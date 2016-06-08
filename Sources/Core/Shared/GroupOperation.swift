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

    private let finishingOperation = NSBlockOperation { }
    private var _aggregateErrors = Protector(Array<ErrorType>())
    private var _uncommittedErrors = Protector(Array<ErrorType>())

    /// - returns: the OperationQueue the group runs operations on.
    public let queue = OperationQueue()

    /// - returns: the operations which have been added to the queue
    public private(set) var operations: [NSOperation]

    /// - returns: an aggregation of errors [ErrorType]
    public var aggregateErrors: Array<ErrorType> {
        var currentErrors = _aggregateErrors.read { $0 }
        currentErrors.appendContentsOf(_uncommittedErrors.read { $0 })
        return currentErrors
    }

    public override var userIntent: Operation.UserIntent {
        didSet {
            let (nsops, ops) = operations.splitNSOperationsAndOperations
            nsops.forEach { $0.setQualityOfServiceFromUserIntent(userIntent) }
            ops.forEach { $0.userIntent = userIntent }
        }
    }

    /**
    Designated initializer.

    - parameter operations: an array of `NSOperation`s.
    */
    public init(operations ops: [NSOperation]) {
        operations = ops
        super.init()
        name = "Group Operation"
        queue.suspended = true
        queue.delegate = self
        userIntent = operations.userIntent
        addObserver(WillCancelObserver { [unowned self] operation, errors in
            if operation === self {
                if errors.isEmpty {
                    self.operations.forEach { $0.cancel() }
                }
                else {
                    let (nsops, ops) = self.operations.splitNSOperationsAndOperations
                    nsops.forEach { $0.cancel() }
                    ops.forEach { $0.cancelWithError(OperationError.ParentOperationCancelledWithErrors(errors)) }
                }
                self.queue.cancelAllOperations()
            }
        })
    }

    /// Convenience initializer for direct usage without subclassing.
    public convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }

    /**
     Executes the group by adding the operations to the queue. Then
     starting the queue, and adding the finishing operation.
    */
    public override func execute() {
        addOperations(operations.filter { !self.queue.operations.contains($0) })
        queue.addOperation(finishingOperation)
        queue.suspended = false
    }

    /**
     Add an `NSOperation` to the group's queue.

     - parameter operation: an `NSOperation` instance.
    */
    public func addOperation(operation: NSOperation) {
        addOperations(operation)
    }

    /**
     Add multiple operations at once.

     - parameter operations: an array of `NSOperation` instances.
     */
    public func addOperations(operations: NSOperation...) {
        addOperations(operations)
    }

    /**
     Add multiple operations at once.

     - parameter operations: an array of `NSOperation` instances.
     */
    public func addOperations(additional: [NSOperation]) {
        if additional.count > 0 {
            additional.forEachOperation { $0.log.severity = log.severity }
            queue.addOperations(additional)
            operations.appendContentsOf(additional)
        }
    }

    /**
     Append an error to the list of aggregate errors. Subclasses can use this
     to maintain the errors received by operations within the group.

     - parameter error: an ErrorType to append.
    */
    public final func aggregateError(error: ErrorType) {
        log.warning("Aggregated error: \(error)")
        _uncommittedErrors.append(error)
    }

    /**
     This method is called every time one of the groups child operations
     is about to finish.

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
    public func willFinishOperation(operation: NSOperation, withErrors errors: [ErrorType]) {
        // no-op, subclasses can override for their own functionality.
    }

    @available(*, unavailable, renamed="willFinishOperation")
    public func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) { }

    internal func childOperation(child: NSOperation, didFinishWithErrors errors: [ErrorType]) {
        _uncommittedErrors.appendContentsOf(errors)
    }
}

extension GroupOperation {
    
    // Commits errors, replacing any uncomitted errors
    // This can be used by GroupOperation subclasses to override errors set by a previous operation
    // For example, in RetryOperation this is used to allow the RetryGenerator to indicate that the next
    // operation is "handling" the previous errors.
    
    public func commitErrors(errors: [ErrorType]) {
        log.warning("Committing errors, replacing uncommitted errors. Committing: \(errors)")
        _aggregateErrors.write { (aggregateErrors) in
            aggregateErrors.appendContentsOf(errors)
        }
        _uncommittedErrors.write { (lastOpErrors) in
            lastOpErrors.removeAll()
        }
    }
}

public protocol GroupOperationWillAddChildObserver: OperationObserverType {

    func groupOperation(group: GroupOperation, willAddChildOperation child: NSOperation)
}

extension GroupOperation {

    internal var willAddChildOperationObservers: [GroupOperationWillAddChildObserver] {
        return observers.flatMap { $0 as? GroupOperationWillAddChildObserver }
    }
}

extension GroupOperation: OperationQueueDelegate {

    /**
     The group operation acts as its own queue's delegate. When an operation is added to the queue,
     assuming that the finishing operation has not started (or finished), and the operation is not
     the finishing operation itself, then we add the operation as a dependency to the finishing
     operation.

     The purpose of this is to keep the finishing operation as the last child operation that executes
     when there are no more operations in the group.
    */
    public func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        assert(!finishingOperation.executing, "Cannot add new operations to a group after the group has started to finish.")
        assert(!finishingOperation.finished, "Cannot add new operations to a group after the group has completed.")

        if operation !== finishingOperation {

            willAddChildOperationObservers.forEach { $0.groupOperation(self, willAddChildOperation: operation) }

            finishingOperation.addDependency(operation)
        }
    }

    /**
     The group operation acts as it's own queue's delegate. When an operation finishes, if the
     operation is the finishing operation, we finish the group operation here. Else, the group is
     notified (using `operationDidFinish` that a child operation has finished.
    */
    public func operationQueue(queue: OperationQueue, willFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {

        if !errors.isEmpty {
            childOperation(operation, didFinishWithErrors: errors)
        }

        if operation !== finishingOperation {
            willFinishOperation(operation, withErrors: errors)
        }
    }

    public func operationQueue(queue: OperationQueue, didFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {
        
        if operation === finishingOperation {
            
            // NOTE: could combine the uncommitted into aggregate here, but the aggregateErrors accessor does this for us
            
            finish(aggregateErrors)
            queue.suspended = true
        }
    }
}

/**
 WillAddChildObserver is an observer which will execute a
 closure when the group operation it is attaches to adds a
 child operation to its queue.
 */
public struct WillAddChildObserver: GroupOperationWillAddChildObserver {
    public typealias BlockType = (group: GroupOperation, child: NSOperation) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .None

    /**
     Initialize the observer with a block.

     - parameter willAddChild: the `WillAddChildObserver.BlockType`
     - returns: an observer.
     */
    public init(willAddChild: BlockType) {
        self.block = willAddChild
    }

    /// Conforms to GroupOperationWillAddChildObserver
    public func groupOperation(group: GroupOperation, willAddChildOperation child: NSOperation) {
        block(group: group, child: child)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(operation: Operation) {
        didAttachToOperation?(operation: operation)
    }
}
