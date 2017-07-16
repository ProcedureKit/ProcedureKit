//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses to receive
 events at state transitions.
 */
public protocol ProcedureObserver {

    /**
     Observer gets notified when it is attached to a procedure.

     - parameter procedure: the observed procedure, P.
     */
    func didAttach(to procedure: ProcedureProtocol)

    /**
     The procedure will execute.

     - parameter procedure: the observed `Procedure`.
     */
    func will(execute procedure: ProcedureProtocol, pendingExecute: PendingExecuteEvent)

    /**
     The procedure did execute.

     - notes: this observer will be invoked directly after the
     `execute` returns.

     - warning: there are no guarantees about when this observer
     will be called, relative to the lifecycle of the procedure. It
     is entirely possible that the procedure, will actually
     have already finished be the time the observer is invoked. See
     the conversation here which explains the reasoning behind it:
     https://github.com/ProcedureKit/ProcedureKit/pull/554

     - parameter procedure: the observed `Procedure`.
     */
    func did(execute procedure: ProcedureProtocol)

    /**
     The procedure did cancel.

     - parameter procedure: the observed `Procedure`.
     */
    func did(cancel procedure: ProcedureProtocol, withErrors: [Error])

    /**
     The procedure will add a new `Operation` instance to the
     queue. Note that this isn't necessarily a `Procedure`, so be careful, if you
     intend to automatically start observing it.

     - parameter procedure: the observed `Procedure`.
     - parameter newOperation: the `Operation` which will be added
     */
    func procedure(_ procedure: ProcedureProtocol, willAdd newOperation: Operation)

    /**
     The procedure did add a new `Operation` instance to the
     queue. Note that this isn't necessarily a `Procedure`, so be careful, if you
     intend to automatically start observing it.

     - parameter procedure: the observed `Procedure`.
     - parameter newOperation: the `Operation` which has been added to the queue
     */
    func procedure(_ procedure: ProcedureProtocol, didAdd newOperation: Operation)

    /**
     The procedure will finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of `Error`s.
     */
    func will(finish procedure: ProcedureProtocol, withErrors: [Error], pendingFinish: PendingFinishEvent)

    /**
     The procedure did finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of `ErrorType`s.
     */
    func did(finish procedure: ProcedureProtocol, withErrors: [Error])

    /**
     Provide a queue onto which observer callbacks will be dispatched.
    */
    var eventQueue: DispatchQueueProtocol? { get }
}

public extension ProcedureObserver {
    // MARK: - Unavailable/renamed observer callbacks
    @available(*, unavailable, renamed: "will(execute:pendingExecute:)")
    func will(execute procedure: ProcedureProtocol) { }

    @available(*, unavailable, renamed: "will(finish:withErrors:pendingFinish:)")
    func will(finish procedure: ProcedureProtocol, withErrors: [Error]) { }
}

public extension ProcedureObserver {

    func didAttach(to procedure: ProcedureProtocol) { }

    func will(execute procedure: ProcedureProtocol, pendingExecute: PendingExecuteEvent) { }

    func did(execute procedure: ProcedureProtocol) { }

    func did(cancel procedure: ProcedureProtocol, withErrors: [Error]) { }

    func procedure(_ procedure: ProcedureProtocol, willAdd newOperation: Operation) { }

    func procedure(_ procedure: ProcedureProtocol, didAdd newOperation: Operation) { }

    func will(finish procedure: ProcedureProtocol, withErrors errors: [Error], pendingFinish: PendingFinishEvent) { }

    func did(finish procedure: ProcedureProtocol, withErrors errors: [Error]) { }

    var eventQueue: DispatchQueueProtocol? { return nil }
}

// MARK: - Unavilable & Renamed

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationObserverType { }

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationWillExecuteObserver { }

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationWillCancelObserver { }

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationDidCancelObserver { }

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationDidProduceOperationObserver { }

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationWillFinishObserver { }

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationDidFinishObserver { }

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationObserver { }
