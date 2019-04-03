//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses to receive
 events at state transitions.
 */
public protocol ProcedureObserver {

    associatedtype Procedure: ProcedureProtocol

    /**
     Observer gets notified when it is attached to a procedure.

     - parameter procedure: the observed procedure, P.
     */
    func didAttach(to procedure: Procedure)

    /**
     Observer gets notified when the attached InputProcedure has
     it's input value set ready.

     - parameter procedure: the observed procedure, P
     */
    func didSetInputReady(on procedure: Procedure)

    /**
     The procedure will execute.

     - parameter procedure: the observed `Procedure`.
     */
    func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent)

    /**
     The procedure did execute.

     - note: This observer will be invoked directly after the
     `execute` method of the procedure returns.

     - warning: There are no guarantees about when this observer
     will be called, relative to the lifecycle of the procedure. It
     is entirely possible that the procedure will actually
     have already finished be the time the observer is invoked. See
     the conversation here which explains the reasoning behind it:
     https://github.com/ProcedureKit/ProcedureKit/pull/554

     - parameter procedure: the observed `Procedure`.
     */
    func did(execute procedure: Procedure)

    /**
     The procedure did cancel.

     - parameter procedure: the observed `Procedure`.
     */
    func did(cancel procedure: Procedure, with error: Error?)

    /**
     The procedure will add a new `Operation` instance to the
     queue. Note that this isn't necessarily a `Procedure`, so be careful, if you
     intend to automatically start observing it.

     - parameter procedure: the observed `Procedure`.
     - parameter newOperation: the `Operation` which will be added
     */
    func procedure(_ procedure: Procedure, willAdd newOperation: Operation)

    /**
     The procedure did add a new `Operation` instance to the
     queue. Note that this isn't necessarily a `Procedure`, so be careful, if you
     intend to automatically start observing it.

     - parameter procedure: the observed `Procedure`.
     - parameter newOperation: the `Operation` which has been added to the queue
     */
    func procedure(_ procedure: Procedure, didAdd newOperation: Operation)

    /**
     The procedure will finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an Error.
     */
    func will(finish procedure: Procedure, with error: Error?, pendingFinish: PendingFinishEvent)

    /**
     The procedure did finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter error: an Error.
     */
    func did(finish procedure: Procedure, with error: Error?)

    /**
     Provide a queue onto which observer callbacks will be dispatched.
    */
    var eventQueue: DispatchQueueProtocol? { get }
}

public extension ProcedureObserver {
    // MARK: - Unavailable/renamed observer callbacks
    @available(*, unavailable, renamed: "will(execute:pendingExecute:)")
    func will(execute procedure: Procedure) { }

    @available(*, unavailable, renamed: "will(finish:withErrors:pendingFinish:)")
    func will(finish procedure: Procedure, withErrors: [Error]) { }

    @available(*, deprecated, renamed: "did(cancel:with:)", message: "Use did(cancel:with:) instead.")
    func did(cancel procedure: Procedure, withErrors errors: [Error]) {
        did(cancel: procedure, with: errors.first)
    }

    @available(*, deprecated, renamed: "will(finish:with:pendingFinish:)", message: "Use will(finish:with:pendingFinish:) instead.")
    func will(finish procedure: Procedure, withErrors errors: [Error], pendingFinish: PendingFinishEvent) {
        will(finish: procedure, with: errors.first, pendingFinish: pendingFinish)
    }

    @available(*, deprecated, renamed: "did(finish:with:)", message: "Use did(finish:with:) instead.")
    func did(finish procedure: Procedure, withErrors errors: [Error]) {
        did(finish: procedure, with: errors.first)
    }
}

public extension ProcedureObserver {

    /// Do nothing.
    func didAttach(to procedure: Procedure) { }

    /// Do nothing
    func didSetInputReady(on procedure: Procedure) { }

    /// Do nothing.
    func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) { }

    /// Do nothing.
    func did(execute procedure: Procedure) { }

    /// Do nothing.
    func did(cancel procedure: Procedure, with error: Error?) { }

    /// Do nothing.
    func procedure(_ procedure: Procedure, willAdd newOperation: Operation) { }

    /// Do nothing.
    func procedure(_ procedure: Procedure, didAdd newOperation: Operation) { }

    /// Do nothing.
    func will(finish procedure: Procedure, with error: Error?, pendingFinish: PendingFinishEvent) { }

    /// Do nothing.
    func did(finish procedure: Procedure, with error: Error?) { }

    /// - Returns: nil
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
