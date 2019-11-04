//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

// MARK: - EventQueue

/**
 An EventQueue is used to wrap some additional logic around a serial DispatchQueue for internal use in ProcedureKit.
 Blocks can be dispatched asynchronously onto an EventQueue, and are executed in a serial FIFO manner.
 
 (Only asynchronous dispatch methods are available.)
*/
public class EventQueue {
    fileprivate let queue: DispatchQueue
    #if DEBUG
    private let key: DispatchSpecificKey<UInt8>
    private let value: UInt8 = 1
    #endif
    fileprivate let eventQueueLock = PThreadMutex()
    internal var qualityOfService: DispatchQoS = .default // is updated by Procedure

    public init(label: String, qos: DispatchQoS = .default) {
        // The internal DispatchQueue is created as a serial queue with no specified QoS level
        // to permit the setting of any desired minimum QoS level for a block later.
        self.queue = DispatchQueue(label: label)
        self.qualityOfService = qos
        #if DEBUG
            key = DispatchSpecificKey()
            queue.setSpecific(key: key, value: value)
        #endif
    }

    internal func debugAssertIsOnQueue() {
        #if DEBUG
            assert(isOnQueue, "Not on expected EventQueue.")
        #endif
        // does nothing if not compiled in Debug mode
    }

    #if DEBUG
    internal var isOnQueue: Bool {
        guard let retrieved = DispatchQueue.getSpecific(key: key) else { return false }
        return value == retrieved
    }
    internal func debugBestowTemporaryEventQueueStatusOn(queue: DispatchQueueProtocol) {
        queue.pk_setSpecific(key: key, value: value)
    }
    internal func debugClearTemporaryEventQueueStatusFrom(queue: DispatchQueueProtocol) {
        queue.pk_setSpecific(key: key, value: nil)
    }
    #endif

    /// Asynchronously dispatches a block for execution on the EventQueue.
    ///
    /// - Parameters:
    ///   - block: a block to execute on the EventQueue
    public func dispatch(block: @escaping () -> Void) {
        dispatchEventBlockInternal(minimumQoS: nil, block: block)
    }

    /// Asynchronously dispatches a block for execution on the EventQueue as a DispatchWorkItem (which it returns).
    ///
    /// - Parameters:
    ///   - block: a block to execute on the EventQueue
    /// - Returns: the DispatchWorkItem that is scheduled for executing on the EventQueue
    public func dispatchAsWorkItem(block: @escaping () -> Void) -> DispatchWorkItem {
        return dispatchEventBlockInternal(minimumQoS: nil, block: block)
    }

    /// Schedules a block to be submitted to the EventQueue when a DispatchGroup has completed.
    ///
    /// - Parameters:
    ///   - group: the DispatchGroup which signals completion
    ///   - block: a block to execute on the EventQueue
    public func dispatchNotify(withGroup group: DispatchGroup, block: @escaping () -> Void) {
        group.notify(queue: queue, execute: {
            self.eventQueueLock.withCriticalScope {
                autoreleasepool {
                    block()
                }
            }
        })
    }
}

internal extension EventQueue {

    /// Asynchronously dispatches an event for execution on the Procedure's EventQueue
    /// (optionally specifying a minimumQoS level).
    ///
    /// If no minimumQoS level is specified, the qualityOfService level of the EventQueue
    /// itself will be used. (For custom-created EventQueues, this is the value assigned
    /// at init(). For Procedure.eventQueue, this value is updated when the
    /// Procedure.qualityOfService is updated.)
    ///
    /// - NOTE: Just because a block has a specified QoS level does not guarantee the block
    /// will execute with that exact QoS level. Promotional QoS and other factors can come
    /// into play and result in a higher QoS level.
    ///
    /// - Parameters:
    ///   - minimumQoS: a minimum QoS level for the submitted block
    ///   - block: a block to execute on the EventQueue
    @discardableResult
    func dispatchEventBlockInternal(minimumQoS: DispatchQoS? = nil, block: @escaping () -> Void) -> DispatchWorkItem {
        let resultingQoS = minimumQoS ?? qualityOfService

        let workItem = DispatchWorkItem(qos: resultingQoS, flags: [DispatchWorkItemFlags.enforceQoS]) {
            self.eventQueueLock.withCriticalScope {
                autoreleasepool {
                    block()
                }
            }
        }
        queue.async(execute: workItem)
        return workItem
    }

    func dispatchNotify(withGroup group: DispatchGroup, minimumQoS: DispatchQoS? = nil, block: @escaping () -> Void) {
        let resultingQoS = minimumQoS ?? qualityOfService

        group.notify(qos: resultingQoS, flags: [DispatchWorkItemFlags.enforceQoS], queue: queue, execute: {
            self.eventQueueLock.withCriticalScope {
                autoreleasepool {
                    block()
                }
            }
        })
    }

    /// - IMPORTANT: MUST be called when executing on the receiver EventQueue itself.
    ///
    /// Dispatches a block to be executed on another queue (EventQueue, DispatchQueue, etc)
    /// non-concurrently with the receiver (i.e. the current EventQueue). No further blocks
    /// from the receiver EventQueue will be executed until the block submitted to the otherQueue
    /// completes.
    ///
    /// If you call this method, you should return from the block that is executing on the receiver
    /// EventQueue as quickly as possible - the block scheduled on the otherQueue will only execute
    /// after the receiver EventQueue's block returns.
    ///
    /// Internally, this pauses the receiver EventQueue, to ensure that no threads are blocked waiting
    /// on the otherQueue to asynchronously handle the submitted block. After the otherQueue handles
    /// the submitted block, the receiver EventQueue is resumed.
    ///
    /// The block on the otherQueue is submitted with a QoS level promoted to at least the level of
    /// the calling thread. (Although never less than the QoS of the otherQueue itself.)
    ///
    /// - Parameters:
    ///   - otherQueue: another queue (EventQueue, DispatchQueue) onto which to asynchronously submit the block
    ///   - block: the block that is asynchronously submitted to the otherQueue
    func dispatchSynchronizedBlock(onOtherQueue otherQueue: DispatchQueueProtocol, block: @escaping () -> Void) {
        debugAssertIsOnQueue()
        assert(otherQueue !== self, "Cannot dispatch synchronized block onOtherQueue if otherQueue is self.")

        // acquire the QoS class of the current block on the receiver queue
        let originalQueueQoS = DispatchQoS(qosClass: DispatchQueue.currentQoSClass, relativePriority: 0)

        // suspend the current queue so no additional scheduled async blocks will be executed
        // after the calling code returns (preventing blocked threads)
        queue.suspend()

        // dispatch async to the other queue
        //
        // the original queue, since it is also synchronized with the block, will not schedule
        // any additional blocks to be executed after the current block returns (i.e. the block
        // that called dispatchSynchronizedBlock(onOtherQueue:))
        //
        // the caller should ideally return quickly after this function returns so that the current 
        // eventQueueLock is released and can be acquired in the otherQueue
        //
        otherQueue.asyncDispatch(minimumQoS: originalQueueQoS) { [originalQueue = self] in

            // on the other queue, aquire the event lock from the original queue
            // to ensure that all blocks on the original queue are done executing

            originalQueue.eventQueueLock.withCriticalScope {

                #if DEBUG
                    // For Debug purposes, treat the otherQueue at this point as if it were *also* the EventQueue
                    // (Since the actual EventQueue is paused and no longer executing blocks until this finishes.)
                    //
                    // This ensures that if the code inside the block calls `eventQueue.debugAssertIsOnQueue()`,
                    // it will (properly) succeed.
                    originalQueue.debugBestowTemporaryEventQueueStatusOn(queue: otherQueue)
                    assert(originalQueue.isOnQueue)
                #endif

                // This block should be synchronized with *both* queues
                block()

                #if DEBUG
                    originalQueue.debugClearTemporaryEventQueueStatusFrom(queue: otherQueue)
                    assert(!originalQueue.isOnQueue)
                #endif
            }

            // after the block is complete, resume the original queue
            originalQueue.queue.resume()
        }
    }
}

public extension EventQueue {
    func makeTimerSource(flags: DispatchSource.TimerFlags = []) -> DispatchSourceTimer {
        return DispatchSource.makeTimerSource(flags: flags, queue: queue)
    }
}

// MARK: - QueueProvider

/**
 A QueueProvider provides a queue conforming to DispatchQueueProtocol.
 
 Dispatch.DispatchQueue and ProcedureKit.EventQueue both provide themselves.
 ProcedureKit.Procedure provides its EventQueue.
 
 Several methods in ProcedureKit can take a QueueProvider. For example,
 ProcedureProtocol's `add*BlockObserver(synchronizedWith:block:)` methods take
 a QueueProvider for the `synchronizedWith` parameter. This can be a
 DispatchQueue, a ProcedureKit.EventQueue, or a Procedure.
 
 */
public protocol QueueProvider {
    var providedQueue: DispatchQueueProtocol { get }
}

extension DispatchQueue: QueueProvider {
    public var providedQueue: DispatchQueueProtocol { return self }
}

extension EventQueue: QueueProvider {
    public var providedQueue: DispatchQueueProtocol { return self }
}

extension Procedure: QueueProvider {
    public var providedQueue: DispatchQueueProtocol { return eventQueue }
}

// MARK: - DispatchQueueProtocol

public protocol DispatchQueueProtocol: class {
    @discardableResult func asyncDispatch(block: @escaping () -> Void) -> DispatchWorkItem
    @discardableResult func asyncDispatch(minimumQoS: DispatchQoS, block: @escaping () -> Void) -> DispatchWorkItem
    func dispatchNotify(withGroup group: DispatchGroup, block: @escaping () -> Void)
    #if DEBUG
    func pk_setSpecific<T>(key: DispatchSpecificKey<T>, value: T?)
    #endif
}

extension DispatchQueue: DispatchQueueProtocol {
    @discardableResult public func asyncDispatch(block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(block: block)
        self.async(execute: workItem)
        return workItem
    }
    @discardableResult public func asyncDispatch(minimumQoS: DispatchQoS, block: @escaping () -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem(qos: minimumQoS, flags: [DispatchWorkItemFlags.enforceQoS], block: block)
        self.async(execute: workItem)
        return workItem
    }
    public func dispatchNotify(withGroup group: DispatchGroup, block: @escaping () -> Void) {
        group.notify(queue: self, execute: block)
    }
    #if DEBUG
    public func pk_setSpecific<T>(key: DispatchSpecificKey<T>, value: T?) {
        #if swift(>=3.2)
            setSpecific(key: key, value: value)
        #else // Swift < 3.2 (Xcode 8.x)
            if let value = value {
                setSpecific(key: key, value: value)
            }
            else {
                pk_clearSpecific(key: key)
            }
        #endif
    }
    #endif
}

// Swift 3.x
fileprivate extension DispatchQueue {
    // Swift 3.x (Xcode 8.x) is missing the ability to clear specific keys from DispatchQueues
    // via DispatchQueue.setSpecific(key:value:) because it does not take an optional.
    //
    // A fix was merged into apple/swift in: https://github.com/apple/swift/commit/5accebf556f40ea104a7440ff0353f9e4f7f1ac2
    // And is available in Swift 4+.
    //
    // For compatibility with Xcode < 9 and Swift 3, this custom clearSpecific(key:)
    // function is provided.
    func pk_clearSpecific<T>(key: DispatchSpecificKey<T>) {
        let k = Unmanaged.passUnretained(key).toOpaque()
        __dispatch_queue_set_specific(self, k, nil, nil)
    }
}

extension EventQueue: DispatchQueueProtocol {
    @discardableResult public func asyncDispatch(block: @escaping () -> Void) -> DispatchWorkItem {
        return self.dispatchEventBlockInternal(block: block)
    }
    @discardableResult public func asyncDispatch(minimumQoS: DispatchQoS, block: @escaping () -> Void) -> DispatchWorkItem {
        let desiredQoS = max(minimumQoS, qualityOfService)
        return self.dispatchEventBlockInternal(minimumQoS: desiredQoS, block: block)
    }
    #if DEBUG
    public func pk_setSpecific<T>(key: DispatchSpecificKey<T>, value: T?) {
        queue.pk_setSpecific(key: key, value: value)
    }
    #endif
}
