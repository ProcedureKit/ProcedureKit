//
//  Procedure.swift
//  Operations
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

// swiftlint:disable file_length

import Foundation

// swiftlint:disable type_body_length

/**
Abstract base Procedure class which subclasses `NSOperation`.

Procedure builds on `NSOperation` in a few simple ways.

1. For an instance to become `.Ready`, all of its attached
`OperationCondition`s must be satisfied.

2. It is possible to attach `OperationObserver`s to an instance,
to be notified of lifecycle events in the operation.

*/
public class Procedure: Operation {

    private enum State: Int, Comparable {

        // The initial state
        case initialized

        // Ready to begin evaluating conditions
        case pending

        // It is executing
        case executing

        // Execution has completed, but not yet notified queue
        case finishing

        // The operation has finished.
        case finished

        func canTransitionToState(_ other: State, whenCancelled cancelled: Bool) -> Bool {
            switch (self, other) {
            case (.initialized, .pending),
                (.pending, .executing),
                (.executing, .finishing),
                (.finishing, .finished):
                return true

            case (.pending, .finishing) where cancelled:
                // When an operation is cancelled it can go from pending direct to finishing.
                return true

            default:
                return false
            }
        }
    }

    /**
     Type to express the intent of the user in regards to executing an Procedure instance

     - see: https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39
    */
    @objc public enum UserIntent: Int {
        case none = 0, sideEffect, initiated

        internal var qos: QualityOfService {
            switch self {
            case .initiated, .sideEffect:
                return .userInitiated
            default:
                return .default
            }
        }
    }

    /// - returns: a unique String which can be used to identify the operation instance
    public let identifier = UUID().uuidString

    private let stateLock = RecursiveLock()
    private var _log = Protector<LoggerType>(Logger())
    private var _state = State.initialized
    private var _internalErrors = [ErrorProtocol]()
    private var _isTransitioningToExecuting = false
    private var _isHandlingFinish = false
    private var _isHandlingCancel = false
    private var _observers = Protector([OperationObserverType]())
    private let disableAutomaticFinishing: Bool

    internal private(set) var directDependencies = Set<Operation>()
    internal private(set) var conditions = Set<Condition>()

    internal var indirectDependencies: Set<Operation> {
        return Set(conditions.flatMap { $0.directDependencies })
    }

    // Internal operation properties which are used to manage the scheduling of dependencies
    internal private(set) var evaluateConditionsOperation: GroupOperation? = .none

    private var _cancelled = false  // should always be set by .cancel()

    /// Access the internal errors collected by the Procedure
    public var errors: [ErrorProtocol] {
        return stateLock.withCriticalScope { _internalErrors }
    }

    /**
     Expresses the user intent in regards to the execution of this Procedure.

     Setting this property will set the appropriate quality of service parameter
     on the Procedure.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     */
    public var userIntent: UserIntent = .none {
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
    @available(*, unavailable, message: "This property has been deprecated in favor of userIntent.")
    public var userInitiated: Bool {
        get {
            return qualityOfService == .userInitiated
        }
        set {
            precondition(state < .executing, "Cannot modify userInitiated after execution has begun.")
            qualityOfService = newValue ? .userInitiated : .default
        }
    }

    /**
     # Access the logger for this Procedure
     The `log` property can be used as the interface to access the logger.
     e.g. to output a message with `LogSeverity.Info` from inside
     the `Procedure`, do this:

    ```swift
    log.info("This is my message")
    ```

     To adjust the instance severity of the LoggerType for the
     `Procedure`, access it via this property too:

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
            _log.write { (ward: inout LoggerType) in
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

     The default behavior of Procedure is to automatically call finish()
     when:
        (a) it's cancelled, whether that occurs:
            - prior to the Procedure starting
              (in which case, Procedure will skip calling execute())
            - on another thread at the same time that the operation is
              executing
        (b) when willExecuteObservers log errors

     To ensure that an Procedure subclass does not finish until the
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
    @available(iOS, deprecated: 8, message: "Refactor OperationCondition types as Condition subclasses.")
    @available(OSX, deprecated: 10.10, message: "Refactor OperationCondition types as Condition subclasses.")
    public func addCondition(_ condition: OperationCondition) {
        assert(state < .executing, "Cannot modify conditions after operation has begun executing, current state: \(state).")
        let operation = WrappedOperationCondition(condition)
        if let dependency = condition.dependencyForOperation(self) {
            operation.addDependency(dependency)
        }
        conditions.insert(operation)
    }

    public func addCondition(_ condition: Condition) {
        assert(state < .executing, "Cannot modify conditions after operation has begun executing, current state: \(state).")
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
    public func addObserver(_ observer: OperationObserverType) {

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
    @available(*, unavailable, renamed: "operationDidFinish")
    public func finished(_ errors: [ErrorProtocol]) {
        operationDidFinish(errors)
    }

    /**
     Subclasses may override `operationWillFinish(_:)` if they wish to
     react to the operation finishing with errors.

     - parameter errors: an array of `ErrorType`.
     */
    public func operationWillFinish(_ errors: [ErrorProtocol]) { /* No op */ }

    /**
     Subclasses may override `operationDidFinish(_:)` if they wish to
     react to the operation finishing with errors.

     - parameter errors: an array of `ErrorType`.
     */
    public func operationDidFinish(_ errors: [ErrorProtocol]) { /* no op */ }

    // MARK: - Cancellation

    /**
     Cancel the operation with an error.

     - parameter error: an optional `ErrorType`.
     */
    public func cancelWithError(_ error: ErrorProtocol? = .none) {
        cancelWithErrors(error.map { [$0] } ?? [])
    }

    /**
     Cancel the operation with multiple errors.

     - parameter errors: an `[ErrorType]` defaults to empty array.
     */
    public func cancelWithErrors(_ errors: [ErrorProtocol] = []) {
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
    public func operationWillCancel(_ errors: [ErrorProtocol]) { /* No op */ }

    /**
     Subclasses may override `operationDidCancel(_:)` if they wish to
     react to the operation finishing with errors.

     - parameter errors: an array of `ErrorType`.
     */
    public func operationDidCancel() { /* No op */ }

    public final override func cancel() {
        let willCancel = stateLock.withCriticalScope { _ -> Bool in
            // Do not cancel if already finished or finishing, or cancelled
            guard state <= .executing && !_cancelled else { return false }
            // Only a single call to cancel should continue
            guard !_isHandlingCancel else { return false }
            _isHandlingCancel = true
            return true
        }

        guard willCancel else { return }

        operationWillCancel(errors)
        willChangeValue(forKey: Operation.KeyPath.Cancelled.rawValue)
        willCancelObservers.forEach { $0.willCancelOperation(self, errors: self.errors) }

        stateLock.withCriticalScope {
            _cancelled = true
        }

        operationDidCancel()
        didCancelObservers.forEach { $0.didCancelOperation(self) }
        log.verbose("Did cancel.")
        didChangeValue(forKey: Operation.KeyPath.Cancelled.rawValue)

        // Call super.cancel() to trigger .isReady state change on cancel
        // as well as isReady KVO notification.
        super.cancel()

        let willFinish = stateLock.withCriticalScope { () -> Bool in
            let willFinish = isExecuting && !disableAutomaticFinishing && !_isHandlingFinish
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

public extension Procedure {

    private var state: State {
        get {
            return stateLock.withCriticalScope { _state }
        }
        set (newState) {
            stateLock.withCriticalScope {
                assert(_state.canTransitionToState(newState, whenCancelled: isCancelled), "Attempting to perform illegal cyclic state transition, \(_state) -> \(newState) for operation: \(identity).")
                log.verbose("\(_state) -> \(newState)")
                _state = newState
            }
        }
    }

    /// Boolean indicator for whether the Procedure is currently executing or not
    final override var isExecuting: Bool {
        return state == .executing
    }

    /// Boolean indicator for whether the Procedure has finished or not
    final override var isFinished: Bool {
        return state == .finished
    }

    /// Boolean indicator for whether the Procedure has cancelled or not
    final override var isCancelled: Bool {
        return stateLock.withCriticalScope { _cancelled }
    }

    /// Boolean flag to indicate that the Procedure failed due to errors.
    var failed: Bool {
        return errors.count > 0
    }

    internal func willEnqueue() {
        state = .pending
    }
}

// MARK: - Dependencies

public extension Procedure {

    internal func evaluateConditions() -> GroupOperation {

        func createEvaluateConditionsOperation() -> GroupOperation {
            // Set the operation on each condition
            conditions.forEach { $0.operation = self }

            let evaluator = GroupOperation(operations: Array(conditions))
            evaluator.name = "Condition Evaluator for: \(operationName)"
            super.addDependency(evaluator)
            return evaluator
        }

        assert(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")

        let evaluator = createEvaluateConditionsOperation()

        // Add an observer to the evaluator to see if any of the conditions failed.
        evaluator.addObserver(WillFinishObserver { [unowned self] operation, errors in
            if errors.count > 0 {
                // If conditions fail, we should cancel the operation
                self.cancelWithErrors(errors)
            }
        })

        directDependencies.forEach {
            evaluator.addDependency($0)
        }

        return evaluator
    }

    internal func addDependencyOnPreviousMutuallyExclusiveOperation(_ operation: Procedure) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        super.addDependency(operation)
    }

    internal func addDirectDependency(_ directDependency: Operation) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        directDependencies.insert(directDependency)
        super.addDependency(directDependency)
    }

    internal func removeDirectDependency(_ directDependency: Operation) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        directDependencies.remove(directDependency)
        super.removeDependency(directDependency)
    }

    /// Public override to get the dependencies
    final override var dependencies: [Operation] {
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
    final override func addDependency(_ operation: Operation) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
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
    final override func removeDependency(_ operation: Operation) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        removeDirectDependency(operation)
    }
}

// MARK: - Observers

public extension Procedure {

    private(set) var observers: [OperationObserverType] {
        get {
            return _observers.read { $0 }
        }
        set {
            _observers.write { (ward: inout [OperationObserverType]) in
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

public extension Procedure {

    /// Starts the operation, correctly managing the cancelled state. Cannot be over-ridden
    final override func start() {
        // Don't call super.start

        guard !isCancelled || disableAutomaticFinishing else {
            finish()
            return
        }

        main()
    }

    /// Triggers execution of the operation's task, correctly managing errors and the cancelled state. Cannot be over-ridden
    final override func main() {

        // Inform observers that the operation will execute
        willExecuteObservers.forEach { $0.willExecuteOperation(self) }

        let nextState = stateLock.withCriticalScope { () -> (Procedure.State?) in
            assert(!isExecuting, "Procedure is attempting to execute, but is already executing.")
            guard !_isTransitioningToExecuting else {
                assertionFailure("Procedure is attempting to execute twice, concurrently.")
                return nil
            }

            // Check to see if the operation has now been finished
            // by an observer (or anything else)
            guard state <= .pending else { return nil }

            // Check to see if the operation has now been cancelled
            // by an observer
            guard (_internalErrors.isEmpty && !isCancelled) || disableAutomaticFinishing else {
                _isHandlingFinish = true
                return Procedure.State.finishing
            }

            // Transition to the .isExecuting state, and explicitly send the required KVO change notifications
            _isTransitioningToExecuting = true
            return Procedure.State.executing
        }

        guard nextState != .finishing else {
            _finish([], fromCancel: true)
            return
        }

        guard nextState == .executing else { return }

        willChangeValue(forKey: Operation.KeyPath.Executing.rawValue)

        let nextState2 = stateLock.withCriticalScope { () -> (Procedure.State?) in
            // Re-check state, since it could have changed on another thread (ex. via finish)
            guard state <= .pending else { return nil }

            state = .executing
            _isTransitioningToExecuting = false

            if isCancelled && !disableAutomaticFinishing && !_isHandlingFinish {
                // Procedure was cancelled, automatic finishing is enabled,
                // but cancel is not (yet/ever?) handling the finish.
                // Because cancel could have already passed the check for executing,
                // handle calling finish here.
                _isHandlingFinish = true
                return .finishing
            }
            return .executing
        }

        // Always send the closing didChangeValueForKey
        didChangeValue(forKey: Operation.KeyPath.Executing.rawValue)

        guard nextState2 != .finishing else {
            _finish([], fromCancel: true)
            return
        }

        guard nextState2 == .executing else { return }

        log.verbose("Will Execute")

        execute()
    }

    /**
     Produce another operation on the same queue that this instance is on.

     - parameter operation: a `NSOperation` instance.
     */
    final func produceOperation(_ operation: Operation) {
        precondition(state > .initialized, "Cannot produce operation while not being scheduled on a queue.")
        log.verbose("Did produce \(operation.operationName)")
        didProduceOperationObservers.forEach { $0.operation(self, didProduceOperation: operation) }
    }
}

// MARK: - Finishing

public extension Procedure {

    /**
     Finish method which must be called eventually after an operation has
     begun executing, unless it is cancelled.

     - parameter errors: an array of `ErrorType`, which defaults to empty.
     */
    final func finish(_ receivedErrors: [ErrorProtocol] = []) {
        _finish(receivedErrors, fromCancel: false)
    }

    private final func _finish(_ receivedErrors: [ErrorProtocol], fromCancel: Bool = false) {
        let willFinish = stateLock.withCriticalScope { _ -> Bool in
            // Do not finish if already finished or finishing
            guard state <= .finishing else { return false }
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

        let changedExecutingState = isExecuting
        if changedExecutingState {
            willChangeValue(forKey: Operation.KeyPath.Executing.rawValue)
        }

        stateLock.withCriticalScope {
            state = .finishing
        }

        if changedExecutingState {
            didChangeValue(forKey: Operation.KeyPath.Executing.rawValue)
        }

        let errors = stateLock.withCriticalScope { () -> [ErrorProtocol] in
            _internalErrors.append(contentsOf: receivedErrors)
            return _internalErrors
        }

        if errors.isEmpty {
            log.verbose("Will finish with no errors.")
        }
        else {
            log.warning("Will finish with \(errors.count) errors.")
        }

        operationWillFinish(errors)
        willChangeValue(forKey: Operation.KeyPath.Finished.rawValue)
        willFinishObservers.forEach { $0.willFinishOperation(self, errors: errors) }

        stateLock.withCriticalScope {
            state = .finished
        }

        operationDidFinish(errors)
        didFinishObservers.forEach { $0.didFinishOperation(self, errors: errors) }

        let message = !errors.isEmpty ? "errors: \(errors)" : "no errors"
        log.verbose("Did finish with \(message)")

        didChangeValue(forKey: Operation.KeyPath.Finished.rawValue)
    }

    /// Convenience method to simplify finishing when there is only one error.
    final func finish(_ receivedError: ErrorProtocol?) {
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

private func < (lhs: Procedure.State, rhs: Procedure.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

private func == (lhs: Procedure.State, rhs: Procedure.State) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

/**
A common error type for Operations. Primarily used to indicate error when
an Operation's conditions fail.
*/
public enum OperationError: ErrorProtocol, Equatable {

    /// Indicates that a condition of the Procedure failed.
    case conditionFailed

    /// Indicates that the operation timed out.
    case operationTimedOut(TimeInterval)

    /// Indicates that a parent operation was cancelled (with errors).
    case parentOperationCancelledWithErrors([ErrorProtocol])
}

/// OperationError is Equatable.
public func == (lhs: OperationError, rhs: OperationError) -> Bool {
    switch (lhs, rhs) {
    case (.conditionFailed, .conditionFailed):
        return true
    case let (.operationTimedOut(aTimeout), .operationTimedOut(bTimeout)):
        return aTimeout == bTimeout
    case let (.parentOperationCancelledWithErrors(aErrors), .parentOperationCancelledWithErrors(bErrors)):
        // Not possible to do a real equality check here.
        return aErrors.count == bErrors.count
    default:
        return false
    }
}

extension Operation {

    /**
    Chain completion blocks.

    - parameter block: a Void -> Void block
    */
    public func addCompletionBlock(_ block: (Void) -> Void) {
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
    public func addDependencies<S where S: Sequence, S.Iterator.Element: Operation>(_ dependencies: S) {
        precondition(!isExecuting && !isFinished, "Cannot modify the dependencies after the operation has started executing.")
        dependencies.forEach(addDependency)
    }

    /**
     Remove multiple depdendencies from the operation. Will remove each
     dependency in turn.

     - parameter dependencies: and array of `NSOperation` instances.
     */
    public func removeDependencies<S where S: Sequence, S.Iterator.Element: Operation>(_ dependencies: S) {
        precondition(!isExecuting && !isFinished, "Cannot modify the dependencies after the operation has started executing.")
        dependencies.forEach(removeDependency)
    }

    /// Removes all the depdendencies from the operation.
    public func removeDependencies() {
        removeDependencies(dependencies)
    }

    internal func setQualityOfServiceFromUserIntent(_ userIntent: Procedure.UserIntent) {
        qualityOfService = userIntent.qos
    }
}

private extension Operation {
    enum KeyPath: String {
        case Cancelled = "isCancelled"
        case Executing = "isExecuting"
        case Finished = "isFinished"
    }
}

extension Foundation.Lock {
    func withCriticalScope<T>(_ block: @noescape () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

extension RecursiveLock {
    func withCriticalScope<T>(_ block: @noescape () -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

extension Array where Element: Operation {

    internal var splitNSOperationsAndOperations: ([Operation], [Procedure]) {
        return reduce(([], [])) { result, element in
            var (ns, op) = result
            if let operation = element as? Procedure {
                op.append(operation)
            }
            else {
                ns.append(element)
            }
            return (ns, op)
        }
    }

    internal var userIntent: Procedure.UserIntent {
        get {
            let (_, ops) = splitNSOperationsAndOperations
            return ops.map { $0.userIntent }.max { $0.rawValue < $1.rawValue } ?? .none
        }
    }

    internal func forEachOperation(body: @noescape (Procedure) throws -> Void) rethrows {
        try forEach {
            if let operation = $0 as? Procedure {
                try body(operation)
            }
        }
    }
}

// swiftlint:enable file_length
