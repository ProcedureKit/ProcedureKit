//
//  OperationQueue.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A protocol which the `OperationQueue`'s delegate must conform to. The delegate is informed
when the queue is about to add an operation, and when operations finish. Because it is a 
delegate protocol, conforming types must be classes, as the queue weakly owns it.
*/
public protocol OperationQueueDelegate: class {

    /**
    The operation queue will add a new operation. This is for information only, the 
    delegate cannot affect whether the operation is added, or other control flow.
    
    - paramter queue: the `OperationQueue`.
    - paramter operation: the `NSOperation` instance about to be added.
    */
    func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation)

    /**
    An operation has finished on the queue.
    
    - parameter queue: the `OperationQueue`.
    - parameter operation: the `NSOperation` instance which finished.
    - parameter errors: an array of `ErrorType`s.
    */
    func operationQueue(queue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [ErrorType])
}

/**
An `NSOperationQueue` subclass which supports the features of Operations. All functionality
is achieved via the overridden functionality of `addOperation`.
*/
public class OperationQueue: NSOperationQueue {

    /**
    The queue's delegate, helpful for reporting activity.
    
    - parameter delegate: a weak `OperationQueueDelegate?`
    */
    public weak var delegate: OperationQueueDelegate? = .None

    /**
    Adds the operation to the queue. Subclasses which override this method must call this
    implementation as it is critical to how Operations function.
    
    - parameter op: an `NSOperation` instance.
    */
    public override func addOperation(op: NSOperation) {
        if let operation = op as? Operation {

            /// Add an observer so that any produced operations are added to the queue
            operation.addObserver(ProducedOperationObserver { [weak self] in
                self?.addOperation($1)
            })

            /// Add an observer to invove the did finish delegate method
            operation.addObserver(FinishedObserver { [weak self] operation, errors in
                if let q = self {
                    q.delegate?.operationQueue(q, operationDidFinish: operation, withErrors: errors)
                }
            })

            let dependencies = operation.conditions.flatMap {
                $0.dependencyForOperation(operation)
            }

            for dependency in dependencies {
                operation.addDependency(dependency)
                addOperation(dependency)
            }

            // Check for mutual exclusion constraints
            //// TODO: Move this all to before adding any condition dependencies
            //// to the queue. e.g. line 77.
            //// This is because the `manager.addOperation()` may call `addDependency`
            //// which should be done before adding the operation to a queue.
            let manager = ExclusivityManager.sharedInstance
            let exclusive = operation.conditions.filter { $0.isMutuallyExclusive }
            for condition in exclusive {
                let category = "\(condition.dynamicType)"
                let mutuallyExclusiveOperation: NSOperation = condition.dependencyForOperation(operation) ?? operation
                manager.addOperation(mutuallyExclusiveOperation, category: category)
            }

            // Indicate to the operation that it is to be enqueued
            operation.willEnqueue()
        }
        else {

            op.addCompletionBlock { [weak self, weak op] in
                if let queue = self, let op = op {
                    queue.delegate?.operationQueue(queue, operationDidFinish: op, withErrors: [])
                }
            }
        }

        delegate?.operationQueue(self, willAddOperation: op)

        super.addOperation(op)
    }

    /**
    Adds the operations to the queue.

    - parameter ops: an array of `NSOperation` instances.
    - parameter wait: a Bool flag which is ignored.
    */
    public override func addOperations(ops: [NSOperation], waitUntilFinished wait: Bool) {
        ops.forEach(addOperation)
    }
}


public extension NSOperationQueue {

    /**
     Add operations to the queue as a variadic parameter
     - parameters ops: a variadic array of `NSOperation` instances.
    */
    func addOperations(ops: NSOperation...) {
        addOperations(ops, waitUntilFinished: false)
    }
}
