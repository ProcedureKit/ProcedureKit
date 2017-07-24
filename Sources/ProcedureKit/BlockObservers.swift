//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public struct Observer<Procedure: ProcedureProtocol> {

    public typealias VoidBlock = (Procedure) -> Void
    public typealias ErrorsBlock = (Procedure, [Error]) -> Void
    public typealias ProducerBlock = (Procedure, Operation) -> Void

    public typealias DidAttach = VoidBlock
    public typealias WillExecute = (Procedure, PendingExecuteEvent) -> Void
    public typealias DidExecute = VoidBlock
    public typealias DidCancel = ErrorsBlock
    public typealias WillAdd = ProducerBlock
    public typealias DidAdd = ProducerBlock
    public typealias WillFinish = (Procedure, [Error], PendingFinishEvent) -> Void
    public typealias DidFinish = ErrorsBlock

    private init() { }
}

public struct BlockObserver<Procedure: ProcedureProtocol>: ProcedureObserver {

    /// - returns: the block which is called when the observer is attached to a procedure
    public let didAttach: Observer<Procedure>.DidAttach?

    /// - returns: the block which is called when the attached procedure will execute
    public let willExecute: Observer<Procedure>.WillExecute?

    /// - returns: the block which is called when the attached procedure did execute
    public let didExecute: Observer<Procedure>.DidExecute?

    /// - returns: the block which is called when the attached procedure did cancel
    public let didCancel: Observer<Procedure>.DidCancel?

    /// - returns: the block which is called when the attached procedure will add a new operation
    public let willAdd: Observer<Procedure>.WillAdd?

    /// - returns: the block which is called when the attached procedure did add a new operation
    public let didAdd: Observer<Procedure>.DidAdd?

    /// - returns: the block which is called when the attached procedure will finish
    public let willFinish: Observer<Procedure>.WillFinish?

    /// - returns: the block which is called when the attached procedure did finish
    public let didFinish: Observer<Procedure>.DidFinish?

    /// - returns: the queue onto which observer callbacks are dispatched
    public let eventQueue: DispatchQueueProtocol?

    /// Creates a new BlockObserver.
    ///
    /// - parameter synchronizedWith: a provider of the queue onto which observer callbacks are dispatched
    /// - parameter didAttach:   the block which will execute when the observer is attached to a procedure
    /// - parameter willExecute: the block which is called when the attached procedure will execute
    /// - parameter didCancel:   the block which is called when the attached procedure did cancel
    /// - parameter willAdd:     the block which is called when the attached procedure will add a new operation
    /// - parameter didAdd:      the block which is called when the attached procedure did add a new operation
    /// - parameter willFinish:  the block which is called when the attached procedure will finish
    /// - parameter didFinish:   the block which is called when the attached procedure did finish
    ///
    /// - returns: an immutable BlockObserver
    public init(
        synchronizedWith queueProvider: QueueProvider? = nil,
        didAttach: Observer<Procedure>.DidAttach? = nil,
        willExecute: Observer<Procedure>.WillExecute? = nil,
        didExecute: Observer<Procedure>.DidExecute? = nil,
        didCancel: Observer<Procedure>.DidCancel? = nil,
        willAdd: Observer<Procedure>.WillAdd? = nil,
        didAdd: Observer<Procedure>.DidAdd? = nil,
        willFinish: Observer<Procedure>.WillFinish? = nil,
        didFinish: Observer<Procedure>.DidFinish? = nil) {
            self.eventQueue = queueProvider?.providedQueue
            self.didAttach = didAttach
            self.willExecute = willExecute
            self.didExecute = didExecute
            self.didCancel = didCancel
            self.willAdd = willAdd
            self.didAdd = didAdd
            self.willFinish = willFinish
            self.didFinish = didFinish
    }

    public func didAttach(to procedure: Procedure) {
        didAttach?(procedure)
    }

    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        willExecute?(procedure, pendingExecute)
    }

    public func did(execute procedure: Procedure) {
        didExecute?(procedure)
    }

    public func did(cancel procedure: Procedure, withErrors errors: [Error]) {
        didCancel?(procedure, errors)
    }

    public func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        willAdd?(procedure, newOperation)
    }

    public func procedure(_ procedure: Procedure, didAdd newOperation: Operation) {
        didAdd?(procedure, newOperation)
    }

    public func will(finish procedure: Procedure, withErrors errors: [Error], pendingFinish: PendingFinishEvent) {
        willFinish?(procedure, errors, pendingFinish)
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        didFinish?(procedure, errors)
    }
}

/// WillExecuteObserver is an observer which will execute a
/// closure when the procedure starts (prior to the `execute()`
/// method being called).
public struct WillExecuteObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.WillExecute

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach?

    /// - returns: the queue onto which observer callbacks are dispatched
    public let eventQueue: DispatchQueueProtocol?

    /**
     Initialize the observer with a block.

     - parameter synchronizedWith: a provider of the queue onto which observer callbacks are dispatched
     - parameter willExecute: the `Block`
     - returns: an observer.
     */
    public init(synchronizedWith queueProvider: QueueProvider? = nil, willExecute: @escaping Observer<Procedure>.WillExecute) {
        self.block = willExecute
        self.eventQueue = queueProvider?.providedQueue
    }

    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Conforms to `WillExecuteProcedureObserver`, executes the block
    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        block(procedure, pendingExecute)
    }
}

/// DidExecuteObserver is an observer which will execute a
/// closure when the procedure starts.
///
/// - note: This observer will be invoked directly after the
/// `execute` method of the procedure returns.
///
/// - warning: There are no guarantees about when this observer
/// will be called, relative to the lifecycle of the procedure. It
/// is entirely possible that the procedure will actually
/// have already finished be the time the observer is invoked. See
/// the conversation here which explains the reasoning behind it:
/// https://github.com/ProcedureKit/ProcedureKit/pull/554
public struct DidExecuteObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.DidExecute

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach?

    /// - returns: the queue onto which observer callbacks are dispatched
    public let eventQueue: DispatchQueueProtocol?

    /**
     Initialize the observer with a block.

     - parameter synchronizedWith: a provider of the queue onto which observer callbacks are dispatched
     - parameter didExecute: the `Block`
     - returns: an observer.
     */
    public init(synchronizedWith queueProvider: QueueProvider? = nil, didExecute: @escaping Observer<Procedure>.DidExecute) {
        self.block = didExecute
        self.eventQueue = queueProvider?.providedQueue
    }

    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Conforms to `DidExecuteProcedureObserver`, executes the block
    public func did(execute procedure: Procedure) {
        block(procedure)
    }
}

/// DidCancelObserver is an observer which will execute a
/// closure when the procedure cancels.
public struct DidCancelObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.DidCancel

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach?

    /// - returns: the queue onto which observer callbacks are dispatched
    public let eventQueue: DispatchQueueProtocol?

    /// Initialize the observer with a block.
    /// - parameter synchronizedWith: a provider of the queue onto which observer callbacks are dispatched
    /// - parameter didCancel: the `Block`
    /// - returns: an observer.
    public init(synchronizedWith queueProvider: QueueProvider? = nil, didCancel: @escaping Observer<Procedure>.DidCancel) {
        self.block = didCancel
        self.eventQueue = queueProvider?.providedQueue
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure did cancel.
    /// - parameter cancel: the procedure which is cancelled.
    /// - parameter errors: the errors the procedure was cancelled with.
    public func did(cancel procedure: Procedure, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}

/// WillAddOperationObserver is an observer which will execute a
/// closure when the procedure will add another operation.
public struct WillAddOperationObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.WillAdd

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach?

    /// - returns: the queue onto which observer callbacks are dispatched
    public let eventQueue: DispatchQueueProtocol?

    /// Initialize the observer with a block.
    /// - parameter synchronizedWith: a provider of the queue onto which observer callbacks are dispatched
    /// - parameter willAdd: the `Block`
    /// - returns: an observer.
    public init(synchronizedWith queueProvider: QueueProvider? = nil, willAdd: @escaping Observer<Procedure>.WillAdd) {
        self.block = willAdd
        self.eventQueue = queueProvider?.providedQueue
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure will add another Operation.
    /// - parameter procedure: the procedure which will add another Operation.
    /// - parameter newOperation: the new Operation instance which will be added.
    public func procedure(_ procedure: Procedure, willAdd newOperation: Operation) {
        block(procedure, newOperation)
    }
}

/// DidAddOperationObserver is an observer which will execute a
/// closure when the procedure did add another operation.
public struct DidAddOperationObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.DidAdd

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach?

    /// - returns: the queue onto which observer callbacks are dispatched
    public let eventQueue: DispatchQueueProtocol?

    /// Initialize the observer with a block.
    /// - parameter synchronizedWith: a provider of the queue onto which observer callbacks are dispatched
    /// - parameter didAdd: the `Block`
    /// - returns: an observer.
    public init(synchronizedWith queueProvider: QueueProvider? = nil, didAdd: @escaping Observer<Procedure>.DidAdd) {
        self.block = didAdd
        self.eventQueue = queueProvider?.providedQueue
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure did add another Operation.
    /// - parameter procedure: the procedure which did add another Operation.
    /// - parameter newOperation: the new Operation instance which was added.
    public func procedure(_ procedure: Procedure, didAdd newOperation: Operation) {
        block(procedure, newOperation)
    }
}

/// WillFinishObserver is an observer which will execute a
/// closure when the procedure is about to finish.
public struct WillFinishObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.WillFinish

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach?

    /// - returns: the queue onto which observer callbacks are dispatched
    public let eventQueue: DispatchQueueProtocol?

    /// Initialize the observer with a block.
    /// - parameter synchronizedWith: a provider of the queue onto which observer callbacks are dispatched
    /// - parameter willFinish: the `Block`
    /// - returns: an observer.
    public init(synchronizedWith queueProvider: QueueProvider? = nil, willFinish: @escaping Observer<Procedure>.WillFinish) {
        self.block = willFinish
        self.eventQueue = queueProvider?.providedQueue
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure will finish.
    /// - parameter procedure: the procedure which will finish.
    /// - parameter errors: the errors the procedure will finish with
    public func will(finish procedure: Procedure, withErrors errors: [Error], pendingFinish: PendingFinishEvent) {
        block(procedure, errors, pendingFinish)
    }
}

/**
 DidFinishObserver is an observer which will execute a
 closure when the procedure did just finish.
 */
public struct DidFinishObserver<Procedure: ProcedureProtocol>: ProcedureObserver {
    private let block: Observer<Procedure>.DidFinish

    /// - returns: a block which is called when the observer is attached to a procedure
    public var didAttachToProcedure: Observer<Procedure>.DidAttach?

    /// - returns: the queue onto which observer callbacks are dispatched
    public let eventQueue: DispatchQueueProtocol?

    /// Initialize the observer with a block.
    /// - parameter synchronizedWith: a provider of the queue onto which observer callbacks are dispatched
    /// - parameter didFinish: the `Block`
    /// - returns: an observer.
    public init(synchronizedWith queueProvider: QueueProvider? = nil, didFinish: @escaping Observer<Procedure>.DidFinish) {
        self.block = didFinish
        self.eventQueue = queueProvider?.providedQueue
    }

    /// - parameter to: the procedure which is attached
    public func didAttach(to procedure: Procedure) {
        didAttachToProcedure?(procedure)
    }

    /// Observes when the attached procedure did finish.
    /// - parameter procedure: the procedure which will finish.
    /// - parameter errors: the errors the procedure will finish with
    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        block(procedure, errors)
    }
}

public extension ProcedureProtocol {

    private var _currentEventQueue: DispatchQueueProtocol? {
        get {
            guard let queueProvider = self as? QueueProvider else {
                return nil
            }
            return queueProvider.providedQueue
        }
    }

    private func assertQueueProviderIsNotSelf(_ queueProvider: QueueProvider?, function: String = #function) {
        assert(queueProvider == nil || queueProvider!.providedQueue !== _currentEventQueue, "\(function): Synchronizing with self is unnecessary for an observer added to self.")
    }

    /// Adds a WillExecuteObserver to the receiver using a provided block
    ///
    /// - Parameter synchronizedWith: a QueueProvider that provides a queue onto which the observer callback will be dispatched (can be a Procedure, an EventQueue, or a DispatchQueue)
    /// - Parameter block: the block which will be invoked before execute is called.
    func addWillExecuteBlockObserver(synchronizedWith queueProvider: QueueProvider? = nil, block: @escaping Observer<Self>.WillExecute) {
        assertQueueProviderIsNotSelf(queueProvider)
        add(observer: WillExecuteObserver(synchronizedWith: queueProvider, willExecute: block))
    }

    /// Adds a DidExecuteObserver to the receiver using a provided block
    ///
    /// - Parameter synchronizedWith: a QueueProvider that provides a queue onto which the observer callback will be dispatched (can be a Procedure, an EventQueue, or a DispatchQueue)
    /// - Parameter block: the block which will be invoked after execute is called.
    func addDidExecuteBlockObserver(synchronizedWith queueProvider: QueueProvider? = nil, block: @escaping Observer<Self>.DidExecute) {
        assertQueueProviderIsNotSelf(queueProvider)
        add(observer: DidExecuteObserver(synchronizedWith: queueProvider, didExecute: block))
    }

    /// Adds a DidCancelObserver to the receiver using a provided block
    ///
    /// - Parameter synchronizedWith: a QueueProvider that provides a queue onto which the observer callback will be dispatched (can be a Procedure, an EventQueue, or a DispatchQueue)
    /// - Parameter block: the block which will be invoked after the procedure cancels.
    func addDidCancelBlockObserver(synchronizedWith queueProvider: QueueProvider? = nil, block: @escaping Observer<Self>.DidCancel) {
        assertQueueProviderIsNotSelf(queueProvider)
        add(observer: DidCancelObserver(synchronizedWith: queueProvider, didCancel: block))
    }

    /// Adds a WillAddOperationObserver to the receiver using a provided block
    ///
    /// - Parameter synchronizedWith: a QueueProvider that provides a queue onto which the observer callback will be dispatched (can be a Procedure, an EventQueue, or a DispatchQueue)
    /// - Parameter block: the block which will be invoked before the procedure adds another operation.
    func addWillAddOperationBlockObserver(synchronizedWith queueProvider: QueueProvider? = nil, block: @escaping Observer<Self>.WillAdd) {
        assertQueueProviderIsNotSelf(queueProvider)
        add(observer: WillAddOperationObserver(synchronizedWith: queueProvider, willAdd: block))
    }

    /// Adds a DidAddOperationObserver to the receiver using a provided block
    ///
    /// - Parameter synchronizedWith: a QueueProvider that provides a queue onto which the observer callback will be dispatched (can be a Procedure, an EventQueue, or a DispatchQueue)
    /// - Parameter block: the block which will be invoked after the procedure adds another operation.
    func addDidAddOperationBlockObserver(synchronizedWith queueProvider: QueueProvider? = nil, block: @escaping Observer<Self>.DidAdd) {
        assertQueueProviderIsNotSelf(queueProvider)
        add(observer: DidAddOperationObserver(synchronizedWith: queueProvider, didAdd: block))
    }

    /// Adds a WillFinishObserver to the receiver using a provided block
    ///
    /// - Parameter synchronizedWith: a QueueProvider that provides a queue onto which the observer callback will be dispatched (can be a Procedure, an EventQueue, or a DispatchQueue)
    /// - Parameter block: the block which will be invoked before the procedure finishes.
    func addWillFinishBlockObserver(synchronizedWith queueProvider: QueueProvider? = nil, block: @escaping Observer<Self>.WillFinish) {
        assertQueueProviderIsNotSelf(queueProvider)
        add(observer: WillFinishObserver(synchronizedWith: queueProvider, willFinish: block))
    }

    /// Adds a DidFinishObserver to the receiver using a provided block
    ///
    /// - Parameter synchronizedWith: a QueueProvider that provides a queue onto which the observer callback will be dispatched (can be a Procedure, an EventQueue, or a DispatchQueue)
    /// - Parameter block: the block which will be invoked after the procedure has finished.
    func addDidFinishBlockObserver(synchronizedWith queueProvider: QueueProvider? = nil, block: @escaping Observer<Self>.DidFinish) {
        assertQueueProviderIsNotSelf(queueProvider)
        add(observer: DidFinishObserver(synchronizedWith: queueProvider, didFinish: block))
    }
}

// MARK: - Unavailable

public extension ProcedureProtocol {

    @available(*, unavailable, renamed: "addDidCancelBlockObserver(block:)", message: "WillCancel observers are no longer available. Use a DidCancel observer.")
    func addWillCancelBlockObserver(block: @escaping Observer<Self>.ErrorsBlock) {
        fatalError("No longer available.")
    }
}
