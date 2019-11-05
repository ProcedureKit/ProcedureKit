//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

// MARK: - ProcedurePromise & ProcedureFuture

/**
 A `ProcedurePromise` provides a `ProcedureFuture` that is signaled when the promise is completed.
 
 Create a `ProcedurePromise` and retrieve the future from the promise:
 
 ```swift
 let promise = ProcedurePromise()
 let future = promise.future // retrieve the future from the promise
 ```
 
 then after your asynchronous task is complete, complete the promise like so:
 
 ```swift
 promise.complete()
 ```
 
 and anything scheduled using the `ProcedureFuture` will occur after the promise has been completed.
 
 A simple example is:
 
 ```swift
 func myAsyncFunction() -> ProcedureFuture {
     let promise = ProcedurePromise()
     // dispatch an asynchronous task
     DispatchQueue.global().async {
         // do something
         // then complete the promise when done
         promise.complete()
     }
     return promise.future
 }
 
 myAsyncFunction().then(on: DispatchQueue.global()) {
    // execute this block after myAsyncFunction's promise completes, on DispatchQueue.global()
 }
 ```
 
 A `ProcedurePromise` / `ProcedureFuture` does not return a value - it merely allows you to execute
 a block when a promise is complete.
 
 To return a future value, use `ProcedurePromiseResult` (and `ProcedureFutureResult`).
 */
public class ProcedurePromise {

    /// The `ProcedureFuture` associated with the Promise.
    public let future = ProcedureFuture()
    #if DEBUG
    private var _didComplete = false
    private var lock = PThreadMutex()
    #endif

    #if DEBUG
    // In Debug builds, verify and fail if a promise is not completed before it is deinited
    // (this slightly impacts performance)
    deinit {
        let didComplete = lock.withCriticalScope { _didComplete }
        guard didComplete else {
            fatalError("Did not complete ProcedurePromise (\(self)) before deinit. All promises must eventually be completed.")
        }
    }
    #endif

    /// Complete the ProcedurePromise, signaling the future to dispatch any waiting blocks
    ///
    /// - IMPORTANT: Only call `complete()` **once** on a ProcedurePromise.
    func complete() {
        #if DEBUG
        lock.withCriticalScope {
            assert(!_didComplete, "Called complete() more than once on a ProcedurePromise.")
            _didComplete = true
        }
        #endif
        future.complete()
    }
}

/**
 A `ProcedureFuture` can be used to schedule a following block of code after it is signaled (in the future).
 
 You cannot create a `ProcedureFuture` directly. Instead, create a `ProcedurePromise` and retrieve the future
 from the promise:
 
 ```swift
 let promise = ProcedurePromise()
 let future = promise.future // retrieve the future from the promise
 ```
 
 then after your asynchronous task is complete, complete the promise like so:
 
 ```swift
 promise.complete()
 ```
 
 and anything scheduled using the `ProcedureFuture` will occur after the promise has been completed.

 A simple example is:
 
 ```swift
 func myAsyncFunction() -> ProcedureFuture {
    let promise = ProcedurePromise()
    // dispatch an asynchronous task
    DispatchQueue.global().async {
        // do something
        // then complete the promise when done
        promise.complete()
    }
    return promise.future
 }
 
 myAsyncFunction().then(on: DispatchQueue.global()) {
    // execute this block after myAsyncFunction's promise completes, on DispatchQueue.global()
 }
 ```
 
 A `ProcedureFuture` / `ProcedurePromise` does not return a value - it merely allows you to execute
 a block when a promise is complete.
 
 To return a future value, use `ProcedurePromiseResult` (and `ProcedureFutureResult`).
*/
public class ProcedureFuture {
    internal let group: DispatchGroup

    internal init(group: DispatchGroup = DispatchGroup()) {
        self.group = group
        group.enter()
    }

    /// Schedules a block for execution after the ProcedureFuture completes.
    ///
    /// - Parameters:
    ///   - on: a queue [DispatchQueue, EventQueue, Procedure (which schedules it on its internal event queue)]
    ///   - block: The block to be scheduled after the ProcedureFuture completes.
    public func then(on eventQueueProvider: QueueProvider, block: @escaping () -> Void) {

        let eventQueue = eventQueueProvider.providedQueue
        eventQueue.dispatchNotify(withGroup: group, block: block)
    }
}

// Used by ProcedurePromise
fileprivate extension ProcedureFuture {

    func complete() {
        group.leave()
    }
}

// Used by ProcedureFutureGroup
fileprivate extension ProcedureFuture {
    // If the future is immediately available, execute the block synchronously on the current thread
    // otherwise, queue a future dispatch onto the QueueProvider's queue.
    @discardableResult
    func thenOnSelfOrLater(on eventQueueProvider: QueueProvider, block: @escaping () -> Void) -> ProcedureFuture {
        let promise = ProcedurePromise()
        let eventQueue = eventQueueProvider.providedQueue
        if group.wait(timeout: .now()) == .success {
            // future is immediately available, execute the block synchronously on the current thread
            block()
            promise.complete()
        }
        else {
            // future is not immediately available, so queue an asynchrous dispatch when it is on the
            // provided queue
            eventQueue.dispatchNotify(withGroup: group) {
                block()
                promise.complete()
            }
        }
        return promise.future
    }
}

extension Collection where Iterator.Element: ProcedureFuture {

    /// Retrieve a future for a collection of ProcedureFutures that is signaled once
    /// all the futures in the collection are signaled.
    ///
    /// ```swift
    /// let futures: [ProcedureFuture] = ... // multiple ProcedureFutures
    /// futures.future.then(on: DispatchQueue.global()) {
    ///     // execute this block when all the futures have completed
    /// }
    /// ```
    ///
    /// - returns: a ProcedureFuture that is signaled once all ProcedureFutures in the collection are signaled
    var future: ProcedureFuture {
        let future = ProcedureFuture()
        let group = DispatchGroup()
        self.forEach {
            group.enter()
            $0.thenOnSelfOrLater(on: DispatchQueue.global()) {
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.global()) {
            future.complete()
        }
        return future
    }
}

// MARK: - ProcedurePromiseResult

/**
 A `ProcedurePromiseResult<T>`, is much like a `ProcedurePromise`, except it returns a
 `ProcedureFutureResult<T>` that provides a `ProcedureResult<T>` when the promise is completed.

 Create a `ProcedurePromiseResult` and retrieve the future from the promise:
 
 ```swift
 let promise = ProcedurePromiseResult<Bool>()
 let future = promise.future // retrieve the future from the promise
 ```
 
 then after your asynchronous task is complete, complete the promise like so:
 
 ```swift
 promise.complete(withResult: true)
 ```
 
 and anything scheduled using the `ProcedureFutureResult` will occur after the promise has been completed.
 
 A simple example is:
 
 ```swift
 func myAsyncFunction() -> ProcedureFutureResult<Bool> {
     let promise = ProcedurePromiseResult<Bool>()
     // dispatch an asynchronous task
     DispatchQueue.global().async {
         // do something that returns a result
         let result = true
         // then complete the promise when done
         promise.complete(withResult: result)
     }
     return promise.future
 }
 
 myAsyncFunction().then(on: DispatchQueue.global()) { result in
     // execute this block after myAsyncFunction's promise completes, on DispatchQueue.global()
     // the result of the promise is passed-in to the block as a ProcedureResult<T>
     guard let value = result.value else {
        // error
        print("The result is error: \(result.error)")
     }
     print("The result is: \(value)")
 }
 ```

 If you do not need to return a value, use `ProcedurePromise` (and `ProcedureFuture`) instead.
 */
public class ProcedurePromiseResult<T> {

    /// The `ProcedureFutureResult` associated with the Promise.
    public let future = ProcedureFutureResult<T>()

    deinit {
        assert(future.hasResult, "Did not complete ProcedureResultPromise (\(self)) before deinit. All promises must eventually be completed.")
        guard future.hasResult else {
            future.complete(withFailure: ProcedureKitError.UnfulfilledPromise())
            return
        }
    }

    /// Complete the `ProcedurePromiseResult` with a result of type T, signaling the
    /// future to dispatch any waiting blocks.
    ///
    /// The blocks will receive a `ProcedureResult<T>.success(result)`.
    /// - See: `ProcedureResult`
    ///
    /// - IMPORTANT: Only call `complete` **once** on a ProcedurePromiseResult.
    func complete(withResult success: T) {
        future.complete(withResult: success)
    }

    /// Complete the `ProcedurePromiseResult` with a failure Error, signaling the
    /// future to dispatch any waiting blocks
    ///
    /// The blocks will receive a `ProcedureResult<T>.failure(error)`.
    /// - See: `ProcedureResult`
    ///
    /// - IMPORTANT: Only call `complete` **once** on a ProcedurePromiseResult.
    func complete(withFailure failure: Error) {
        future.complete(withFailure: failure)
    }
}

public class ProcedureFutureResult<Result> {
    private var _result = Pending<ProcedureResult<Result>>(nil)
    private var group = DispatchGroup()
    private var resultLock = PThreadMutex()
    private var result: Pending<ProcedureResult<Result>> {
        get { return resultLock.withCriticalScope { _result } }
        set {
            resultLock.withCriticalScope {
                _result = newValue
            }
        }
    }

    fileprivate init() {
        group.enter()
    }

    public func then(on eventQueueProvider: QueueProvider, block: @escaping (ProcedureResult<Result>) -> Void) {

        let eventQueue = eventQueueProvider.providedQueue
        eventQueue.dispatchNotify(withGroup: group) {
            guard let value = self.result.value else { fatalError("Notify triggered before result is available.") }
            block(value)
        }
    }

    // MARK: - Private Implementation used by ProcedurePromiseResult

    fileprivate func complete(withResult value: Result) {
        setResult(.success(value))
    }

    fileprivate func complete(withFailure error: Error) {
        setResult(.failure(error))
    }

    private func setResult(_ result: ProcedureResult<Result>) {
        let setResult = resultLock.withCriticalScope { () -> Bool in
            guard _result.isPending else {
                assertionFailure("Cannot set the result of a ProcedureFuture more than once.")
                return false
            }
            _result = .ready(result)
            return true
        }
        guard setResult else { return }
        group.leave()
    }

    fileprivate var hasResult: Bool {
        return resultLock.withCriticalScope { !_result.isPending }
    }
}

public extension ProcedureKitError {

    struct UnfulfilledPromise: Error {
        internal init() { }
    }
}
