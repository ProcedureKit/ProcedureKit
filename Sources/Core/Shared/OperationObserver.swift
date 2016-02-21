//
//  OperationObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public struct OperationObserverKind: OptionSetType {
    public let rawValue: Int

    static let DidStart = OperationObserverKind(rawValue: 1 << 1)
    static let DidCancel = OperationObserverKind(rawValue: 1 << 2)
    static let DidProduceOperation = OperationObserverKind(rawValue: 1 << 3)
    static let WillFinish = OperationObserverKind(rawValue: 1 << 4)
    static let DidFinish = OperationObserverKind(rawValue: 1 << 5)
    static let All: OperationObserverKind = [ .DidStart, .DidCancel, .DidProduceOperation, .WillFinish, .DidFinish ]

    public init(rawValue: Int) { self.rawValue = rawValue }
}

/**
 Types which conform to this protocol, can be attached to `Operation` subclasses before
 they are added to a queue.
 */
public protocol OperationObserverType {

    var kind: OperationObserverKind { get }

    /**
     Observer gets notified when it is attached to an operation.
     
     - parameter operation: the observed `Operation`.
    */
    func didAttachToOperation(operation: Operation)

    /**
     Observer gets notified when it will be detached from 
     the operation. This will happen after all relevant events
     have been observed.

     - parameter operation: the observed `Operation`.
     */
    func willDetachFromOperation(operation: Operation)
}



public extension OperationObserverType {

    /**
     Default implementation of didAttachToOperation 
     is a none-operation.
     
     - parameter operation: the observed `Operation`.
    */
    func didAttachToOperation(operation: Operation) { /* No operation */ }

    /**
    Default implementation of willDetachFromOperation
    is a none-operation.

    - parameter operation: the observed `Operation`.
    */
    func willDetachFromOperation(operation: Operation) { /* No operation */ }
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

public extension OperationDidStartObserver {

    /// - returns: the kind of the observer
    var kind: OperationObserverKind { return .DidStart }
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

public extension OperationDidCancelObserver {

    /// - returns: the kind of the observer
    var kind: OperationObserverKind { return .DidCancel }
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

public extension OperationDidProduceOperationObserver {

    /// - returns: the kind of the observer
    var kind: OperationObserverKind { return .DidProduceOperation }
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

public extension OperationWillFinishObserver {

    /// - returns: the kind of the observer
    var kind: OperationObserverKind { return .WillFinish }
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

public extension OperationDidFinishObserver {

    /// - returns: the kind of the observer
    var kind: OperationObserverKind { return .DidFinish }
}



/**
 Types which conform to this protocol, can be attached to `Operation` subclasses before
 they are added to a queue. They will receive callbacks when the operation starts,
 produces a new operation, and finishes.
 */
public protocol OperationObserver: OperationDidStartObserver, OperationDidCancelObserver, OperationDidProduceOperationObserver, OperationWillFinishObserver, OperationDidFinishObserver { }

