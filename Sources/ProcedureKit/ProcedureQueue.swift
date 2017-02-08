//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
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
     - returns: (optional) a ProcedureFuture (signaled when handling of the delegate callback is complete), or nil (if there is no need for the ProcedureQueue to wait to add the operation)
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
     - returns: (optional) a ProcedureFuture (signaled when handling of the delegate callback is complete), or nil (if there is no need for the ProcedureQueue to wait to add the operation)
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
     - returns: (optional) a ProcedureFuture (signaled when handling of the delegate callback is complete), or nil (if there is no need for the ProcedureQueue to temporarily block the Procedure from finishing)
     */
    func procedureQueue(_ queue: ProcedureQueue, willFinishProcedure procedure: Procedure, withErrors errors: [Error]) -> ProcedureFuture?

    /**
     A Procedure has finished on the queue.
     
     - parameter queue: the `ProcedureQueue`.
     - parameter procedure: the `Procedure` instance which finished.
     - parameter errors: an array of `Error`s.
     */
    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error])
}

public extension ProcedureQueueDelegate {

    // Operations

    func procedureQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation, context: Any?) -> ProcedureFuture? { /* default no-op */ return nil }

    func procedureQueue(_ queue: ProcedureQueue, didAddOperation operation: Operation, context: Any?) { /* default no-op */ }

    func procedureQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation) { /* default no-op */ }

    // Procedures

    func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? { /* default no-op */ return nil }

    func procedureQueue(_ queue: ProcedureQueue, didAddProcedure procedure: Procedure, context: Any?) { /* default no-op */ }

    func procedureQueue(_ queue: ProcedureQueue, willFinishProcedure procedure: Procedure, withErrors errors: [Error]) -> ProcedureFuture? { /* default no-op */ return nil }

    func procedureQueue(_ queue: ProcedureQueue, didFinishProcedure procedure: Procedure, withErrors errors: [Error]) { /* default no-op */ }
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

    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    /**
     Adds the operation to the queue. Subclasses which override this method must call this
     implementation as it is critical to how ProcedureKit function.

     - parameter op: an `Operation` instance.
     - parameter context: an optional parameter that is passed-through to the Will/DidAdd delegate callbacks
     - returns: a ProcedureFuture that is signaled once the operation has been added to the ProcedureQueue
     */
    @discardableResult open func add(operation: Operation, withContext context: Any? = nil) -> ProcedureFuture {

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
        _add(operation: operation, context: context, promise: promise)

        return promise.future
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length

    /**
     Adds the operations to the queue.

     - parameter ops: an array of `NSOperation` instances.
     - parameter wait: a Bool flag which is ignored.
     */
    open override func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        ops.forEach { addOperation($0) }
    }

    /// Overrides and wraps the Swift 3 interface
    open override func addOperation(_ operation: Operation) {
        add(operation: operation)
    }

    // MARK: - Private Implementation

    private func _add(operation: Operation, context: Any?, promise: ProcedurePromise) {

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
                (delegate.procedureQueue(self, willAddOperation: operation, context: context) ?? _SyncAlreadyAvailableFuture()).then(on: dispatchQueue) { _ in

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

        procedure.log.verbose(message: "Adding to queue")

        /// Add an observer to invoke the will finish delegate method
        procedure.addWillFinishBlockObserver { [weak self] procedure, errors, pendingFinish in
            if let queue = self {
                queue.delegate?.procedureQueue(queue, willFinishProcedure: procedure, withErrors: errors)?.then(on: queue.dispatchQueue) {
                    // ensure that the observed procedure does not finish prior to the
                    // willFinishProcedure delegate completing
                    pendingFinish.doThisBeforeEvent()
                }
            }
        }

        /// Add an observer to invoke the did finish delegate method
        procedure.addDidFinishBlockObserver { [weak self] procedure, errors in
            if let queue = self {
                queue.delegate?.procedureQueue(queue, didFinishProcedure: procedure, withErrors: errors)
            }
        }

        // Indicate to the operation that it is to be enqueued
        procedure.willEnqueue(on: self)

        if let delegate = delegate {

            // WillAddProcedure delegate
            (delegate.procedureQueue(self, willAddProcedure: procedure, context: context) ?? _SyncAlreadyAvailableFuture()).then(on: dispatchQueue) { _ in

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

        // DidAddProcedure delegate
        delegate?.procedureQueue(self, didAddProcedure: procedure, context: context)

        promise.complete()
    }
}

public extension ProcedureQueue {
    /**
     Add operations to the queue as an array
     
     - parameters operations: a sequence of `NSOperation` instances.
     - parameter context: an optional parameter that is passed-through to the Will/DidAdd delegate callbacks
     - returns: a ProcedureFuture that is signaled once the operations have been added to the ProcedureQueue
     */
    @discardableResult
    final func add<S: Sequence>(operations: S, withContext context: Any? = nil) -> ProcedureFuture where S.Iterator.Element: Operation {

        let futures = operations.map {
            add(operation: $0, withContext: context)
        }

        return futures.future
    }

    /**
     Add operations to the queue as a variadic parameter

     - parameters operations: a variadic array of `NSOperation` instances.
     - parameter context: an optional parameter that is passed-through to the Will/DidAdd delegate callbacks
     - returns: a ProcedureFuture that is signaled once the operations have been added to the ProcedureQueue
     */
    final func add(operations: Operation..., withContext context: Any? = nil) -> ProcedureFuture {
        return add(operations: operations, withContext: context)
    }
}

/// Public extensions on OperationQueue
public extension OperationQueue {

    /**
     Add operations to the queue as an array
     - parameters operations: a array of `NSOperation` instances.
     */
    final func add<S>(operations: S) where S: Sequence, S.Iterator.Element: Operation {
        addOperations(Array(operations), waitUntilFinished: false)
    }

    /**
     Add operations to the queue as a variadic parameter
     - parameters operations: a variadic array of `NSOperation` instances.
     */
    final func add(operations: Operation...) {
        add(operations: operations)
    }
}

/// A ProcedureFuture that is used internally to shortcut dispatching async when no waiting is required.
fileprivate class _SyncAlreadyAvailableFuture: ProcedureFuture {
    internal init() { }

    deinit {
        group.leave()
    }

    @discardableResult public override func then(on eventQueueProvider: QueueProvider, block: @escaping (Void) -> Void) {
        block()
    }
}

// MARK: - Unavilable & Renamed

@available(*, unavailable, renamed: "ProcedureQueueDelegate")
public protocol OperationQueueDelegate: class { }
