//
//  Operation.swift
//  YapDB
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

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

    class func keyPathsForValuesAffectingIsCancelled() -> Set<NSObject> {
        return ["state"]
    }


    private var _state = State.Initialized

    private var state: State {
        get {
            return _state
        }
        set (newState) {
            willChangeValueForKey("state")

            switch (_state, newState) {
            case (.Finished, _):
                break
            default:
                assert(_state != newState, "Attempting to perform illegal cyclic state transition.")
                _state = newState
            }

            didChangeValueForKey("state")
        }
    }

    public override var ready: Bool {
        switch (cancelled, state) {

        case (true, _):
            // If the operation is cancelled, isReady should return true
            return true

        case (false, .Pending):

            if super.ready {
                evaluateConditions()
            }

            // Until conditions have been evaluated, we're not ready
            return false

        case (false, .Ready):
            return super.ready

        default:
            return false
        }
    }

    public override var executing: Bool {
        return state == .Executing
    }
    
    public override var finished: Bool {
        return state == .Finished
    }

    /**
    Indicates that the Operation can now begin to evaluate readiness conditions,
    if appropriate.
    */
    func willEnqueue() {
        state = .Pending
    }

    private func evaluateConditions() {
        assert(state == .Pending, "\(__FUNCTION__) was called out of order.")
        state = .EvaluatingConditions
        if conditions.count > 0 {
            OperationConditionEvaluator.evaluate(conditions, operation: self) { errors in
                if errors.isEmpty {
                    self.state = .Ready
                }
                else {
                    self.finish(errors: errors)
                }
            }
        }
        else {
            state = .Ready
        }
    }

    // MARK: - Conditions

    private(set) var conditions = [OperationCondition]()

    public func addCondition(condition: OperationCondition) {
        assert(state < .Executing, "Cannot modify conditions after execution has begun.")
        conditions.append(condition)
    }

    // MARK: - Observers
    
    private(set) var observers = [OperationObserver]()
    
    public func addObserver(observer: OperationObserver) {
        assert(state < .Executing, "Cannot modify observers after execution has begun.")
        
        observers.append(observer)
    }
    
    public override func addDependency(operation: NSOperation) {
        assert(state <= .Executing, "Dependencies cannot be modified after execution has begun.")
        
        super.addDependency(operation)
    }

    // MARK: - Execution and Cancellation
    
    public override final func start() {
        assert(state == .Ready, "This operation must be performed on an operation queue.")
        
        state = .Executing
        
        observers.map { $0.operationDidStart(self) }
        
        execute()
    }
    
    /**
    Subclasses should override this method to perform their specialized task.
    They must call a finish methods in order to complete.
    */
    public func execute() {
        print("\(self.dynamicType) must override `execute()`.")
        
        finish()
    }
    
    private var _internalErrors = [ErrorType]()

    public func cancelWithError(error: ErrorType? = .None) {
        if let error = error {
            _internalErrors.append(error)
        }
        
        cancel()
    }
    
    public final func produceOperation(operation: NSOperation) {
        observers.map { $0.operation(self, didProduceOperation: operation) }
    }
    
    // MARK: Finishing
    
    /**
    A private property to ensure we only notify the observers once that the
    operation has finished.
    */
    private var hasFinishedAlready = false

    /**
    Finish method which must be called eventually after an operation has
    begun executing.
    */
    final public func finish(errors: [ErrorType] = []) {
        if !hasFinishedAlready {
            hasFinishedAlready = true
            state = .Finishing
            
            let combinedErrors = _internalErrors + errors
            finished(combinedErrors)
            
            observers.map { $0.operationDidFinish(self, errors: combinedErrors) }
            
            state = .Finished
        }
    }
    
    /**
    Convenience method to simplify finishing when there is only one error.
    */
    final public func finish(error: ErrorType?) {
        if let error = error {
            finish(errors: [error])
        }
        else {
            finish()
        }
    }

    /**
    Subclasses may override `finished(_:)` if they wish to react to the operation
    finishing with errors.
    */
    public func finished(errors: [ErrorType]) {
        // No op.
    }
    
    public override func waitUntilFinished() {
        /**
        To promote best practices, where waiting is never the correct thing to do,
        we will crash the app if this is called. Instead use discrete operations and
        dependencies, or groups, or semaphores or even NSLocking.
        */
        fatalError("Waiting on operations is an anti-pattern. Remove this ONLY if you're absolutely sure there is No Other Way™. Post a question in https://github.com/danthorpe/Operations if you are unsure.")
    }
}


private func <(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

private func ==(lhs: Operation.State, rhs: Operation.State) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

extension NSOperation {

    /// Chain completion blocks
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
    
    /// Add multiple depdendencies to the operation.
    func addDependencies(dependencies: [NSOperation]) {
        dependencies.map { self.addDependency($0) }
    }
}


