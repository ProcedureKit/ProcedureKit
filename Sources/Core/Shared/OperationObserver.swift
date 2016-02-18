//
//  OperationObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
 Types which conform to this protocol, can be attached to `Operation` subclasses before
 they are added to a queue.
 */
public protocol OperationObserverType {

    /**
     Observer gets notified when it is attached to an operation.
     
     - parameter operation: the observed `Operation`.
    */
    func didAttachToOperation(operation: Operation)
}



public extension OperationObserverType {

    /**
     Default implementation is a no-operation.
     
     - parameter operation: the observed `Operation`.
    */
    func didAttachToOperation(operation: Operation) { /* No operation */ }
}



/**
 Types which conform to this protocol, can be attached to `Operation` subclasses before
 they are added to a queue. They will receive a callback when the operation starts.
 */
public protocol OperationDidStartObserver: OperationObserverType {

    /**
     The operation started.

     - parameter operation: the observed `Operation`.
     */
    func didStartOperation(operation: Operation)
}



/**
 Types which conform to this protocol, can be attached to `Operation` subclasses before
 they are added to a queue. They will receive a callback when the operation cancels.
 */
public protocol OperationDidCancelObserver: OperationObserverType {

    /**
     The operation was cancelled.

     - parameter operation: the observed `Operation`.
     */
    func didCancelOperation(operation: Operation)
}



/**
 Types which conform to this protocol, can be attached to `Operation` subclasses before
 they are added to a queue. They will receive a callback when the operation produces
 another operation.
 */
public protocol OperationDidProduceOperationObserver: OperationObserverType {

    /**
     The operation produced a new `NSOperation` instance which has been added to the
     queue. Note that this isn't necessarily an `Operation`, so be careful, if you
     intend to automatically start observing it.

     - parameter operation: the observed `Operation`.
     - parameter newOperation: the produced `NSOperation`
     */
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation)
}



/**
 Types which confirm to this protocol, can be attached to `Operation` subclasses.
 */
public protocol OperationWillFinishObserver: OperationObserverType {

    /**
     The operation will finish. Any errors that were encountered are collected here.

     - parameter operation: the observed `Operation`.
     - parameter errors: an array of `ErrorType`s.
     */
    func willFinishOperation(operation: Operation, errors: [ErrorType])
}



/**
 Types which conform to this protocol, can be attached to `Operation` subclasses before
 they are added to a queue. They will receive a callback when the operation finishes.
 */
public protocol OperationDidFinishObserver: OperationObserverType {

    /**
     The operation did finish. Any errors that were encountered are collected here.

     - parameter operation: the observed `Operation`.
     - parameter errors: an array of `ErrorType`s.
     */
    func didFinishOperation(operation: Operation, errors: [ErrorType])
}



/**
 Types which conform to this protocol, can be attached to `Operation` subclasses before
 they are added to a queue. They will receive callbacks when the operation starts,
 produces a new operation, and finishes.
 */
public protocol OperationObserver: OperationDidStartObserver, OperationDidCancelObserver, OperationDidProduceOperationObserver, OperationWillFinishObserver, OperationDidFinishObserver { }

