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

    public init(operations ops: [NSOperation]) {
        operations = ops
        super.init()
        queue.suspended = true
        queue.delegate = self
    }

    public convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }

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

    public func addOperation(operation: NSOperation) {
        queue.addOperation(operation)
    }

    final func aggregateError(error: ErrorType) {
        aggregateErrors.append(error)
    }

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

