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

    private let finishingOperation = Foundation.BlockOperation { }
    private var _aggregateErrors = Protector(Array<ErrorProtocol>())

    /// - returns: the OperationQueue the group runs operations on.
    public let queue = OperationQueue()

    /// - returns: the operations which have been added to the queue
    public private(set) var operations: [Foundation.Operation]

    /// - returns: an aggregation of errors [ErrorType]
    public var aggregateErrors: Array<ErrorProtocol> {
        return _aggregateErrors.read { $0 }
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
    public init(operations ops: [Foundation.Operation]) {
        operations = ops
        super.init()
        name = "Group Operation"
        queue.isSuspended = true
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
                    ops.forEach { $0.cancelWithError(OperationError.parentOperationCancelledWithErrors(errors)) }
                }
                self.queue.cancelAllOperations()
            }
        })
    }

    /// Convenience initializer for direct usage without subclassing.
    public convenience init(operations: Foundation.Operation...) {
        self.init(operations: operations)
    }

    /**
     Executes the group by adding the operations to the queue. Then
     starting the queue, and adding the finishing operation.
    */
    public override func execute() {
        addOperations(operations.filter { !self.queue.operations.contains($0) })
        queue.addOperation(finishingOperation)
        queue.isSuspended = false
    }

    /**
     Add an `NSOperation` to the group's queue.

     - parameter operation: an `NSOperation` instance.
    */
    public func addOperation(_ operation: Foundation.Operation) {
        addOperations(operation)
    }

    /**
     Add multiple operations at once.

     - parameter operations: an array of `NSOperation` instances.
     */
    public func addOperations(_ operations: Foundation.Operation...) {
        addOperations(operations)
    }

    /**
     Add multiple operations at once.

     - parameter operations: an array of `NSOperation` instances.
     */
    public func addOperations(_ additional: [Foundation.Operation]) {
        if additional.count > 0 {
            additional.forEachOperation { $0.log.severity = log.severity }
            queue.addOperations(additional)
            operations.append(contentsOf: additional)
        }
    }

    /**
     Append an error to the list of aggregate errors. Subclasses can use this
     to maintain the errors received by operations within the group.

     - parameter error: an ErrorType to append.
    */
    public final func aggregateError(_ error: ErrorProtocol) {
        log.warning("Aggregated error: \(error)")
        _aggregateErrors.append(error)
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
    public func willFinishOperation(_ operation: Foundation.Operation, withErrors errors: [ErrorProtocol]) {
        // no-op, subclasses can override for their own functionality.
    }

    @available(*, unavailable, renamed:"willFinishOperation")
    public func operationDidFinish(_ operation: Foundation.Operation, withErrors errors: [ErrorProtocol]) { }

    internal func childOperation(_ child: Foundation.Operation, didFinishWithErrors errors: [ErrorProtocol]) {
        _aggregateErrors.appendContentsOf(errors)
    }
}

public protocol GroupOperationWillAddChildObserver: OperationObserverType {

    func groupOperation(_ group: GroupOperation, willAddChildOperation child: Foundation.Operation)
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
    public func operationQueue(_ queue: OperationQueue, willAddOperation operation: Foundation.Operation) {
        assert(!finishingOperation.isExecuting, "Cannot add new operations to a group after the group has started to finish.")
        assert(!finishingOperation.isFinished, "Cannot add new operations to a group after the group has completed.")

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
    public func operationQueue(_ queue: OperationQueue, willFinishOperation operation: Foundation.Operation, withErrors errors: [ErrorProtocol]) {

        if !errors.isEmpty {
            childOperation(operation, didFinishWithErrors: errors)
        }

        if operation !== finishingOperation {
            willFinishOperation(operation, withErrors: errors)
        }
    }

    public func operationQueue(_ queue: OperationQueue, didFinishOperation operation: Foundation.Operation, withErrors errors: [ErrorProtocol]) {

        if operation === finishingOperation {
            finish(aggregateErrors)
            queue.isSuspended = true
        }
    }
}

/**
 WillAddChildObserver is an observer which will execute a
 closure when the group operation it is attaches to adds a
 child operation to its queue.
 */
public struct WillAddChildObserver: GroupOperationWillAddChildObserver {
    public typealias BlockType = (group: GroupOperation, child: Foundation.Operation) -> Void

    private let block: BlockType

    /// - returns: a block which is called when the observer is attached to an operation
    public var didAttachToOperation: DidAttachToOperationBlock? = .none

    /**
     Initialize the observer with a block.

     - parameter willAddChild: the `WillAddChildObserver.BlockType`
     - returns: an observer.
     */
    public init(willAddChild: BlockType) {
        self.block = willAddChild
    }

    /// Conforms to GroupOperationWillAddChildObserver
    public func groupOperation(_ group: GroupOperation, willAddChildOperation child: Foundation.Operation) {
        block(group: group, child: child)
    }

    /// Base OperationObserverType method
    public func didAttachToOperation(_ operation: Operation) {
        didAttachToOperation?(operation: operation)
    }
}
