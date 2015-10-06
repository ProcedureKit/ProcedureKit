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
they are added to a queue. They will receive callbacks when the operation starts, 
produces a new operation, and finishes.
*/
public protocol OperationObserver {

    /**
    The operation started.
    
    - parameter operaton: the observed `Operation`.
    */
    func operationDidStart(operation: Operation)

    /**
    The operation produced a new `NSOperation` instance which has been added to the 
    queue. Note that this isn't necessarily an `Operation`, so be careful, if you 
    intend to automatically start observing it.
    
    - parameter operaton: the observed `Operation`.
    - parameter newOperation: the produced `NSOperation`
    */
    func operation(operation: Operation, didProduceOperation newOperation: NSOperation)

    /**
    The operation did finish. Any errors that were encountered are collected here.
    
    - parameter operaton: the observed `Operation`.
    - parameter errors: an array of `ErrorType`s.
    */
    func operationDidFinish(operation: Operation, errors: [ErrorType])
}
