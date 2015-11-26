//
//  Operation.swift
//  YapDB
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

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

        // Is evaluating conditions
        case EvaluatingConditions

        // Conditions have been satisfied, ready to execute
        case Ready

        // It is executing
        case Executing

        // Execution has completed, but not yet notified queue
        case Finishing

        // The operation has finished.
        case Finished

        func canTransitionToState(other: State) -> Bool {
            switch (self, other) {
            case (.Initialized, .Pending),
                (.Pending, .EvaluatingConditions),
                (.Pending, .Finishing),
                (.EvaluatingConditions, .Ready),
                (.Ready, .Executing),
                (.Ready, .Finishing),
                (.Executing, .Finishing),
                (.Finishing, .Finished):
                return true

            default:
                return false
            }
        }
    }

    // use the KVO mechanism to indicate that changes to "state" affect other properties as well
    class func keyPathsForValuesAffectingIsReady() -> Set<NSObject> {
        return ["state"]
    }

    class func keyPathsForValuesAffectingIsExecuting() -> Set<NSObject> {
        return ["state"]
    }

    class func keyPathsForValuesAffectingIsFinished() -> Set<NSObject> {
        return ["state"]
    }

    private let stateLock = NSLock()

    private lazy var _log: LoggerType = Logger()

    private var _state = State.Initialized
    private var _internalErrors = [ErrorType]()

    private(set) var conditions = [OperationCondition]()
    private(set) var observers = [OperationObserver]()

    private var state: State {
        get {
            return stateLock.withCriticalScope { _state }
        }
        set (newState) {
            willChangeValueForKey("state")

            log.verbose("\(operationName): \(_state) -> \(newState)")

            stateLock.withCriticalScope { () -> Void in

                switch (_state, newState) {
                case (.Finished, _):
                    break
                default:
                    assert(_state.canTransitionToState(newState), "Attempting to perform illegal cyclic state transition, \(_state) -> \(newState).")
                    _state = newState
                }
            }

            didChangeValueForKey("state")
        }
    }

    /// Access the internal errors collected by the Operation
    public var errors: [ErrorType] {
        return _internalErrors
    }

    /// Boolean flag to indicate that the Operation failed due to errors.
    public var failed: Bool {
        return errors.count > 0
    }

    /// Boolean indicator of the readyness of the Operation
    public override var ready: Bool {
        switch state {

        case .Initialized:
            // If the operation is cancelled, isReady should return true
            return cancelled

        case .Pending:
            // If the operation is cancelled, isReady should return true
            if cancelled {
                return true
            }

            if super.ready {
                evaluateConditions()
            }

            // Until conditions have been evaluated, we're not ready
            return false

        case .Ready:
            return super.ready || cancelled

        default:
            return false
        }
    }

    /// - returns: a Bool indicating whether or not the quality of service is .UserInitiated
    public var userInitiated: Bool {
        get {
            return qualityOfService == .UserInitiated
        }
        set {
            assert(state < .Executing, "Cannot modify userInitiated after execution has begun.")
            qualityOfService = newValue ? .UserInitiated : .Default
        }
    }

    /// Boolean indicator for whether the Operation is currently executing or not
    public override var executing: Bool {
        return state == .Executing
    }

    /// Boolean indicator for whether the Operation has finished or not
    public override var finished: Bool {
        return state == .Finished
    }

    // MARK: - Logging

    /** 
     # Access the logger for this Operation
     The `log` property can be used as the interface to access the logger.
     e.g. to output a message with `LogSeverity.Info` from inside
     the `Operation`, do this:
    
    ```swift
    log.info("\(operationName): This is my message")
    ```
    
     To adjust the instance severity of the LoggerType for the
     `Operation`, access it via this property too:
    
    ```swift
    log.severity = .Verbose
    ```
    
     Note, that Swift does not allow changing the property
     types of super classes. See `getLogger()` for info
     about using a custom logger.
    */
    public var log: LoggerType {
        get { return getLogger() }
        set { setLogger(newValue) }
    }

    /**
     # Custom LoggerType
     
     To utilise a custom logger within an `Operation` subclass
     create an instance variable for your logger, and then
     override this method to return it. E.g.
     
     ```swift
     var _customLogger: CustomLogger // conforms to LoggerType

     override func getLogger() -> LoggerType {
         return _customLogger
     }
     ```
     
     - see: `setLogger(: LoggerType)`
     - returns: a `LoggerType`.
    */
    public func getLogger() -> LoggerType {
        return _log
    }

    /**
     # Custom LoggerType

     To utilise a custom logger within an `Operation` subclass
     create an instance variable for your logger, and then
     override this method to set it. E.g.

     ```swift
     var _customLogger: CustomLogger // conforms to LoggerType

     override func setLogger(newLogger: LoggerType) {
        _customLogger = CustomLogger(severity: newLogger.severity, logger: newLogger.logger)
     }
     ```

     - see: `getLogger() -> LoggerType`
     */
    public func setLogger(newLogger: LoggerType) {
        _log = Logger(severity: newLogger.severity)
    }

    /**
    Indicates that the Operation can now begin to evaluate readiness conditions,
    if appropriate.
    */
    func willEnqueue() {
        state = .Pending
    }

    private func evaluateConditions() {
        assert(state == .Pending && cancelled == false, "\(__FUNCTION__) was called out of order.")
        state = .EvaluatingConditions
        OperationConditionEvaluator.evaluate(conditions, operation: self) { errors in
            self._internalErrors.appendContentsOf(errors)
            self.state = .Ready
        }
    }

    // MARK: - Conditions

    /**
    Add a condition to the to the operation, can only be done prior to the operation starting.

    - parameter condition: type conforming to protocol `OperationCondition`.
    */
    public func addCondition(condition: OperationCondition) {
        assert(state < .Executing, "Cannot modify conditions after execution has begun, current state: \(state).")
        conditions.append(condition)
    }

    // MARK: - Observers

    /**
    Add an observer to the to the operation, can only be done prior to the operation starting.

    - parameter observer: type conforming to protocol `OperationObserver`.
    */
    public func addObserver(observer: OperationObserver) {
        assert(state < .Executing, "Cannot modify observers after execution has begun, current state: \(state).")
        observers.append(observer)
    }

    /**
    Add another `NSOperation` as a dependency. It is a programmatic error to call this method after the receiver has 
    already started executing. Therefore, best practice is to add dependencies before adding them to operation
    queues.
    
    - parameter operation: a `NSOperation` instance.
    */
    public override func addDependency(operation: NSOperation) {
        assert(state <= .Executing, "Dependencies cannot be modified after execution has begun, current state: \(state).")        
        super.addDependency(operation)
    }

    // MARK: - Execution and Cancellation

    /// Starts the operation, correctly managing the cancelled state. Cannot be over-ridden
    public override final func start() {
        // NSOperation.start() has important logic which shouldn't be bypassed
        super.start()

        // If the operation has been cancelled, we still need to enter the finished state
        if cancelled {
            finish()
        }
    }

    /// Triggers execution of the operation's task, correctly managing errors and the cancelled state. Cannot be over-ridden
    public override final func main() {
        assert(state == .Ready, "This operation must be performed on an operation queue, current state: \(state).")

        if _internalErrors.isEmpty && !cancelled {
            state = .Executing
            log.info("\(operationName): did start")
            observers.forEach { $0.operationDidStart(self) }
            execute()
        }
        else {
            finish()
        }
    }

    /**
    Subclasses should override this method to perform their specialized task.
    They must call a finish methods in order to complete.
    */
    public func execute() {
        print("\(self.dynamicType) must override `execute()`.", terminator: "")
        
        finish()
    }

    /**
    Cancel the operation with an error.
    
    - parameter error: an optional `ErrorType`.
    */
    public func cancelWithError(error: ErrorType? = .None) {
        if let error = error {
            _internalErrors.append(error)
            log.warning("\(operationName): did cancel with error: \(error).")
        }
        else {
            log.info("\(operationName): did cancel.")
        }
        cancel()
    }

    /**
    Produce another operation on the same queue that this instance is on.

    - parameter operation: a `NSOperation` instance.
    */
    public final func produceOperation(operation: NSOperation) {
        log.info("\(operationName): did produce \(operation.operationName)")
        observers.forEach { $0.operation(self, didProduceOperation: operation) }
    }
    
    // MARK: Finishing
    
    /**
    A private property to ensure we only notify the observers once that the
    operation has finished.
    */
    private var hasFinishedAlready = false

    /**
    Finish method which must be called eventually after an operation has
    begun executing, unless it is cancelled.

    - parameter errors: an array of `ErrorType`, which defaults to empty.
    */
    final public func finish(errors: [ErrorType] = []) {
        if !hasFinishedAlready {
            hasFinishedAlready = true
            state = .Finishing

            _internalErrors.appendContentsOf(errors)
            finished(_internalErrors)

            if errors.isEmpty {
                log.info("\(operationName): did finish with no errors.")
            }
            else {
                log.warning("\(operationName): did finish with errors: \(errors).")
            }

            observers.forEach { $0.operationDidFinish(self, errors: self._internalErrors) }

            state = .Finished
        }
    }
    
    /// Convenience method to simplify finishing when there is only one error.
    final public func finish(error: ErrorType?) {
        if let error = error {
            finish([error])
        }
        else {
            finish()
        }
    }

    /**
    Subclasses may override `finished(_:)` if they wish to react to the operation
    finishing with errors.
    
    - parameter errors: an array of `ErrorType`.
    */
    public func finished(errors: [ErrorType]) {
        // No op.
    }

    /**
    Public override which deliberately crashes your app, as usage is considered an antipattern

    To promote best practices, where waiting is never the correct thing to do,
    we will crash the app if this is called. Instead use discrete operations and
    dependencies, or groups, or semaphores or even NSLocking.
    
    */
    public override func waitUntilFinished() {
        fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™. Post a question in https://github.com/danthorpe/Operations if you are unsure.")
    }
}

private func <(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

private func ==(lhs: Operation.State, rhs: Operation.State) -> Bool {
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
}

/// OperationError is Equatable.
public func ==(a: OperationError, b: OperationError) -> Bool {
    switch (a, b) {
    case (.ConditionFailed, .ConditionFailed):
        return true
    case let (.OperationTimedOut(aTimeout), .OperationTimedOut(bTimeout)):
        return aTimeout == bTimeout
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
    public func addDependencies(dependencies: [NSOperation]) {
        dependencies.forEach(addDependency)
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

