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
public class GroupOperation: Operation, OperationQueueDelegate {

    typealias ErrorsByOperation = [NSOperation: [ErrorType]]
    internal struct Errors {
        var fatal = Array<ErrorType>()
        var attemptedRecovery: ErrorsByOperation = [:]

        var previousAttempts: [ErrorType] {
            return Array(FlattenSequence(attemptedRecovery.values))
        }

        var all: [ErrorType] {
            get {
                var tmp: [ErrorType] = fatal
                tmp.appendContentsOf(previousAttempts)
                return tmp
            }
        }
    }

    private let finishingOperation = NSBlockOperation { }
    private var protectedErrors = Protector(Errors())

    /// - returns: the OperationQueue the group runs operations on.
    public let queue = OperationQueue()

    /// - returns: the operations which have been added to the queue
    public private(set) var operations: [NSOperation]

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
     This method is called when a child operation in the group will finish with errors.

     Often an operation will finish with errors become some of its pre-requisites were not
     met. Errors of this nature should be recoverable. This can be done by re-trying the
     original operation, but with another operation which fulfil the pre-requisites as a
     dependency.

     If the errors were recovered from, return true from this method, else return false.

     Errors which are not handled will result in the Group finishing with errors.

     - parameter errors: an [ErrorType], the errors of the child operation
     - parameter operation: the child operation which is finishing
     - returns: a Boolean, return true if the errors were handled, else return false.
     */
    public func willAttemptRecoveryFromErrors(errors: [ErrorType], inOperation operation: NSOperation) -> Bool {
        return false
    }

    /**
     This method is only called when a child operation finishes without any errors.

     - parameter operation: the child operation which will finish without errors
    */
    public func willFinishOperation(operation: NSOperation) {
        // no-op
    }

    @available(*, unavailable, message="Rewrite your GroupOperation subclass as this method is no longer used.")
    public func willFinishOperation(operation: NSOperation, withErrors errors: [ErrorType]) {
        var message = "Attention!!\n"
        message += "Rewrite your GroupOperation subclass as this method is no longer used.\n"
        message += "Override willFinishOperation(_: NSOperation) to manage scheduling of child operations."
        message += "Override willAttemptRecoveryFromErrors(_: [ErrorType], inOperation: NSOperation) to do error handling."
        message += "See code documentation for more details."
        assert(true, message)
    }

    @available(*, unavailable, renamed="willFinishOperation")
    public func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) { }

    internal func child(child: NSOperation, didEncounterFatalErrors errors: [ErrorType]) {
        addFatalErrors(errors)
    }

    internal func child(child: NSOperation, didAttemptRecoveryFromErrors errors: [ErrorType]) {
        protectedErrors.write { (inout tmp: Errors) in
            tmp.attemptedRecovery[child] = errors
        }
    }

    // MARK: - OperationQueueDelegate

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
            if willAttemptRecoveryFromErrors(errors, inOperation: operation) {
                child(operation, didAttemptRecoveryFromErrors: errors)
            }
            else {
                child(operation, didEncounterFatalErrors: errors)
            }
        }
        else if operation !== finishingOperation {
            willFinishOperation(operation)
        }
    }

    public func operationQueue(queue: OperationQueue, didFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) {

        if operation === finishingOperation {
            finish(fatalErrors)
            queue.suspended = true
        }
    }
}

public extension GroupOperation {

    internal var internalErrors: Errors {
        return protectedErrors.read { $0 }
    }

    /// - returns: the errors which could not be recovered from
    var fatalErrors: [ErrorType] {
        return internalErrors.fatal
    }

    /**
     Appends a fatal error.
     - parameter error: an ErrorType
    */
    final func addFatalError(error: ErrorType) {
        addFatalErrors([error])
    }

    /**
     Appends an array of fatal errors.
     - parameter errors: an [ErrorType]
     */
    final func addFatalErrors(errors: [ErrorType]) {
        protectedErrors.write { (inout tmp: Errors) in
            tmp.fatal.appendContentsOf(errors)
        }
    }

    internal func didRecoverFromOperationErrors(operation: NSOperation) {
        if let _ = internalErrors.attemptedRecovery[operation] {
            log.verbose("successfully recovered from errors in \(operation)")
            protectedErrors.write { (inout tmp: Errors) in
                tmp.attemptedRecovery.removeValueForKey(operation)
            }
        }
    }

    internal func didNotRecoverFromOperationErrors(operation: NSOperation) {
        log.verbose("failed to recover from errors in \(operation)")
        protectedErrors.write { (inout tmp: Errors) in
            if let errors = tmp.attemptedRecovery.removeValueForKey(operation) {
                tmp.fatal.appendContentsOf(errors)
            }
        }
    }
}

public extension GroupOperation {

    @available(*, unavailable, renamed="fatalErrors")
    var aggregateErrors: [ErrorType] {
        return fatalErrors
    }

    @available(*, unavailable, renamed="addFatalError")
    final func aggregateError(error: ErrorType) {
        addFatalError(error)
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
