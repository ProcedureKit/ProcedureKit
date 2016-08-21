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
    func didAttach<P: Procedure>(to procedure: P)
}

public extension ProcedureObserver {

    /**
     Default implementation does nothing.

     - parameter procedure: the observed `Procedure`.
     */
    func didAttach<P: Procedure>(to procedure: P) { }
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses. They
 will receive a callback when the operation starts.
 */
public protocol WillExecuteProcedureObserver: ProcedureObserver {

    associatedtype P: Procedure

    /**
     The procedure will execute.

     - parameter procedure: the observed `Procedure`.
     */
    func will(execute procedure: P)
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses. They
 will receive a callback when the operation cancels.
 */
public protocol WillCancelProcedureObserver: ProcedureObserver {

    associatedtype P: Procedure

    /**
     The procedure will cancel.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of [Error] types.
     */
    func will(cancel procedure: P, errors: [Error])
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses. They
 will receive a callback when the operation cancels.
 */
public protocol DidCancelProcedureObserver: ProcedureObserver {

    associatedtype P: Procedure

    /**
     The procedure did cancel.

     - parameter procedure: the observed `Procedure`.
     */
    func did(cancel procedure: P)
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses. They
 will receive a callback when the Procedure produces another operation.
 */
public protocol DidProduceOperationProcedureObserver: ProcedureObserver {

    associatedtype P: Procedure

    /**
     The procedure produced a new `Operation` instance which has been added to the
     queue. Note that this isn't necessarily an `Procedure`, so be careful, if you
     intend to automatically start observing it.

     - parameter procedure: the observed `Procedure`.
     - parameter newOperation: the produced `Operation`
     */
    func procedure(_ procedure: P, didProduce newOperation: Operation)
}

/**
 Types which confirm to this protocol, can be attached to `Procedure` subclasses.
 */
public protocol WillFinishProcedureObserver: ProcedureObserver {

    associatedtype P: Procedure

    /**
     The procedure will finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of `Error`s.
     */
    func will(finish procedure: P, withErrors errors: [Error])
}

/**
 Types which conform to this protocol, can be attached to `Operation` subclasses. They
 will receive a callback when the procedure finishes.
 */
public protocol DidFinishProcedureObserver: ProcedureObserver {

    associatedtype P: Procedure

    /**
     The procedure did finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of `ErrorType`s.
     */
    func did(finish procedure: P, withErrors errors: [Error])
}


// MARK: - Unavilable & Renamed

@available(*, unavailable, renamed: "ProcedureObserver")
public protocol OperationObserverType { }

@available(*, unavailable, renamed: "WillExecuteProcedureObserver")
public protocol OperationWillExecuteObserver { }

@available(*, unavailable, renamed: "WillCancelProcedureObserver")
public protocol OperationWillCancelObserver { }

@available(*, unavailable, renamed: "DidCancelProcedureObserver")
public protocol OperationDidCancelObserver { }

@available(*, unavailable, renamed: "DidProduceOperationProcedureObserver")
public protocol OperationDidProduceOperationObserver { }

@available(*, unavailable, renamed: "WillFinishProcedureObserver")
public protocol OperationWillFinishObserver { }

@available(*, unavailable, renamed: "DidFinishProcedureObserver")
public protocol OperationDidFinishObserver { }

@available(*, unavailable, message: "This protocol has now been removed and can be replaced with the required combination of ProcedureObserver protocols.")
public protocol OperationObserver { }
