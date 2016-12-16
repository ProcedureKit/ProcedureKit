//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

// swiftlint:disable file_length
// swiftlint:disable type_body_length

import Foundation

internal struct ProcedureKit {

    fileprivate enum FinishingFrom {
        case main, cancel, finish
    }

    fileprivate enum State: Int, Comparable {

        static func < (lhs: State, rhs: State) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        case initialized
        case pending
        case executing
        case finishing
        case finished

        func canTransition(to other: State, whenCancelled isCancelled: Bool) -> Bool {
            switch (self, other) {
            case (.initialized, .pending),
                 (.pending, .executing),
                 (.executing, .finishing),
                 (.finishing, .finished):
                return true

            case (.initialized, .finishing) where isCancelled:
                // When an operation is cancelled before it is added to a queue it can go from pending direct to finishing.
                return true

            case (.pending, .finishing) where isCancelled:
                // When an operation is cancelled it can go from pending direct to finishing.
                return true

            default:
                return false
            }
        }
    }

    private init() { }
}

/**
 Type to express the intent of the user in regards to executing an Operation instance

 - see: https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39
 */
@objc public enum UserIntent: Int {
    case none = 0, sideEffect, initiated

    internal var qualityOfService: QualityOfService {
        switch self {
        case .initiated, .sideEffect:
            return .userInitiated
        default:
            return .default
        }
    }
}

open class Procedure: Operation, ProcedureProtocol {

    private var _isTransitioningToExecuting = false
    private var _isFinishingFrom: ProcedureKit.FinishingFrom? = nil
    private var _isHandlingCancel = false
    private var _isCancelled = false  // should always be set by .cancel()

    private var _isHandlingFinish: Bool {
        return _isFinishingFrom != nil
    }

    fileprivate let isAutomaticFinishingDisabled: Bool

    private weak var queue: ProcedureQueue?

    /**
     Expresses the user intent in regards to the execution of this Procedure.

     Setting this property will set the appropriate quality of service parameter
     on the parent Operation.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     */
    public var userIntent: UserIntent = .none {
        didSet {
            setQualityOfService(fromUserIntent: userIntent)
        }
    }

    internal let identifier = UUID()

    // MARK: State

    private var _state = ProcedureKit.State.initialized
    private let _stateLock = NSRecursiveLock()

    fileprivate var state: ProcedureKit.State {
        get {
            return _stateLock.withCriticalScope { _state }
        }
        set(newState) {
            _stateLock.withCriticalScope {
                log.verbose(message: "\(_state) -> \(newState)")
                assert(_state.canTransition(to: newState, whenCancelled: isCancelled), "Attempting to perform illegal cyclic state transition, \(_state) -> \(newState) for operation: \(identity). Ensure that Procedure instances are added to a ProcedureQueue not an OperationQueue.")
                _state = newState
            }
        }
    }

    /// Boolean indicator for whether the Procedure has been enqueue
    final public var isEnqueued: Bool {
        return state >= .pending
    }

    /// Boolean indicator for whether the Procedure is pending
    final public var isPending: Bool {
        return state == .pending
    }

    /// Boolean indicator for whether the Procedure is currently executing or not
    final public override var isExecuting: Bool {
        return state == .executing
    }

    /// Boolean indicator for whether the Procedure has finished or not
    final public override var isFinished: Bool {
        return state == .finished
    }

    /// Boolean indicator for whether the Operation has cancelled or not
    final public override var isCancelled: Bool {
        return _stateLock.withCriticalScope { _isCancelled }
    }

    // MARK: Protected Internal Properties

    fileprivate struct ProtectedProperties {
        var log: LoggerProtocol = Logger()
        var errors = [Error]()
        var observers = [AnyObserver<Procedure>]()
        var directDependencies = Set<Operation>()
        var conditions = Set<Condition>()
    }
    fileprivate let protectedProperties = Protector(ProtectedProperties())


    // MARK: Errors

    public var errors: [Error] {
        return protectedProperties.read { $0.errors }
    }

    // MARK: Log

    /**
     Access the logger for this Operation

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
    final public var log: LoggerProtocol {
        get {
            let operationName = self.operationName
            return protectedProperties.read { LoggerContext(parent: $0.log, operationName: operationName) }
        }
        set {
            protectedProperties.write {
                $0.log = newValue
            }
        }
    }

    // MARK: Observers

    final var observers: [AnyObserver<Procedure>] {
        get { return protectedProperties.read { $0.observers } }
    }



    // MARK: Dependencies & Conditions

    internal var directDependencies: Set<Operation> {
        get { return protectedProperties.read { $0.directDependencies } }
    }

    internal fileprivate(set) var evaluateConditionsProcedure: EvaluateConditions? = nil

    internal var indirectDependencies: Set<Operation> {
        return Set(conditions
            .flatMap { $0.directDependencies }
            .filter { !directDependencies.contains($0) }
        )
    }

    /// - returns conditions: the Set of Condition instances attached to the operation
    public var conditions: Set<Condition> {
        get { return protectedProperties.read { $0.conditions } }
    }

    // MARK: - Initialization

    public override init() {
        isAutomaticFinishingDisabled = false
        super.init()
        name = String(describing: type(of: self))
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
        isAutomaticFinishingDisabled = disableAutomaticFinishing
        super.init()
        name = String(describing: type(of: self))
    }


    // MARK: - Execution

    private var shouldEnqueue: Bool {
        return _stateLock.withCriticalScope {
            // Do not cancel if already finished or finishing, or cancelled
            guard state < .pending && !_isCancelled else { return false }
            return true
        }
    }


    public final func willEnqueue(on queue: ProcedureQueue) {
        state = .pending
        self.queue = queue
    }

    /// Starts the operation, correctly managing the cancelled state. Cannot be over-ridden
    public final override func start() {
        // Don't call super.start

        // Replicate NSOperation.start() autorelease behavior
        // (Push an autoreleasepool before calling main(), pop after main() returns)
        autoreleasepool {
            guard !isCancelled || isAutomaticFinishingDisabled else {
                finish()
                return
            }

            main()
        }
    }

    /// Triggers execution of the operation's task, correctly managing errors and the cancelled state. Cannot be over-ridden
    public final override func main() {

        // Prevent concurrent execution
        func getNextState() -> ProcedureKit.State? {
            return _stateLock.withCriticalScope {

                // Check to see if the procedure is already attempting to execute
                assert(!isExecuting, "Procedure is attempting to execute, but is already executing.")
                guard !_isTransitioningToExecuting else {
                    assertionFailure("Procedure is attempting to execute twice, concurrently.")
                    return nil
                }

                // Check to see if the procedure has now been finished
                // by an observer (or anything else)
                guard state <= .pending else { return nil }

                // Check to see if the procedure has now been cancelled
                // by an observer
                guard (errors.isEmpty && !isCancelled) || isAutomaticFinishingDisabled else {
                    _isFinishingFrom = .main
                    return .finishing
                }

                // Transition to the .isExecuting state, and explicitly send the required KVO change notifications
                _isTransitioningToExecuting = true
                return .executing
            }
        }

        // Check the state again, as it could have changed in another queue via finish
        func getNextStateAgain() -> ProcedureKit.State? {
            return _stateLock.withCriticalScope {
                guard state <= .pending else { return nil }

                state = .executing
                _isTransitioningToExecuting = false

                if isCancelled && !isAutomaticFinishingDisabled && !_isHandlingFinish {
                    // Procedure was cancelled, automatic finishing is enabled,
                    // but cancel is not (yet/ever?) handling the finish.
                    // Because cancel could have already passed the check for executing,
                    // handle calling finish here.
                    _isFinishingFrom = .main
                    return .finishing
                }
                return .executing
            }
        }

        observers.forEach { $0.will(execute: self) }

        let nextState = getNextState()

        guard nextState != .finishing else {
            _finish(withErrors: [], from: .main)
            return
        }

        guard nextState == .executing else { return }

        willChangeValue(forKey: .executing)

        let nextState2 = getNextStateAgain()

        didChangeValue(forKey: .executing)

        guard nextState2 != .finishing else {
            _finish(withErrors: [], from: .main)
            return
        }

        guard nextState2 == .executing else { return }

        log.notice(message: "Will Execute")

        execute()

        observers.forEach { $0.did(execute: self) }

        log.notice(message: "Did Execute")
    }

    open func execute() {
        print("\(self) must override `execute()`.")
        finish()
    }

    public final func produce(operation: Operation) throws {
        precondition(state > .initialized, "Cannot add operation which is not being scheduled on a queue")
        guard let queue = queue else {
            throw ProcedureKitError.noQueue()
        }

        queue.delegate?.procedureQueue(queue, willProduceOperation: operation)

        log.notice(message: "Will add \(operation.operationName)")

        observers.forEach { $0.procedure(self, willAdd: operation) }

        queue.add(operation: operation)

        observers.forEach { $0.procedure(self, didAdd: operation) }
    }

    internal func queue(_ queue: ProcedureQueue, didAddOperation operation: Operation) {
        log.notice(message: "Did add \(operation.operationName)")
        observers.forEach { $0.procedure(self, didAdd: operation) }
    }

    // MARK: - Cancellation

    open func procedureWillCancel(withErrors: [Error]) { }

    open func procedureDidCancel(withErrors: [Error]) { }

    public final func cancel(withErrors errors: [Error]) {
        _cancel(withAdditionalErrors: errors)
    }

    public final override func cancel() {
        _cancel(withAdditionalErrors: [])
    }

    private var shouldCancel: Bool {
        return _stateLock.withCriticalScope {
            // Do not cancel if already finished or finishing, or cancelled
            guard state <= .executing && !_isCancelled else { return false }
            // Only a single call to cancel should continue
            guard !_isHandlingCancel else { return false }
            _isHandlingCancel = true
            return true
        }
    }

    private var shouldFinishFromCancel: Bool {
        return _stateLock.withCriticalScope {
            let shouldFinish = isExecuting && !isAutomaticFinishingDisabled && !_isHandlingFinish
            if shouldFinish {
                _isFinishingFrom = .cancel
            }
            return shouldFinish
        }
    }

    private final func _cancel(withAdditionalErrors additionalErrors: [Error]) {

        guard shouldCancel else { return }

        let resultingErrors = errors + additionalErrors
        procedureWillCancel(withErrors: resultingErrors)
        willChangeValue(forKey: .cancelled)
        observers.forEach { $0.will(cancel: self, withErrors: resultingErrors) }

        _stateLock.withCriticalScope {
            if !additionalErrors.isEmpty {
                protectedProperties.write {
                    $0.errors.append(contentsOf: additionalErrors)
                }
            }
            _isCancelled = true
        }

        procedureDidCancel(withErrors: resultingErrors)
        observers.forEach { $0.did(cancel: self, withErrors: resultingErrors) }

        let messageSuffix = !additionalErrors.isEmpty ? "errors: \(additionalErrors)" : "no errors"
        log.notice(message: "Will cancel with \(messageSuffix).")

        didChangeValue(forKey: .cancelled)

        // Call super to trigger .isReady state change on cancel
        // as well as isReady KVO notification
        super.cancel()

        guard shouldFinishFromCancel else { return }

        _finish(withErrors: [], from: .cancel)
    }


    // MARK: - Finishing

    open func procedureWillFinish(withErrors: [Error]) { }

    open func procedureDidFinish(withErrors: [Error]) { }

    /**
     Finish method which must be called eventually after an operation has
     begun executing, unless it is cancelled.

     - parameter errors: an array of `Error`, which defaults to empty.
     */
    public final func finish(withErrors errors: [Error] = []) {
        _finish(withErrors: errors, from: .finish)
    }

    private final func shouldFinish(from source: ProcedureKit.FinishingFrom) -> Bool {
        return _stateLock.withCriticalScope {
            // Do not finish is already finishing or finished
            guard state <= .finishing else { return false }
            // Only a single call to _finish should continue
            guard !_isHandlingFinish
                // cancel() and main() ensure one-time execution
                // thus, cancel() and main() set _isFinishingFrom prior to calling _finish()
                // but finish() does not; _isFinishingFrom is set below when finish() calls _finish()
                // this could be simplified to a check for (_isFinishFrom == source) if finish()
                // ensured that it could only call _finish() once
                // (although that would require another aquisition of the lock)
                || (_isFinishingFrom == source && (source == .cancel || source == .main))
                else { return false }

            _isFinishingFrom = source
            return true
        }
    }

    private final func _finish(withErrors receivedErrors: [Error], from source: ProcedureKit.FinishingFrom) {
        guard shouldFinish(from: source) else { return }

        // NOTE:
        // - The stateLock should only be held when necessary, and should not
        //   be held when notifying observers (whether via KVO or Operation's
        //   observers) or deadlock can result.

        let changedExecutingState = isExecuting
        if changedExecutingState {
            willChangeValue(forKey: .executing)
        }
        _stateLock.withCriticalScope { state = .finishing }
        if changedExecutingState {
            didChangeValue(forKey: .executing)
        }

        let resultingErrors: [Error] = protectedProperties.write {
            if !receivedErrors.isEmpty {
                $0.errors.append(contentsOf: receivedErrors)
            }
            return $0.errors
        }

        let messageSuffix = !resultingErrors.isEmpty ? "errors: \(resultingErrors)" : "no errors"

        log.notice(message: "Will finish with \(messageSuffix).")

        procedureWillFinish(withErrors: resultingErrors)

        willChangeValue(forKey: .finished)
        observers.forEach { $0.will(finish: self, withErrors: resultingErrors) }

        _stateLock.withCriticalScope { state = .finished }

        procedureDidFinish(withErrors: resultingErrors)
        observers.forEach { $0.did(finish: self, withErrors: resultingErrors) }

        log.notice(message: "Did finish with \(messageSuffix).")

        didChangeValue(forKey: .finished)
    }

    // MARK: - Observers

    /**
     Add an observer to the procedure.

     - parameter observer: type conforming to protocol `ProcedureObserver`.
     */
    open func add<Observer: ProcedureObserver>(observer: Observer) where Observer.Procedure == Procedure {

        protectedProperties.write {
            $0.observers.append(AnyObserver(base: observer))
        }

        observer.didAttach(to: self)
    }
}

// MARK: Dependencies

public extension Procedure {

    public final func add<Dependency: ProcedureProtocol>(dependency: Dependency) {
        guard let op = dependency as? Operation else {
            assertionFailure("Adding dependencies which do not subclass Foundation.Operation is not supported.")
            return
        }
        add(dependency: op)
    }
}

// MARK: Conditions

extension Procedure {

    final class EvaluateConditions: GroupProcedure, InputProcedure, OutputProcedure {

        var input: Pending<[Condition]> = .pending
        var output: Pending<ConditionResult> = .pending

        init(conditions: Set<Condition>) {
            let ops = Array(conditions)
            input = .ready(ops)
            super.init(operations: ops)
        }

        override func procedureWillFinish(withErrors errors: [Error]) {
            output = .ready(process(withErrors: errors))
        }

        override func procedureWillCancel(withErrors errors: [Error]) {
            output = .ready(process(withErrors: errors))
        }

        private func process(withErrors errors: [Error]) -> ConditionResult {
            guard errors.isEmpty else {
                return .failure(ProcedureKitError.FailedConditions(errors: errors))
            }
            guard let conditions = input.value else {
                fatalError("Conditions must be set before the evaluation is performed.")
            }
            return conditions.reduce(.success(false)) { lhs, condition in
                // Unwrap the condition's output
                guard let rhs = condition.output.value else { return lhs }

                log.verbose(message: "evaluating \(lhs) with \(rhs)")

                switch (lhs, rhs) {
                // both results are failures
                case let (.failure(error), .failure(anotherError)):
                    if let error = error as? ProcedureKitError.FailedConditions {
                        return .failure(error.append(error: anotherError))
                    }
                    else if let anotherError = anotherError as? ProcedureKitError.FailedConditions {
                        return .failure(anotherError.append(error: error))
                    }
                    else {
                        return .failure(ProcedureKitError.FailedConditions(errors: [error, anotherError]))
                    }
                // new condition failed - so return it
                case (_, .failure(_)):
                    return rhs
                // first condition is ignored - so return the new one
                case (.success(false), _):
                    return rhs
                default:
                    return lhs
                }
            }
        }
    }

    func evaluateConditions() -> Procedure {

        func createEvaluateConditionsProcedure() -> EvaluateConditions {
            // Set the procedure on each condition
            conditions.forEach {
                $0.procedure = self
                $0.log.enabled = self.log.enabled
                $0.log.severity = self.log.severity
            }

            let evaluator = EvaluateConditions(conditions: conditions)
            evaluator.name = "\(operationName) Evaluate Conditions"

            super.addDependency(evaluator)
            return evaluator
        }

        assert(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")

        let evaluator = createEvaluateConditionsProcedure()

        // Add the direct dependencies of the procedure as direct dependencies of the evaluator
        directDependencies.forEach {
            evaluator.add(dependency: $0)
        }

        // Add an observer to the evaluator to see if any of the conditions failed.
        evaluator.addWillFinishBlockObserver { [weak self] evaluator, _ in
            guard let result = evaluator.output.value else { return }

            switch result {
            case .success(true):
                break
            case .success(false):
                self?.cancel()
            case let .failure(error):
                if let failedConditions = error as? ProcedureKitError.FailedConditions {
                    self?.cancel(withErrors: failedConditions.errors)
                }
                else {
                    self?.cancel(withError: error)
                }
            }
        }

        return evaluator
    }

    func add(dependencyOnPreviousMutuallyExclusiveProcedure procedure: Procedure) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        super.addDependency(procedure)
    }

    func add(directDependency: Operation) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        protectedProperties.write {
            $0.directDependencies.insert(directDependency)
        }
        super.addDependency(directDependency)
    }

    func remove(directDependency: Operation) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        protectedProperties.write {
            $0.directDependencies.remove(directDependency)
        }
        super.removeDependency(directDependency)
    }

    public final override var dependencies: [Operation] {
        return Array(directDependencies.union(indirectDependencies))
    }

    /**
     Add another `Operation` as a dependency. It is a programmatic error to call
     this method after the receiver has already started executing. Therefore, best
     practice is to add dependencies before adding them to operation queues.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     - parameter operation: a `Operation` instance.
     */
    public final override func addDependency(_ operation: Operation) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        add(directDependency: operation)
    }

    /**
     Remove another `Operation` as a dependency. It is a programmatic error to call
     this method after the receiver has already started executing. Therefore, best
     practice is to manage dependencies before adding them to operation
     queues.

     - requires: self must not have started yet. i.e. either hasn't been added
     to a queue, or is waiting on dependencies.
     - parameter operation: a `Operation` instance.
     */
    public final override func removeDependency(_ operation: Operation) {
        precondition(state <= .executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")
        remove(directDependency: operation)
    }

    /**
     Add a condition to the procedure.

     - parameter condition: a `Condition` which must be satisfied for the procedure to be executed.
     */
    public final func add(condition: Condition) {
        assert(state < .executing, "Cannot modify conditions after operation has begun executing, current state: \(state).")
        protectedProperties.write {
            $0.conditions.insert(condition)
        }
    }
}

// swiftlint:enable type_body_length

// swiftlint:enable file_length
