//
//  GroupOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation


/**
An `Operation` subclass which enables the grouping
of other operations. Use `GroupOperation`s to associate
related operations together, thereby creating higher
levels of abstractions.

Additionally, `GroupOperation`s are useful as a way
of creating Operations which may repeat themselves before
subsequent operations can run. For example, authentication
operations.
*/
public class GroupOperation: Operation {

    private let queue = OperationQueue()
    private let operations: [NSOperation]
    private let finishingOperation = NSBlockOperation(block: {})
    private var aggregateErrors = Array<ErrorType>()

    /**
    Designated initializer.

    :park: operations, an array of `NSOperation`s.
    */
    public init(operations ops: [NSOperation]) {
        operations = ops
        super.init()
        queue.suspended = true
        queue.delegate = self
    }

    public convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }

    /**
    Cancels all the groups operations.
    */
    public override func cancel() {
        queue.cancelAllOperations()
        super.cancel()
    }

    public override func execute() {
        for operation in operations {
            queue.addOperation(operation)
        }
        queue.suspended = false
        queue.addOperation(finishingOperation)
    }

    /**
    Add an `NSOperation` to the group's queue.
    
    :param: operation, an `NSOperation`
    */
    public func addOperation(operation: NSOperation) {
        queue.addOperation(operation)
    }

    final func aggregateError(error: ErrorType) {
        aggregateErrors.append(error)
    }

    /**
    This method is called every time one of the groups child operations
    finish.

    Over-ride this method to enable the following sort of behavior:
    
    ## Error handling. 
    
    Typically you will want to have code like this:
    
        if !errors.isEmpty {
            if operation is MyOperation, let error = errors.first as? MyOperation.Error {
                switch error {
                case .AnError:
                  println("Handle the error case")
                }
            }
        }
    
    So, if the errors array is not empty, it is important to know which kind of 
    errors the operation may have encountered, and then implement handling of
    any that are necessary.
    
    Note that if an operation has conditions, which fail, they will be returned
    as the first errors.

    ## Move results between operations. 
    
    Typically we use `GroupOperation` to
    compose and manage multiple operations into a single unit. This might 
    often need to move the results of one operation into the next one. So this
    can be done here.

    :param: operation, an `NSOperation`
    :param:, errors, an array of `ErrorType`s.
    */
    public func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        // no-op, subclasses can override for their own functionality.
    }
}

extension GroupOperation: OperationQueueDelegate {

    public func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        assert(!finishingOperation.finished && !finishingOperation.executing, "Cannot add new operations to a group after the group has completed.")

        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }
    }

    public func operationQueue(queue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [ErrorType]) {
        aggregateErrors.extend(errors)

        if operation === finishingOperation {
            queue.suspended = true
            finish(errors: aggregateErrors)
        }
        else {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}

