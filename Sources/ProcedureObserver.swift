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

    associatedtype Procedure: ProcedureProcotol

    /**
     Observer gets notified when it is attached to a procedure.

     - parameter procedure: the observed procedure, P.
     */
    func didAttach(to procedure: Procedure)

    /**
     The procedure will execute.

     - parameter procedure: the observed `Procedure`.
     */
    func will(execute procedure: Procedure)

    /**
     The procedure will cancel.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of [Error] types.
     */
    func will(cancel procedure: Procedure, withErrors: [Error])

    /**
     The procedure did cancel.

     - parameter procedure: the observed `Procedure`.
     */
    func did(cancel procedure: Procedure, withErrors: [Error])

    /**
     The procedure produced a new `Operation` instance which has been added to the
     queue. Note that this isn't necessarily an `Procedure`, so be careful, if you
     intend to automatically start observing it.

     - parameter procedure: the observed `Procedure`.
     - parameter newOperation: the produced `Operation`
     */
    func procedure(_ procedure: Procedure, didProduce newOperation: Operation)

    /**
     The procedure will finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of `Error`s.
     */
    func will(finish procedure: Procedure, withErrors errors: [Error])

    /**
     The procedure did finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of `ErrorType`s.
     */
    func did(finish procedure: Procedure, withErrors errors: [Error])
}

public extension ProcedureObserver {

    /**
     Default implementations that do nothing.

     - parameter procedure: the observed `Procedure`.
     */
    func didAttach(to procedure: Procedure) { }

    func will(execute procedure: Procedure) { }

    func will(cancel procedure: Procedure, withErrors: [Error]) { }

    func did(cancel procedure: Procedure, withErrors: [Error]) { }

    func procedure(_ procedure: Procedure, didProduce newOperation: Operation) { }

    func will(finish procedure: Procedure, withErrors errors: [Error]) { }

    func did(finish procedure: Procedure, withErrors errors: [Error]) { }
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
