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

     - parameter procedure: the observed `Procedure`.
     */
    func didAttachTo(procedure: Procedure)
}

public extension ProcedureObserver {

    /**
     Default implementation does nothing.

     - parameter procedure: the observed `Procedure`.
     */
    func didAttachTo(procedure: Procedure) { }
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses. They 
 will receive a callback when the operation starts.
 */
public protocol WillExecuteProcedureObserver: ProcedureObserver {

    /**
     The procedure will execute.

     - parameter procedure: the observed `Procedure`.
     */
    func willExecute(procedure: Procedure)
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses. They 
 will receive a callback when the operation cancels.
 */
public protocol WillCancelProcedureObserver: ProcedureObserver {

    /**
     The procedure will cancel.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of [Error] types.
     */
    func willCancel(procedure: Procedure, errors: [Error])
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses. They 
 will receive a callback when the operation cancels.
 */
public protocol DidCancelProcedureObserver: ProcedureObserver {

    /**
     The procedure did cancel.

     - parameter procedure: the observed `Procedure`.
     */
    func didCancel(procedure: Procedure)
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses. They 
 will receive a callback when the Procedure produces another operation.
 */
public protocol DidProduceOperationProcedureObserver: ProcedureObserver {

    /**
     The procedure produced a new `Operation` instance which has been added to the
     queue. Note that this isn't necessarily an `Procedure`, so be careful, if you
     intend to automatically start observing it.

     - parameter procedure: the observed `Procedure`.
     - parameter newOperation: the produced `Operation`
     */
    func procedure(_ procedure: Procedure, didProduceOperation newOperation: Operation)
}

/**
 Types which confirm to this protocol, can be attached to `Procedure` subclasses.
 */
public protocol WillFinishProcedureObserver: ProcedureObserver {

    /**
     The procedure will finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of `Error`s.
     */
    func willFinish(procedure: Procedure, errors: [Error])
}

/**
 Types which conform to this protocol, can be attached to `Operation` subclasses. They 
 will receive a callback when the procedure finishes.
 */
public protocol DidFinishProcedureObserver: ProcedureObserver {

    /**
     The procedure did finish. Any errors that were encountered are collected here.

     - parameter procedure: the observed `Procedure`.
     - parameter errors: an array of `ErrorType`s.
     */
    func didFinish(procedure: Procedure, errors: [Error])
}

