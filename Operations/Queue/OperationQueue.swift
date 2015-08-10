//
//  OperationQueue.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public protocol OperationQueueDelegate: class {
    func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation)
    func operationQueue(queue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [ErrorType])
}

public class OperationQueue: NSOperationQueue {

    public weak var delegate: OperationQueueDelegate? = .None

    public override func addOperation(op: NSOperation) {
        if let operation = op as? Operation {

            // Setup an observer to invoke the delegate methods
            let observer = BlockObserver(
                produceHandler: { [weak self] in
                    self?.addOperation($1)
                },
                finishHandler: { [weak self] (operation, errors) in
                    if let q = self {
                        q.delegate?.operationQueue(q, operationDidFinish: operation, withErrors: errors)
                    }
                }
            )

            operation.addObserver(observer)

            let dependencies = operation.conditions.flatMap {
                flatMap($0.dependencyForOperation(operation), { [$0] }) ?? []
            }

            for dependency in dependencies {
                operation.addDependency(dependency)
                addOperation(dependency)
            }

            // Check for exclusive mutability constraints
            let concurrencyCategories: [String] = operation.conditions.flatMap {
                flatMap($0) {
                    if !$0.isMutuallyExclusive { return .None }
                    return ["\($0.dynamicType)"]
                } ?? []
            }

            if !concurrencyCategories.isEmpty {
                let manager = ExclusivityManager.sharedInstance
                manager.addOperation(operation, categories: concurrencyCategories)

                operation.addObserver(BlockObserver(finishHandler: { (operation, _) in
                    manager.removeOperation(operation, categories: concurrencyCategories)
                }))
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

    public override func addOperations(ops: [AnyObject], waitUntilFinished wait: Bool) {
        if let ops = ops as? [NSOperation] {
            ops.map(addOperation)

            if wait {
                for operation in operations {
                    operation.waitUntilFinished()
                }
            }
        }
    }

}

