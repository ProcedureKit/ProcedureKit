//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation

/**
 A protocol which the `ProcedureQueue`'s delegate must conform to. The delegate is informed
 when the queue is about to add an operation/procedure, and when they finish. Because it is a
 delegate protocol, conforming types must be classes, as the queue weakly owns it.
 
 There are slight differences depending on whether an Operation subclass or a Procedure subclass
 is being added to a ProcedureQueue.
 
 For an Operation subclass, the delegate callbacks are:
 
    - procedureQueue(_:, willAddOperation:, context:)
    - procedureQueue(_:, didAddOperation:, context:)
    - procedureQueue(_:, didFinishOperation:)
 
 If you get the first, you are guaranteed* to get the other two callbacks once the Operation
 finishes (*unless you later modify the completionBlock - which is a bad idea - or your Operation
 never finishes - which is also a bad idea).
 
 For a Procedure subclass, the delegate callbacks are:
 
    - procedureQueue(_:, willAddProcedure:, context:)
    - procedureQueue(_:, didAddProcedure:, context:)
    - procedureQueue(_:, willFinishProcedure:)
    - procedureQueue(_:, didFinishProcedure:)
 
 You will (eventually) receive all 4 delegate callbacks for a Procedure (assuming it finishes).
 
 The `context` parameter provided to the will/didAdd delegate callbacks is the same `context`
 parameter that was passed into the call to `ProcedureQueue.add(operation:context:)`.
 
 For both adding and finishing, the "will" delegate will be called before the respective "did" delegate
 method. However, you should be aware of the following additional guidelines:
 
    - `willAddOperation` / `willAddProcedure` is always guaranteed to be called before any other delegate
      methods for an Operation / Procedure instance
    - `willFinishProcedure` is always guaranteed to be called before `didFinishProcedure` for a
      Procedure instance
    - No other ordering (or non-concurrency) is guaranteed
 
 Delegate callbacks may occur concurrently and on any thread.
 
 Examples:
    - It is possible for `didAddOperation` / `didAddProcedure` to be called concurrently with
    `didFinishOperation` / `will/didFinishProcedure` for an Operation / Procedure instance.
    - It is possible for `didAddOperation` to be called concurrently for two different Operation
    instances added to a ProcedureQueue simultaneously. (i.e. Once for each Operation.)
 
 */
public protocol ProcedureQueueDelegate: class {

    // MARK: - Operations

    /**
     The procedure queue will add a new operation. This is for information only, the
     delegate cannot affect whether the operation is added, or other control flow.

     - parameter queue: the `ProcedureQueue`.
     - parameter operation: the `Operation` instance about to be added.
     - parameter context: the context, if any, passed into the call to ProcedureQueue.add(operation:context:) that triggered the delegate callback
     - returns: (optional) a `ProcedureFuture` (signaled when handling of the delegate callback is complete), or nil (if there is no need for the `ProcedureQueue` to wait to add the operation)
     */
    func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation, context: Any?) -> ProcedureFuture?

    /**
     The procedure queue did add a new operation. This is for information only.

     - parameter queue: the `ProcedureQueue`.
     - parameter operation: the `Operation` instance which was added.
     - parameter context: the context, if any, passed into the call to ProcedureQueue.add(operation:context:) that triggered the delegate callback
     */
    func procedureQueue(_ queue: ProcedureQueue, didAddOperation operation: Operation, context: Any?)

    /**
     An operation has finished on the queue.

     - parameter queue: the `ProcedureQueue`.
     - parameter operation: the `Operation` instance which finished.
     - parameter errors: an array of `Error`s.
     */
    func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation)

    // MARK: - Procedures

    /**
     The procedure queue will add a new Procedure. This is for information only, the
     delegate cannot affect whether the Procedure is added, or other control flow.
     
     - parameter queue: the `ProcedureQueue`.
     - parameter procedure: the `Procedure` instance about to be added.
     - parameter context: the context, if any, passed into the call to ProcedureQueue.add(operation:context:) that triggered the delegate callback
     - returns: (optional) a `ProcedureFuture` (signaled when handling of the delegate callback is complete), or nil (if there is no need for the `ProcedureQueue` to wait to add the operation)
     */
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture?

    /**
     The procedure queue did add a new Procedure. This is for information only.
     
     - parameter queue: the `ProcedureQueue`.
     - parameter procedure: the `Procedure` instance which was added.
     - parameter context: the context, if any, passed into the call to ProcedureQueue.add(operation:context:) that triggered the delegate callback
     */
    func procedureQueue(_ queue: ProcedureQueue, didAddProcedure procedure: Procedure, context: Any?)

    /**
     A Procedure will finish on the queue.
     
     - parameter queue: the `ProcedureQueue`.
     - parameter procedure: the `Procedure` instance which finished.
     - parameter errors: an array of `Error`s.
     - returns: (optional) a `ProcedureFuture` (signaled when handling of the delegate callback is complete), or nil (if there is no need for the `ProcedureQueue` to temporarily block the Procedure from finishing)
     */
    func procedureQueue(_ queue: ProcedureQueue, willFinishProcedure procedure: Procedure, with error: Error?) -> ProcedureFuture?

    /**
     A Procedure has finished on the queue.
     
     - parameter queue: the `ProcedureQueue`.
     - parameter procedure: the `Procedure` instance which finished.
     - parameter errors: an array of `Error`s.
     */
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, with error: Error?)
}

public extension ProcedureQueueDelegate {

    // Operations

    /// Default - do nothing.
    func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation, context: Any?) -> ProcedureFuture? { /* default no-op */ return nil }

    /// Default - do nothing.
    func procedureQueue(_ queue: ProcedureQueue, didAddOperation operation: Operation, context: Any?) { /* default no-op */ }

    /// Default - do nothing.
    func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation) { /* default no-op */ }

    // Procedures

    /// Default - do nothing.
    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? { /* default no-op */ return nil }

    /// Default - do nothing.
    func procedureQueue(_ queue: ProcedureQueue, didAddProcedure procedure: Procedure, context: Any?) { /* default no-op */ }

    /// Default - do nothing.
    func procedureQueue(_ queue: ProcedureQueue, willFinishProcedure procedure: Procedure, with error: Error?) -> ProcedureFuture? { /* default no-op */ return nil }

    /// Default - do nothing.
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, with error: Error?) { /* default no-op */ }
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

    fileprivate let dispatchQueue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.ProcedureQueue"/*, qos: DispatchQoS.userInteractive*/, attributes: [.concurrent])

    // Events that are queued until the ProcedureQueue is un-suspended
    fileprivate var queuedConditionEvaluators: [Procedure.EvaluateConditions] = [] // must be accessed within the suspendLock
    fileprivate var queuedProcedureLockRequests: [ExclusivityLockRequest] = [] // must be accessed within the suspendLock
    fileprivate var unclaimedExclusivityLockTickets = Set<ExclusivityLockTicket>() // must be accessed within the suspendLock
    fileprivate let suspendLock = PThreadMutex()

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
    open weak var delegate: ProcedureQueueDelegate?

    /**
     Adds the operation to the queue. Subclasses which override this method must call this
     implementation as it is critical to how ProcedureKit functions.

     - parameter op: an `Operation` instance.
     - parameter context: an optional parameter that is passed-through to the Will/DidAdd delegate callbacks
     - returns: a `ProcedureFuture` that is signaled once the operation has been added to the `ProcedureQueue`
     */
    @discardableResult open func addOperation(_ operation: Operation, withContext context: Any? = nil) -> ProcedureFuture {

        let promise = ProcedurePromise()

        // Execute the first internal implementation function on the current thread.
        // This will ensure that willAddOperation/Procedure delegate callbacks are called
        // prior to returning.
        //
        // If those delegate callbacks return a future, additional steps may be executed 
        // asynchronously on the ProcedureQueue's internal DispatchQueue.
        //
        // Thus, when this function returns:
        //  - it is guaranteed that the `willAddOperation` / `willAddProcedure` delegate callbacks
        //    have been called
        //  - the operation may not have been added to the queue yet, but *will* be (if not)
        //
        _addOperation(operation, withContext: context, promise: promise)

        return promise.future
    }

    /**
     Adds the operations to the queue.

     - parameter ops: an array of `NSOperation` instances.
     - parameter wait: a Bool flag which is ignored.

     - IMPORTANT:
       Unlike `Foundation.OperationQueue`, `ProcedureQueue` ignores the
       `waitUntilFinished` parameter.
     */
    open override func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        ops.forEach { addOperation($0) }
    }

    /// Overrides and wraps the Swift 3 interface
    open override func addOperation(_ operation: Operation) {
        addOperation(operation, withContext: nil)
    }

    /**
     Override of OperationQueue's `isSuspended`. Functions the same (with some additional support for
     ProcedureKit internal functionality).
     */
    open override var isSuspended: Bool {
        get { return super.isSuspended }
        set (newIsSuspended) {
            suspendLock.withCriticalScope {
                guard newIsSuspended != super.isSuspended else { return } // nothing changed
                super.isSuspended = newIsSuspended
                if !newIsSuspended {
                    // When resuming a ProcedureQueue:
                    // 1.) Process all queuedProcedureLockRequests
                    for lockRequest in queuedProcedureLockRequests {
                        _requestLockAsync(for: lockRequest.mutuallyExclusiveCategories, completion: lockRequest.completion)
                    }
                    queuedProcedureLockRequests.removeAll()
                    // 2.) Process all queued condition evaluators
                    for conditionEvaluator in queuedConditionEvaluators {
                        conditionEvaluator.queue.async {
                            conditionEvaluator.start()
                        }
                    }
                    queuedConditionEvaluators.removeAll()
                }
                else {
                    // When suspending a ProcedureQueue:
                    // 1.) Invalidate all unclaimedExclusivityLockTickets (releasing the locks)
                    for ticket in unclaimedExclusivityLockTickets {
                        ExclusivityManager.sharedInstance.unlock(categories: ticket.mutuallyExclusiveCategories)
                    }
                    unclaimedExclusivityLockTickets.removeAll()
                }
            }
        }
    }

    // MARK: - Private Implementation

    private func _addOperation(_ operation: Operation, withContext context: Any?, promise: ProcedurePromise) {

        // Stage 1: Add observers / completion block,
        //          willEnqueue(on: self)
        //          Call async WillAdd delegate method, .then(onQueue: )

        guard let procedure = operation as? Procedure else {

            // Operation (non-Procedure) subclasses are handled differently:
            //  - They receive the following delegate callbacks: 
            //      willAddOperation, didAddOperation, didFinishOperation
            //    (There is no willFinishOperation callback fired for non-Procedure Operation subclasses,
            //    and no error information is automatically available when finished.)

            // Add a completion block to invoke the did finish delegate method
            operation.addCompletionBlock { [weak self, weak operation] in
                if let queue = self, let operation = operation {
                    queue.delegate?.procedureQueue(queue, didFinishOperation: operation)
                }
            }

            if let delegate = delegate {

                // WillAddOperation delegate
                (delegate.procedureQueue(self, willAddOperation: operation, context: context) ?? _SyncAlreadyAvailableFuture()).then(on: dispatchQueue) {

                    super.addOperation(operation)

                    delegate.procedureQueue(self, didAddOperation: operation, context: context)

                    promise.complete()
                }
            }
            else {
                super.addOperation(operation)

                promise.complete()
            }

            return
        }

        // Procedure subclass

        procedure.log.verbose.message("Adding to queue")

        /// Add an observer to invoke the will finish delegate method
        procedure.addWillFinishBlockObserver { [weak self] procedure, error, pendingFinish in
            if let queue = self {
                queue.delegate?.procedureQueue(queue, willFinishProcedure: procedure, with: error)?.then(on: queue.dispatchQueue) {
                    // ensure that the observed procedure does not finish prior to the
                    // willFinishProcedure delegate completing
                    pendingFinish.doThisBeforeEvent()
                }
            }
        }

        /// Add an observer to invoke the did finish delegate method
        procedure.addDidFinishBlockObserver { [weak self] procedure, error in
            if let queue = self {
                queue.delegate?.procedureQueue(queue, didFinishProcedure: procedure, with: error)
            }
        }

        // Indicate to the operation that it is to be enqueued
        procedure.willEnqueue(on: self)

        if let delegate = delegate {

            // WillAddProcedure delegate
            (delegate.procedureQueue(self, willAddProcedure: procedure, context: context) ?? _SyncAlreadyAvailableFuture()).then(on: dispatchQueue) {

                // Step 2:
                self._add_step2(procedure: procedure, context: context, promise: promise)
            }
        }
        else {

            // if no delegate, proceed to Step 2 directly:
            _add_step2(procedure: procedure, context: context, promise: promise)
        }
    }

    // Step 2: pendingQueueStart()
    //         super.addOperation()
    //         Call async DidAdd delegate method, .then(onQueue: )
    //
    private func _add_step2(procedure: Procedure, context: Any?, promise: ProcedurePromise) {

        // Indicate to the Procedure that it will be added to the queue
        // and is waiting for the queue to start it
        procedure.pendingQueueStart()

        super.addOperation(procedure)

        procedure.postQueueAdd()

        // DidAddProcedure delegate
        delegate?.procedureQueue(self, didAddProcedure: procedure, context: context)

        promise.complete()
    }

    // MARK: Mutual Exclusivity

    fileprivate struct ExclusivityLockRequest {
        let mutuallyExclusiveCategories: Set<String>
        let completion: (ExclusivityLockTicket) -> Void
    }

    internal class ExclusivityLockTicket: Hashable {
        let mutuallyExclusiveCategories: Set<String>
        fileprivate init(mutuallyExclusiveCategories: Set<String>)
        {
            self.mutuallyExclusiveCategories = mutuallyExclusiveCategories
        }
        static func ==(lhs: ExclusivityLockTicket, rhs: ExclusivityLockTicket) -> Bool {
            return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self).hashValue)
        }
    }

    /// Requests a Mutual Exclusivity lock for a set of categories, taking into account
    /// the ProcedureQueue's `isSuspended` status.
    ///
    /// If the ProcedureQueue is suspended, the request is queued until the ProcedureQueue is resumed.
    /// If the ProcedureQueue is running, the lock request is processed (asynchronously).
    ///
    /// Once the lock request is granted (asynchronously), this function again checks whether the
    /// ProcedureQueue is suspended. If it is, the lock is immediately released and a future attempt
    /// is queued for when the ProcedureQueue is resumed.
    ///
    /// The completion block is provided an `ExclusivityLockTicket`. Once the Procedure has started,
    /// it *must* internally call ProcedureQueue's `procedureClaimLock(withTicket:completion:)`
    /// to officially "claim" the lock to ensure that Mutual Exclusivity is, in fact, enforced.
    /// (This mechanic allows the ProcedureQueue to safely handle various tricky situations
    /// caused by the asynchronous nature of suspending vs. when/how Foundation.Operation
    /// internally decides to start Operations on the queue.)
    ///
    /// - Parameters:
    ///   - mutuallyExclusiveCategories: a Set of mutually exclusive categories (Strings)
    ///   - completion: a block called once a ExclusivityLockTicket has been granted by the ProcedureQueue
    internal func requestLock(for mutuallyExclusiveCategories: Set<String>, completion: @escaping (ExclusivityLockTicket) -> Void) {

        assert(!mutuallyExclusiveCategories.isEmpty, "requestLock called with an empty set of categories")

        let proceed: Bool = suspendLock.withCriticalScope {
            guard !super.isSuspended else {
                // The ProcedureQueue is currently suspended
                // Queue a future lock request attempt (once the queue is resumed)
                queuedProcedureLockRequests.append(
                    ExclusivityLockRequest(mutuallyExclusiveCategories: mutuallyExclusiveCategories, completion: completion)
                )
                return false
            }
            return true
        }
        guard proceed else { return }

        _requestLockAsync(for: mutuallyExclusiveCategories, completion: completion)
    }

    fileprivate func _requestLockAsync(for mutuallyExclusiveCategories: Set<String>, completion: @escaping (ExclusivityLockTicket) -> Void) {

        assert(!mutuallyExclusiveCategories.isEmpty, "requestLock called with an empty set of categories")

        // Request a lock from the ExclusivityManager.
        ExclusivityManager.sharedInstance.requestLock(for: mutuallyExclusiveCategories) {
            // Once the lock is acquired
            let optionalTicket: ExclusivityLockTicket? = self.suspendLock.withCriticalScope {
                guard !super.isSuspended else {
                    // If by the time the lock request is granted the Procedure is suspended,
                    // immediately release the lock and queue a future lock request attempt
                    // (once the ProcedureQueue is resumed)
                    ExclusivityManager.sharedInstance.unlock(categories: mutuallyExclusiveCategories)
                    self.queuedProcedureLockRequests.append(
                        ExclusivityLockRequest(mutuallyExclusiveCategories: mutuallyExclusiveCategories, completion: completion)
                    )
                    return nil
                }
                // If by the time the lock request succeeds the ProcedureQueue is not suspended,
                // return an ExclusivityLockTicket (which is recorded within the ProcedureQueue)
                let ticket = ExclusivityLockTicket(mutuallyExclusiveCategories: mutuallyExclusiveCategories)
                self.unclaimedExclusivityLockTickets.insert(ticket)
                return ticket
            }

            guard let ticket = optionalTicket else { return }
            completion(ticket)
        }
    }

    /// Called by a Procedure, *once the ProcedureQueue has started the Procedure*,
    /// to claim an outstanding Exclusivity Lock
    ///
    /// If the ProcedureQueue has released the lock in the interim (for example, if
    /// it was suspended), this function issues a new lock request on behalf of
    /// the Procedure.
    internal func procedureClaimLock(withTicket ticket: ExclusivityLockTicket, completion: @escaping () -> Void) {
        let claimedLock: Bool = suspendLock.withCriticalScope {
            guard unclaimedExclusivityLockTickets.remove(ticket) != nil else {
                //
                // The ticket is no longer valid (likely because the ProcedureQueue was suspended
                // and released the exclusivity lock in the interim)
                //
                // Initiate a new async lock request on behalf of the Procedure
                //
                // NOTE: Since the Procedure has *already been started* by the ProcedureQueue,
                // there is no point in trying to delay its execution further if the
                // ProcedureQueue is now suspended.
                //
                // Foundation.OperationQueue already only guarantees that:
                //   "Setting [isSuspended] to true prevents the queue from starting any queued
                //    operations, but already executing operations continue to execute."
                // https://developer.apple.com/documentation/foundation/operationqueue/1415909-issuspended
                //
                // Therefore, instead of calling the *ProcedureQueue's* `requestLock` function,
                // (which *would* delay requesting a lock if the ProcedureQueue is suspended),
                // we use the ExclusivityManager directly here.
                //

                ExclusivityManager.sharedInstance.requestLock(for: ticket.mutuallyExclusiveCategories, completion: completion)
                return false
            }
            return true
        }
        guard claimedLock else { return }

        // Lock was successfully claimed - call the completion block
        completion()
    }

    internal func unlock(mutuallyExclusiveCategories categories: Set<String>) {
        ExclusivityManager.sharedInstance.unlock(categories: categories)
    }

    // MARK: Condition Evaluation

    // When a Procedure's EvaluateConditions Operation is ready to begin (i.e. when all dependencies
    // have finished), it calls requestEvaluation(of: self) to ask the ProcedureQueue associated
    // with its Procedure to begin its evaluation.
    //
    // If the ProcedureQueue is suspended, it queues the request until it the queue is un-suspended.
    // If the ProcedureQueue is running, the condition evaluation is started (asynchronously).
    internal func requestEvaluation(of conditionEvaluator: Procedure.EvaluateConditions) {
        let dispatchEvaluator: Bool = suspendLock.withCriticalScope {
            guard !super.isSuspended else {
                // The ProcedureQueue is currently suspended
                // Queue a future dispatch of the condition evaluator (once the queue is resumed)
                queuedConditionEvaluators.append(conditionEvaluator)
                return false
            }
            return true
        }
        guard dispatchEvaluator else { return }

        // Since the ProcedureQueue wasn't suspended, dispatch condition evaluation
        conditionEvaluator.queue.async {
            conditionEvaluator.start()
        }
    }
}

public extension ProcedureQueue {
    /**
     Add operations to the queue as an array
     
     - parameter operations: a sequence of `Operation` instances.
     - parameter context: an optional parameter that is passed-through to the Will/DidAdd delegate callbacks
     - returns: a `ProcedureFuture` that is signaled once the operations have been added to the `ProcedureQueue`
     */
    @discardableResult final func addOperations<S: Sequence>(_ operations: S, withContext context: Any? = nil) -> ProcedureFuture where S.Iterator.Element: Operation {

        let futures = operations.map {
            addOperation($0, withContext: context)
        }

        return futures.future
    }

    /**
     Add operations to the queue as a variadic parameter

     - parameter operations: a variadic array of `Operation` instances.
     - parameter context: an optional parameter that is passed-through to the Will/DidAdd delegate callbacks
     - returns: a `ProcedureFuture` that is signaled once the operations have been added to the `ProcedureQueue`
     */
    @discardableResult final func addOperations(_ operations: Operation..., withContext context: Any? = nil) -> ProcedureFuture {
        return addOperations(operations, withContext: context)
    }
}

/// Public extensions on OperationQueue
public extension OperationQueue {

    /**
     Add operations to the queue as an array
     - parameter operations: a array of `Operation` instances.
     */
    final func addOperations<S>(_ operations: S) where S: Sequence, S.Iterator.Element: Operation {
        addOperations(Array(operations), waitUntilFinished: false)
    }

    /**
     Add operations to the queue as a variadic parameter
     - parameter operations: a variadic array of `Operation` instances.
     */
    final func addOperations(_ operations: Operation...) {
        addOperations(operations)
    }
}

/// A ProcedureFuture that is used internally to shortcut dispatching async when no waiting is required.
fileprivate class _SyncAlreadyAvailableFuture: ProcedureFuture {
    internal init() { }

    deinit {
        group.leave()
    }

    public override func then(on eventQueueProvider: QueueProvider, block: @escaping () -> Void) {
        block()
    }
}

// MARK: - Unavilable & Renamed

@available(*, unavailable, renamed: "ProcedureQueueDelegate")
public protocol OperationQueueDelegate: class { }

public extension ProcedureQueue {

    @available(*, deprecated, renamed: "addOperation(_:withContext:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    @discardableResult func add(operation: Operation, withContext context: Any? = nil) -> ProcedureFuture {
        return addOperation(operation, withContext: context)
    }

    @available(*, deprecated, renamed: "addOperations(_:withContext:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    @discardableResult final func add<S: Sequence>(operations: S, withContext context: Any? = nil) -> ProcedureFuture where S.Iterator.Element: Operation {
        return addOperations(operations, withContext: context)
    }

    @available(*, deprecated, renamed: "addOperations(_:withContext:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add(operations: Operation..., withContext context: Any? = nil) -> ProcedureFuture {
        return addOperations(operations, withContext: context)
    }
}

public extension OperationQueue {

    @available(*, deprecated, renamed: "addOperations(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add<S>(operations: S) where S: Sequence, S.Iterator.Element: Operation {
        addOperations(operations)
    }

    @available(*, deprecated, renamed: "addOperations(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add(operations: Operation...) {
        addOperations(operations)
    }
}
