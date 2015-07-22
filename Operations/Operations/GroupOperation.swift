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

    private let _queue = OperationQueue()
    private let _finishingOperation = NSBlockOperation(block: {})
    private var _aggregateErrors = Array<ErrorType>()

    public init(operations: [NSOperation]) {
        super.init()

        _queue.suspended = true
        _queue.delegate = self

        for operation in operations {
            _queue.addOperation(operation)
        }
    }

    public convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }

    public override func cancel() {
        _queue.cancelAllOperations()
        super.cancel()
    }

    public override func execute() {
        _queue.suspended = false
        _queue.addOperation(_finishingOperation)
    }

    public func addOperation(operation: NSOperation) {
        _queue.addOperation(operation)
    }

    final func aggregateError(error: ErrorType) {
        _aggregateErrors.append(error)
    }

    public func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        // no-op, subclasses can override for their own functionality.
    }
}

extension GroupOperation: OperationQueueDelegate {

    public func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        assert(!_finishingOperation.finished && !_finishingOperation.executing, "Cannot add new operations to a group after the group has completed.")

        if operation !== _finishingOperation {
            _finishingOperation.addDependency(operation)
        }
    }

    public func operationQueue(queue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [ErrorType]) {
        _aggregateErrors.extend(errors)

        if operation === _finishingOperation {
            _queue.suspended = true
            finish(errors: _aggregateErrors)
        }
        else {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}

