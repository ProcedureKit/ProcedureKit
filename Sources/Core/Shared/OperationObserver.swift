//
//  OperationObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public enum OperationEvent: Int {
    case attached = 0, started, cancelled, produced, finished
}

extension OperationEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .attached: return "Attached"
        case .started: return "Started"
        case .cancelled: return "Cancelled"
        case .produced: return "Produced"
        case .finished: return "Finished"
        }
    }
}

/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses before
 they are added to a queue.
 */
public protocol OperationObserverType {

    /**
     Observer gets notified when it is attached to an operation.

     - parameter operation: the observed `Procedure`.
    */
    func didAttachToOperation(_ operation: Procedure)
}



public extension OperationObserverType {

    /**
     Default implementation of didAttachToOperation
     is a none-operation.

     - parameter operation: the observed `Procedure`.
    */
    func didAttachToOperation(_ operation: Procedure) { /* No operation */ }
}



/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses before
 they are added to a queue. They will receive a callback when the operation starts.
 */
public protocol OperationWillExecuteObserver: OperationObserverType {

    /**
     The operation will execute.

     - parameter operation: the observed `Procedure`.
     */
    func willExecuteOperation(_ operation: Procedure)
}


/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses before
 they are added to a queue. They will receive a callback when the operation cancels.
 */
public protocol OperationWillCancelObserver: OperationObserverType {

    /**
     The operation will cancel.

     - parameter operation: the observed `Procedure`.
     */
    func willCancelOperation(_ operation: Procedure, errors: [ErrorProtocol])
}


/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses before
 they are added to a queue. They will receive a callback when the operation cancels.
 */
public protocol OperationDidCancelObserver: OperationObserverType {

    /**
     The operation did cancel.

     - parameter operation: the observed `Procedure`.
     */
    func didCancelOperation(_ operation: Procedure)
}


/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses before
 they are added to a queue. They will receive a callback when the operation produces
 another operation.
 */
public protocol OperationDidProduceOperationObserver: OperationObserverType {

    /**
     The operation produced a new `NSOperation` instance which has been added to the
     queue. Note that this isn't necessarily an `Procedure`, so be careful, if you
     intend to automatically start observing it.

     - parameter operation: the observed `Procedure`.
     - parameter newOperation: the produced `NSOperation`
     */
    func operation(_ operation: Procedure, didProduceOperation newOperation: Operation)
}


/**
 Types which confirm to this protocol, can be attached to `Procedure` subclasses.
 */
public protocol OperationWillFinishObserver: OperationObserverType {

    /**
     The operation will finish. Any errors that were encountered are collected here.

     - parameter operation: the observed `Procedure`.
     - parameter errors: an array of `ErrorType`s.
     */
    func willFinishOperation(_ operation: Procedure, errors: [ErrorProtocol])
}


/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses before
 they are added to a queue. They will receive a callback when the operation finishes.
 */
public protocol OperationDidFinishObserver: OperationObserverType {

    /**
     The operation did finish. Any errors that were encountered are collected here.

     - parameter operation: the observed `Procedure`.
     - parameter errors: an array of `ErrorType`s.
     */
    func didFinishOperation(_ operation: Procedure, errors: [ErrorProtocol])
}


/**
 Types which conform to this protocol, can be attached to `Procedure` subclasses before
 they are added to a queue. They will receive callbacks when the operation starts,
 produces a new operation, and finishes.
 */
public protocol OperationObserver: OperationWillExecuteObserver, OperationWillCancelObserver, OperationDidCancelObserver, OperationDidProduceOperationObserver, OperationWillFinishObserver, OperationDidFinishObserver { }
