//
//  Operation.swift
//  YapDB
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

// swiftlint:disable file_length

import Foundation

// swiftlint:disable type_body_length

/**
Abstract base Operation class which subclasses `NSOperation`.

Operation builds on `NSOperation` in a few simple ways.

1. For an instance to become `.Ready`, all of its attached
`OperationCondition`s must be satisfied.

2. It is possible to attach `OperationObserver`s to an instance,
to be notified of lifecycle events in the operation.

*/
public class Operation: NSOperation {

    private enum State: Int, Comparable {

        // The initial state
        case Initialized

        // Ready to begin evaluating conditions
        case Pending

        // It is executing
        case Executing

        // Execution has completed, but not yet notified queue
        case Finishing

        // The operation has finished.
        case Finished

        func canTransitionToState(other: State, whenCancelled cancelled: Bool) -> Bool {
            switch (self, other) {
            case (.Initialized, .Pending),
                (.Pending, .Executing),
                (.Executing, .Finishing),
                (.Finishing, .Finished):
                return true

            case (.Pending, .Finishing) where cancelled:
                // When an operation is cancelled it can go from pending direct to finishing.
                return true

            default:
                return false
            }
        }
    }

    /**
     Type to express the intent of the user in regards to executing an Operation instance

     - see: https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39
    */
    @objc public enum UserIntent: Int {
        case None = 0, SideEffect, Initiated

        internal var qos: NSQualityOfService {
            switch self {
            case .Initiated, .SideEffect:
                return .UserInitiated
            default:
                return .Default
            }
        }
    }

    /// - returns: a unique String which can be used to identify the operation instance
    public let identifier = NSUUID().UUIDString

    private let stateLock = NSRecursiveLock()
    private var _log = Protector<LoggerType>(Logger())
    private var _state = State.Initialized
    private var _internalErrors = [ErrorType]()
    private var _isTransitioningToExecuting = false
    private var _isHandlingFinish = false
    private var _isHandlingCancel = false
    private var _observers = Protector([OperationObserverType]())
    private let disableAutomaticFinishing: Bool

    internal private(set) var directDependencies = Set<NSOperation>()
    internal private(set) var conditions = Set<Condition>()

    internal var indirectDependencies: Set<NSOperation> {
        return Set(conditions
            .flatMap { $0.directDependencies }
            .filter { !directDependencies.contains($0) }
        )
    }

    // Internal operation properties which are used to manage the scheduling of dependencies
    internal private(set) var evaluateConditionsOperation: GroupOperation? = .None

    private var _cancelled = false  // should always be set by .cancel()

    /// Access the internal errors collected by the Operation
    public var errors: [ErrorType] {
        return stateLock.withCriticalScope { _internalErrors }
    }

    /**
     Expresses the user intent in regards to the execution of this Operation.

     Setting this property will set the appropriate quality of service parameter
     on the Operation.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     */
    public var userIntent: UserIntent = .None {
        didSet {
            setQualityOfServiceFromUserIntent(userIntent)
        }
    }

    /**
     Modifies the quality of service of the underlying operation.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.

     - returns: a Bool indicating whether or not the quality of service is .UserInitiated
    */
    @available(*, unavailable, message="This property has been deprecated in favor of userIntent.")
    public var userInitiated: Bool {
        get {
            return qualityOfService == .UserInitiated
        }
        set {
            precondition(state < .Executing, "Cannot modify userInitiated after execution has begun.")
            qualityOfService = newValue ? .UserInitiated : .Default
        }
    }

    /**
     # Access the logger for this Operation
     The `log` property can be used as the interface to access the logger.
     e.g. to output a message with `LogSeverity.Info` from inside
     the `Operation`, do this:

    ```swift
    log.info("This is my message")
    ```

     To adjust the instance severity of the LoggerType for the
     `Operation`, access it via this property too:

    ```swift
    log.severity = .Verbose
    ```

     The logger is a very simple type, and all it does beyond
     manage the enabled status and severity is send the String to
     a block on a dedicated serial queue. Therefore to provide custom
     logging, set the `logger` property:

     ```swift
     log.logger = { message in sendMessageToAnalytics(message) }
     ```

     By default, the Logger's logger block is the same as the global
     LogManager. Therefore to use a custom logger for all Operations:

     ```swift
     LogManager.logger = { message in sendMessageToAnalytics(message) }
     ```

    */
    public var log: LoggerType {
        get {
            let operationName = self.operationName
            return _log.read { _LoggerOperationContext(parentLogger: $0, operationName: operationName) }
        }
        set {
            _log.write { (inout ward: LoggerType) in
                ward = newValue
            }
        }
    }

    // MARK: - Initialization

    public override init() {
        self.disableAutomaticFinishing = false
        super.init()
    }

    // MARK: - Disable Automatic Finishing

    /**
     Ability to override Operation's built-in finishing behavior, if a
     subclass requires full control over when finish() is called.

     Used for GroupOperation to implement proper .Finished state-handling
     (only finishing after all child operations have finished).

     The default behavior of Operation is to automatically call finish()
     when:
        (a) it's cancelled, whether that occurs:
            - prior to the Operation starting
              (in which case, Operation will skip calling execute())
            - on another thread at the same time that the operation is
              executing
        (b) when willExecuteObservers log errors

     To ensure that an Operation subclass does not finish until the
     subclass calls finish():
     call `super.init(disableAutomaticFinishing: true)` in the init.

     IMPORTANT: If disableAutomaticFinishing == TRUE, the subclass is
     responsible for calling finish() in *ALL* cases, including when the
     operation is cancelled.

     You can react to cancellation using WillCancelObserver/DidCancelObserver
     and/or checking periodically during execute with something like:

     ```swift
     guard !cancelled else {
        // do any necessary clean-up
        finish()    // always call finish if automatic finishing is disabled
        return
     }
     ```

    */
    public init(disableAutomaticFinishing: Bool) {
        self.disableAutomaticFinishing = disableAutomaticFinishing
        super.init()
    }

    // MARK: - Add Condition

    /**
     Add a condition to the to the operation, can only be done prior to the operation starting.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     - parameter condition: type conforming to protocol `OperationCondition`.
     */
    @available(iOS, deprecated=8, message="Refactor OperationCondition types as Condition subclasses.")
    @available(OSX, deprecated=10.10, message="Refactor OperationCondition types as Condition subclasses.")
    public func addCondition(condition: OperationCondition) {
        assert(state < .Executing, "Cannot modify conditions after operation has begun executing, current state: \(state).")
        let operation = WrappedOperationCondition(condition)
        if let dependency = condition.dependencyForOperation(self) {
            operation.addDependency(dependency)
        }
        conditions.insert(operation)
    }

    public func addCondition(condition: Condition) {
        assert(state < .Executing, "Cannot modify conditions after operation has begun executing, current state: \(state).")
        conditions.insert(condition)
    }

    // MARK: - Add Observer

    /**
     Add an observer to the to the operation, can only be done
     prior to the operation starting.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     - parameter observer: type conforming to protocol `OperationObserverType`.
     */
    public func addObserver(observer: OperationObserverType) {

        observers.append(observer)

        observer.didAttachToOperation(self)
    }

    // MARK: - Execution

    /**
     Subclasses should override this method to perform their specialized task.
     They must call a finish methods in order to complete.
     */
    public func execute() {
        print("\(self.dynamicType) must override `execute()`.", terminator: "")
        finish()
    }

    /**
     Subclasses may override `finished(_:)` if they wish to react to the operation
     finishing with errors.

     - parameter errors: an array of `ErrorType`.
     */
    @available(*, unavailable, renamed="operationDidFinish")
    public func finished(errors: [ErrorType]) {
        operationDidFinish(errors)
    }

    /**
     Subclasses may override `operationWillFinish(_:)` if they wish to
     react to the operation finishing with errors.

     - parameter errors: an array of `ErrorType`.
     */
    public func operationWillFinish(errors: [ErrorType]) { /* No op */ }

    /**
     Subclasses may override `operationDidFinish(_:)` if they wish to
     react to the operation finishing with errors.

     - parameter errors: an array of `ErrorType`.
     */
    public func operationDidFinish(errors: [ErrorType]) { /* no op */ }

    // MARK: - Cancellation

    /**
     Cancel the operation with an error.

     - parameter error: an optional `ErrorType`.
     */
    public func cancelWithError(error: ErrorType? = .None) {
        cancelWithErrors(error.map { [$0] } ?? [])
    }

    /**
     Cancel the operation with multiple errors.

     - parameter errors: an `[ErrorType]` defaults to empty array.
     */
    public func cancelWithErrors(errors: [ErrorType] = []) {
        stateLock.withCriticalScope {
            if !errors.isEmpty {
                log.warning("Did cancel with errors: \(errors).")
            }
            _internalErrors += errors
        }
        cancel()
    }

    /**
     Subclasses may override `operationWillCancel(_:)` if they wish to
     react to the operation finishing with errors.

     - parameter errors: an array of `ErrorType`.
     */
    public func operationWillCancel(errors: [ErrorType]) { /* No op */ }

    /**
     Subclasses may override `operationDidCancel(_:)` if they wish to
     react to the operation finishing with errors.

     - parameter errors: an array of `ErrorType`.
     */
    public func operationDidCancel() { /* No op */ }

    public final override func cancel() {
        let willCancel = stateLock.withCriticalScope { _ -> Bool in
            // Do not cancel if already finished or finishing, or cancelled
            guard state <= .Executing && !_cancelled else { return false }
            // Only a single call to cancel should continue
            guard !_isHandlingCancel else { return false }
            _isHandlingCancel = true
            return true
        }

        guard willCancel else { return }

        operationWillCancel(errors)
        willChangeValueForKey(NSOperation.KeyPath.Cancelled.rawValue)
        willCancelObservers.forEach { $0.willCancelOperation(self, errors: self.errors) }

        stateLock.withCriticalScope {
            _cancelled = true
        }

        operationDidCancel()
        didCancelObservers.forEach { $0.didCancelOperation(self) }
        log.verbose("Did cancel.")
        didChangeValueForKey(NSOperation.KeyPath.Cancelled.rawValue)

        // Call super.cancel() to trigger .isReady state change on cancel
        // as well as isReady KVO notification.
        super.cancel()

        let willFinish = stateLock.withCriticalScope { () -> Bool in
            let willFinish = executing && !disableAutomaticFinishing && !_isHandlingFinish
            if willFinish {
                _isHandlingFinish = true
            }
            return willFinish
        }
        if willFinish {
            _finish([], fromCancel: true)
        }
    }
}

// swiftlint:enable type_body_length

// MARK: - State

public extension Operation {

    private var state: State {
        get {
            return stateLock.withCriticalScope { _state }
        }
        set (newState) {
            stateLock.withCriticalScope {
                assert(_state.canTransitionToState(newState, whenCancelled: cancelled), "Attempting to perform illegal cyclic state transition, \(_state) -> \(newState) for operation: \(identity).")
                log.verbose("\(_state) -> \(newState)")
                _state = newState
            }
        }
    }

    /// Boolean indicator for whether the Operation is currently executing or not
    final override var executing: Bool {
        return state == .Executing
    }

    /// Boolean indicator for whether the Operation has finished or not
    final override var finished: Bool {
        return state == .Finished
    }

    /// Boolean indicator for whether the Operation has cancelled or not
    final override var cancelled: Bool {
        return stateLock.withCriticalScope { _cancelled }
    }

    /// Boolean flag to indicate that the Operation failed due to errors.
    var failed: Bool {
        return errors.count > 0
    }

    internal func willEnqueue() {
        state = .Pending
    }
}

// MARK: - Dependencies

public extension Operation {

    internal enum ConditionEvaluation {
        case Pending, Satisfied, Ignored
        case Failed([ErrorType])

        var errors: [ErrorType] {
            if case let .Failed(errors) = self {
                return errors
            }
            return []
        }

        func evaluate(condition: Condition, withErrors errors: [ErrorType]) -> ConditionEvaluation {
            guard let result = condition.result else {
                if errors.isEmpty { return self }
                else { return .Failed(errors) }
            }

            switch (self, result) {
            case let (_, .Failed(conditionError)):
                var errors = self.errors
                errors.append(conditionError)
                return .Failed(errors)
            case (.Failed(_), _):
                return self
            case (_, .Ignored):
                return .Ignored
            case (.Pending, .Satisfied):
                return .Satisfied
            default:
                return self
            }
        }
    }

    internal class EvaluateConditions: GroupOperation, ResultOperationType {

        let requirement: [Condition]
        internal var result: ConditionEvaluation = .Pending

        init(conditions: Set<Condition>) {
            let ops = Array(conditions)
            requirement = ops
            super.init(operations: ops)
        }

        internal override func operationWillFinish(errors: [ErrorType]) {
            process(errors)
        }

        internal override func operationWillCancel(errors: [ErrorType]) {
            process(errors)
        }

        private func process(errors: [ErrorType]) {
            result = requirement.reduce(.Pending) { evaluation, condition in
                log.verbose("evaluating \(evaluation) with \(condition.result)")
                return evaluation.evaluate(condition, withErrors: errors)
            }
        }
    }

    internal func evaluateConditions() -> Operation {

        func createEvaluateConditionsOperation() -> Operation {
            // Set the operation on each condition
            conditions.forEach { $0.operation = self }

            let evaluator = EvaluateConditions(conditions: conditions)
            evaluator.name = "\(operationName) Evaluate Conditions"

            super.addDependency(evaluator)
            return evaluator
        }

        assert(state <= .Executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")

        let evaluator = createEvaluateConditionsOperation()

        // Add an observer to the evaluator to see if any of the conditions failed.
        evaluator.addObserver(WillFinishObserver { [unowned self] operation, errors in
            guard let evaluation = operation as? EvaluateConditions else { return }
            switch evaluation.result {
            case .Pending, .Satisfied:
                break
            case .Ignored:
                self.cancel()
            case .Failed(let errors):
                // If conditions fail, we should cancel the operation
                self.cancelWithErrors(errors)
            }
        })

        directDependencies.forEach {
            evaluator.addDependency($0)
        }

        return evaluator
    }

    internal func addDependencyOnPreviousMutuallyExclusiveOperation(operation: Operation) {
        precondition(state <= .Executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        super.addDependency(operation)
    }

    internal func addDirectDependency(directDependency: NSOperation) {
        precondition(state <= .Executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        directDependencies.insert(directDependency)
        super.addDependency(directDependency)
    }

    internal func removeDirectDependency(directDependency: NSOperation) {
        precondition(state <= .Executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        directDependencies.remove(directDependency)
        super.removeDependency(directDependency)
    }

    /// Public override to get the dependencies
    final override var dependencies: [NSOperation] {
        return Array(directDependencies.union(indirectDependencies))
    }

    /**
     Add another `NSOperation` as a dependency. It is a programmatic error to call
     this method after the receiver has already started executing. Therefore, best
     practice is to add dependencies before adding them to operation queues.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     - parameter operation: a `NSOperation` instance.
     */
    final override func addDependency(operation: NSOperation) {
        precondition(state <= .Executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        addDirectDependency(operation)
    }

    /**
     Remove another `NSOperation` as a dependency. It is a programmatic error to call
     this method after the receiver has already started executing. Therefore, best
     practice is to manage dependencies before adding them to operation
     queues.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     - parameter operation: a `NSOperation` instance.
     */
    final override func removeDependency(operation: NSOperation) {
        precondition(state <= .Executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        removeDirectDependency(operation)
    }
}

// MARK: - Observers

public extension Operation {

    private(set) var observers: [OperationObserverType] {
        get {
            return _observers.read { $0 }
        }
        set {
            _observers.write { (inout ward: [OperationObserverType]) in
                ward = newValue
            }
        }
    }

    internal var willExecuteObservers: [OperationWillExecuteObserver] {
        return observers.flatMap { $0 as? OperationWillExecuteObserver }
    }

    internal var willCancelObservers: [OperationWillCancelObserver] {
        return observers.flatMap { $0 as? OperationWillCancelObserver }
    }

    internal var didCancelObservers: [OperationDidCancelObserver] {
        return observers.flatMap { $0 as? OperationDidCancelObserver }
    }

    internal var didProduceOperationObservers: [OperationDidProduceOperationObserver] {
        return observers.flatMap { $0 as? OperationDidProduceOperationObserver }
    }

    internal var willFinishObservers: [OperationWillFinishObserver] {
        return observers.flatMap { $0 as? OperationWillFinishObserver }
    }

    internal var didFinishObservers: [OperationDidFinishObserver] {
        return observers.flatMap { $0 as? OperationDidFinishObserver }
    }
}

// MARK: - Execution

public extension Operation {

    /// Starts the operation, correctly managing the cancelled state. Cannot be over-ridden
    final override func start() {
        // Don't call super.start

        guard !cancelled || disableAutomaticFinishing else {
            finish()
            return
        }

        main()
    }

    /// Triggers execution of the operation's task, correctly managing errors and the cancelled state. Cannot be over-ridden
    final override func main() {

        // Inform observers that the operation will execute
        willExecuteObservers.forEach { $0.willExecuteOperation(self) }

        let nextState = stateLock.withCriticalScope { () -> (Operation.State?) in
            assert(!executing, "Operation is attempting to execute, but is already executing.")
            guard !_isTransitioningToExecuting else {
                assertionFailure("Operation is attempting to execute twice, concurrently.")
                return nil
            }

            // Check to see if the operation has now been finished
            // by an observer (or anything else)
            guard state <= .Pending else { return nil }

            // Check to see if the operation has now been cancelled
            // by an observer
            guard (_internalErrors.isEmpty && !cancelled) || disableAutomaticFinishing else {
                _isHandlingFinish = true
                return Operation.State.Finishing
            }

            // Transition to the .isExecuting state, and explicitly send the required KVO change notifications
            _isTransitioningToExecuting = true
            return Operation.State.Executing
        }

        guard nextState != .Finishing else {
            _finish([], fromCancel: true)
            return
        }

        guard nextState == .Executing else { return }

        willChangeValueForKey(NSOperation.KeyPath.Executing.rawValue)

        let nextState2 = stateLock.withCriticalScope { () -> (Operation.State?) in
            // Re-check state, since it could have changed on another thread (ex. via finish)
            guard state <= .Pending else { return nil }

            state = .Executing
            _isTransitioningToExecuting = false

            if cancelled && !disableAutomaticFinishing && !_isHandlingFinish {
                // Operation was cancelled, automatic finishing is enabled,
                // but cancel is not (yet/ever?) handling the finish.
                // Because cancel could have already passed the check for executing,
                // handle calling finish here.
                _isHandlingFinish = true
                return .Finishing
            }
            return .Executing
        }

        // Always send the closing didChangeValueForKey
        didChangeValueForKey(NSOperation.KeyPath.Executing.rawValue)

        guard nextState2 != .Finishing else {
            _finish([], fromCancel: true)
            return
        }

        guard nextState2 == .Executing else { return }

        log.verbose("Will Execute")

        execute()
    }

    /**
     Produce another operation on the same queue that this instance is on.

     - parameter operation: a `NSOperation` instance.
     */
    final func produceOperation(operation: NSOperation) {
        precondition(state > .Initialized, "Cannot produce operation while not being scheduled on a queue.")
        log.verbose("Did produce \(operation.operationName)")
        didProduceOperationObservers.forEach { $0.operation(self, didProduceOperation: operation) }
    }
}

// MARK: - Finishing

public extension Operation {

    /**
     Finish method which must be called eventually after an operation has
     begun executing, unless it is cancelled.

     - parameter errors: an array of `ErrorType`, which defaults to empty.
     */
    final func finish(receivedErrors: [ErrorType] = []) {
        _finish(receivedErrors, fromCancel: false)
    }

    private final func _finish(receivedErrors: [ErrorType], fromCancel: Bool = false) {
        let willFinish = stateLock.withCriticalScope { _ -> Bool in
            // Do not finish if already finished or finishing
            guard state <= .Finishing else { return false }
            // Only a single call to _finish should continue
            // (.cancel() sets _isHandlingFinish and fromCancel=true, if appropriate.)
            guard !_isHandlingFinish || fromCancel else { return false }
            _isHandlingFinish = true
            return true
        }

        guard willFinish else { return }

        // NOTE:
        // - The stateLock should only be held when necessary, and should not
        //   be held when notifying observers (whether via KVO or Operation's
        //   observers) or deadlock can result.

        let changedExecutingState = executing
        if changedExecutingState {
            willChangeValueForKey(NSOperation.KeyPath.Executing.rawValue)
        }

        stateLock.withCriticalScope {
            state = .Finishing
        }

        if changedExecutingState {
            didChangeValueForKey(NSOperation.KeyPath.Executing.rawValue)
        }

        let errors = stateLock.withCriticalScope { () -> [ErrorType] in
            _internalErrors.appendContentsOf(receivedErrors)
            return _internalErrors
        }

        if errors.isEmpty {
            log.verbose("Will finish with no errors.")
        }
        else {
            log.warning("Will finish with \(errors.count) errors.")
        }

        operationWillFinish(errors)
        willChangeValueForKey(NSOperation.KeyPath.Finished.rawValue)
        willFinishObservers.forEach { $0.willFinishOperation(self, errors: errors) }

        stateLock.withCriticalScope {
            state = .Finished
        }

        operationDidFinish(errors)
        didFinishObservers.forEach { $0.didFinishOperation(self, errors: errors) }

        let message = !errors.isEmpty ? "errors: \(errors)" : "no errors"
        log.verbose("Did finish with \(message)")

        didChangeValueForKey(NSOperation.KeyPath.Finished.rawValue)
    }

    /// Convenience method to simplify finishing when there is only one error.
    final func finish(receivedError: ErrorType?) {
        finish(receivedError.map { [$0]} ?? [])
    }

    /**
     Public override which deliberately crashes your app, as usage is considered an antipattern

     To promote best practices, where waiting is never the correct thing to do,
     we will crash the app if this is called. Instead use discrete operations and
     dependencies, or groups, or semaphores or even NSLocking.

     */
    final override func waitUntilFinished() {
        fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™. Post a question in https://github.com/danthorpe/Operations if you are unsure.")
    }
}

private func < (lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

private func == (lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

/**
A common error type for Operations. Primarily used to indicate error when
an Operation's conditions fail.
*/
public enum OperationError: ErrorType, Equatable {

    /// Indicates that a condition of the Operation failed.
    case ConditionFailed

    /// Indicates that the operation timed out.
    case OperationTimedOut(NSTimeInterval)

    /// Indicates that a parent operation was cancelled (with errors).
    case ParentOperationCancelledWithErrors([ErrorType])
}

/// OperationError is Equatable.
public func == (lhs: OperationError, rhs: OperationError) -> Bool {
    switch (lhs, rhs) {
    case (.ConditionFailed, .ConditionFailed):
        return true
    case let (.OperationTimedOut(aTimeout), .OperationTimedOut(bTimeout)):
        return aTimeout == bTimeout
    case let (.ParentOperationCancelledWithErrors(aErrors), .ParentOperationCancelledWithErrors(bErrors)):
        // Not possible to do a real equality check here.
        return aErrors.count == bErrors.count
    default:
        return false
    }
}

extension NSOperation {

    /**
    Chain completion blocks.

    - parameter block: a Void -> Void block
    */
    public func addCompletionBlock(block: Void -> Void) {
        if let existing = completionBlock {
            completionBlock = {
                existing()
                block()
            }
        }
        else {
            completionBlock = block
        }
    }

    /**
    Add multiple depdendencies to the operation. Will add each
    dependency in turn.

    - parameter dependencies: and array of `NSOperation` instances.
    */
    public func addDependencies<S where S: SequenceType, S.Generator.Element: NSOperation>(dependencies: S) {
        precondition(!executing && !finished, "Cannot modify the dependencies after the operation has started executing.")
        dependencies.forEach(addDependency)
    }

    /**
     Remove multiple depdendencies from the operation. Will remove each
     dependency in turn.

     - parameter dependencies: and array of `NSOperation` instances.
     */
    public func removeDependencies<S where S: SequenceType, S.Generator.Element: NSOperation>(dependencies: S) {
        precondition(!executing && !finished, "Cannot modify the dependencies after the operation has started executing.")
        dependencies.forEach(removeDependency)
    }

    /// Removes all the depdendencies from the operation.
    public func removeDependencies() {
        removeDependencies(dependencies)
    }

    internal func setQualityOfServiceFromUserIntent(userIntent: Operation.UserIntent) {
        qualityOfService = userIntent.qos
    }
}

private extension NSOperation {
    enum KeyPath: String {
        case Cancelled = "isCancelled"
        case Executing = "isExecuting"
        case Finished = "isFinished"
    }
}

extension NSLock {
    func withCriticalScope<T>(@noescape block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

extension NSRecursiveLock {
    func withCriticalScope<T>(@noescape block: () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

extension Array where Element: NSOperation {

    internal var splitNSOperationsAndOperations: ([NSOperation], [Operation]) {
        return reduce(([], [])) { result, element in
            var (ns, op) = result
            if let operation = element as? Operation {
                op.append(operation)
            }
            else {
                ns.append(element)
            }
            return (ns, op)
        }
    }

    internal var userIntent: Operation.UserIntent {
        get {
            let (_, ops) = splitNSOperationsAndOperations
            return ops.map { $0.userIntent }.maxElement { $0.rawValue < $1.rawValue } ?? .None
        }
    }

    internal func forEachOperation(@noescape body: (Operation) throws -> Void) rethrows {
        try forEach {
            if let operation = $0 as? Operation {
                try body(operation)
            }
        }
    }
}

// swiftlint:enable file_length
