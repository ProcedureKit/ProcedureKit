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

    /// - returns: an aggregation of errors [ErrorType]
    public private(set) var aggregateErrors = Array<ErrorType>()

    /**
    Designated initializer.

    - parameter operations: an array of `NSOperation`s.
    */
    public init(operations ops: [NSOperation]) {
        operations = ops
        super.init()
        queue.suspended = true
        queue.delegate = self
    }

    /// Convenience intiializer for direct usage without subclassing.
    public convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }

    /// Cancels all the groups operations.
    public override func cancel() {
        queue.cancelAllOperations()
        super.cancel()
    }

    /**
    Executes the group by adding the operations to the queue. Then 
    starting the queue, and adding the finishing operation.
    */
    public override func execute() {
        let _operations = operations.flatMap { return $0 as? Operation }
        for op in _operations {
            op.log.severity = log.severity
        }
        addOperations(operations)
        queue.suspended = false
        queue.addOperation(finishingOperation)
    }

    /**
    Add an `NSOperation` to the group's queue.
    
    - parameter operation: an `NSOperation` instance.
    */
    public func addOperation(operation: NSOperation) {
        log.info("\(operationName): add operation to group \(operation.operationName)")
        queue.addOperation(operation)
    }

    /**
    Add multiple operations at once.
    
    - parameter operations: an array of `NSOperation` instances.
    */
    public func addOperations(operations: [NSOperation]) {
        log.info("\(operationName): add operations to group \(operations.map { $0.operationName })")
        queue.addOperations(operations, waitUntilFinished: false)
    }

    /**
     Append an error to the list of aggregate errors. Subclasses can use this
     to maintain the errors received by operations within the group.
     
     - parameter error: an ErrorType to append.
    */
    public final func aggregateError(error: ErrorType) {
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

    - parameter operation: the child `NSOperation` that has just finished.
    - parameter errors: an array of `ErrorType`s.
    */
    public func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        // no-op, subclasses can override for their own functionality.
    }
}

extension GroupOperation: OperationQueueDelegate {

    /**
    The group operation acts as it's own queue's delegate. When an operation is added to the queue,
    assuming that the finishing operation has not started (or finished), and the operation is not
    the finishing operation itself, then we add the operation as a dependency to the finishing
    operation.
    
    The purpose of this is to keep the finishing operation as the last child operation that executes
    when there are no more operations in the group.
    */
    public func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        assert(!finishingOperation.finished && !finishingOperation.executing, "Cannot add new operations to a group after the group has completed.")

        if operation !== finishingOperation {
            finishingOperation.addDependency(operation)
        }
    }

    /**
    The group operation acts as it's own queue's delegate. When an operation finishes, if the
    operation is the finishing operation, we finish the group operation here. Else, the group is
    notified (using `operationDidFinish` that a child operation has finished.
    */
    public func operationQueue(queue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [ErrorType]) {
        aggregateErrors.appendContentsOf(errors)

        if operation === finishingOperation {
            queue.suspended = true
            finish(aggregateErrors)
        }
        else {
            operationDidFinish(operation, withErrors: errors)
        }
    }
}

