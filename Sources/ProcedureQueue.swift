//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public protocol OperationQueueDelegate: class {

    /**
     The operation queue will add a new operation. This is for information only, the
     delegate cannot affect whether the operation is added, or other control flow.

     - paramter queue: the `OperationQueue`.
     - paramter operation: the `Operation` instance about to be added.
     */
    func operationQueue(_ queue: OperationQueue, willAddOperation operation: Operation)

    /**
     An operation will finish on the queue.

     - parameter queue: the `OperationQueue`.
     - parameter operation: the `Operation` instance which finished.
     - parameter errors: an array of `Error`s.
     */
    func operationQueue(_ queue: OperationQueue, willFinishOperation operation: Operation)

    /**
     An operation did finish on the queue.

     - parameter queue: the `OperationQueue`.
     - parameter operation: the `Operation` instance which finished.
     - parameter errors: an array of `Error`s.
     */
    func operationQueue(_ queue: OperationQueue, didFinishOperation operation: Operation)
}

/**
 A protocol which the `OperationQueue`'s delegate must conform to. The delegate is informed
 when the queue is about to add an operation/procedure, and when they finish. Because it is a
 delegate protocol, conforming types must be classes, as the queue weakly owns it.
 */
public protocol ProcedureQueueDelegate: OperationQueueDelegate {

    /**
     The procedure queue will add a new operation. This is for information only, the
     delegate cannot affect whether the operation is added, or other control flow.

     - paramter queue: the `ProcedureQueue`.
     - paramter operation: the `Operation` instance about to be added.
     */
    func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation)

    /**
     An operation will finish on the queue.

     - parameter queue: the `ProcedureQueue`.
     - parameter operation: the `Operation` instance which finished.
     - parameter errors: an array of `Error`s.
     */
    func procedureQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [Error])

    /**
     An operation has finished on the queue.

     - parameter queue: the `ProcedureQueue`.
     - parameter operation: the `Operation` instance which finished.
     - parameter errors: an array of `Error`s.
     */
    func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation, withErrors errors: [Error])

    /**
     The operation queue will add a new operation via produceOperation().
     This is for information only, the delegate cannot affect whether the operation
     is added, or other control flow.

     - paramter queue: the `ProcedureQueue`.
     - paramter operation: the `Operation` instance about to be added.
     */
    func procedureQueue(_ queue: ProcedureQueue, willProduceOperation operation: Operation)
}

/**
 An `OperationQueue` subclass which supports the features of ProcedureKit. All functionality
 is achieved via the overridden functionality of `addOperation`.
 */
open class ProcedureQueue: OperationQueue {

    private class MainProcedureQueue: ProcedureQueue {
        override init() {
            super.init()
            underlyingQueue = DispatchQueue.main
            maxConcurrentOperationCount = 1
        }
    }

    private static let sharedMainQueue = MainProcedureQueue()

    /**
     Override OperationQueue's main to return the main queue as an ProcedureQueue

     - returns: The main queue
     */
    open override class var main: ProcedureQueue {
        return sharedMainQueue
    }

    /**
     The queue's delegate, helpful for reporting activity.

     - parameter delegate: a weak `ProcedureQueueDelegate?`
     */
    open weak var delegate: ProcedureQueueDelegate? = nil

    /**
     Adds the operation to the queue. Subclasses which override this method must call this
     implementation as it is critical to how ProcedureKit function.

     - parameter op: an `Operation` instance.
     */
    // swiftlint:disable function_body_length
    public func add(operation: Operation) {

        defer {
            super.addOperation(operation)
        }

        guard let procedure = operation as? Procedure else {

            operation.addCompletionBlock { [weak self, weak operation] in
                if let queue = self, let operation = operation {
                    queue.delegate?.operationQueue(queue, didFinishOperation: operation)
                }
            }

            delegate?.operationQueue(self, willAddOperation: operation)

            return
        }


/** --> Logging
        procedure.log.verbose("Adding to queue")
*/
        /// Add an observer so that any produced operations are added to the queue
        procedure.addDidProduceOperationBlockObserver { [weak self] (_, produced) in
            if let queue = self {
                queue.delegate?.procedureQueue(queue, willProduceOperation: produced)
                queue.add(operation: produced)
            }
        }

        /// Add an observer to invoke the will finish delegate method
        procedure.addWillFinishBlockObserver { [weak self] procedure, errors in
            if let queue = self {
                self?.delegate?.procedureQueue(queue, willFinishOperation: procedure, withErrors: errors)
            }
        }

        /// Add an observer to invoke the did finish delegate method
        procedure.addDidFinishBlockObserver { [weak self] procedure, errors in
            if let queue = self {
                queue.delegate?.procedureQueue(queue, didFinishOperation: procedure, withErrors: errors)
            }
        }

/* -- > Conditions

            /// Process any conditions
            if procedure.conditions.count > 0 {

                /// Check for mutual exclusion conditions
                let manager = ExclusivityManager.sharedInstance
                let mutuallyExclusiveConditions = operation.conditions.filter { $0.mutuallyExclusive }
                var previousMutuallyExclusiveOperations = Set<NSOperation>()
                for condition in mutuallyExclusiveConditions {
                    let category = "\(condition.category)"
                    if let previous = manager.addOperation(operation, category: category) {
                        previousMutuallyExclusiveOperations.insert(previous)
                    }
                }

                // Create the condition evaluator
                let evaluator = operation.evaluateConditions()

                // Get the condition dependencies
                let indirectDependencies = operation.indirectDependencies

                // If there are dependencies
                if indirectDependencies.count > 0 {

                    // Filter out the indirect dependencies which have already been added to the queue
                    let indirectDependenciesToProcess = indirectDependencies.filter { !self.operations.contains($0) }

                    // Iterate through the indirect dependencies
                    indirectDependenciesToProcess.forEach {

                        // Indirect dependencies are executed after
                        // any previous mutually exclusive operation(s)
                        $0.addDependencies(previousMutuallyExclusiveOperations)

                        // Indirect dependencies are executed after
                        // all direct dependencies
                        $0.addDependencies(operation.directDependencies)

                        // Only evaluate conditions after all indirect
                        // dependencies have finished
                        evaluator.addDependency($0)
                    }

                    // Add indirect dependencies
                    addOperations(indirectDependenciesToProcess)
                }

                // Add the evaluator
                addOperation(evaluator)
            }
*/

        // Indicate to the operation that it is to be enqueued
        procedure.willEnqueue()

        delegate?.procedureQueue(self, willAddOperation: procedure)

    }

    // swiftlint:enable function_body_length


    /**
     Adds the operations to the queue.

     - parameter ops: an array of `NSOperation` instances.
     - parameter wait: a Bool flag which is ignored.
     */
    open override func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        ops.forEach(addOperation)
    }

    /// Overrides and wraps the Swift 3 interface
    open override func addOperation(_ operation: Operation) {
        add(operation: operation)
    }
}


/// Public extensions on OperationQueue
public extension OperationQueue {

    /**
     Add operations to the queue as an array
     - parameters ops: a array of `NSOperation` instances.
     */
    func add<S>(operations: S) where S: Sequence, S.Iterator.Element: Operation {
        addOperations(Array(operations), waitUntilFinished: false)
    }

    /**
     Add operations to the queue as a variadic parameter
     - parameters ops: a variadic array of `NSOperation` instances.
     */
    func add(operations: Operation...) {
        add(operations: operations)
    }
}
