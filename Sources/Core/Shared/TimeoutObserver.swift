//
//  TimeoutObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
An operation observer which will automatically cancels (with an error)
if it doesn't finish before a time interval is expired.
*/
public struct TimeoutObserver: OperationObserver {

    private let timeout: NSTimeInterval

    /**
    Initialize the operation observer with a timeout, which will start when 
    the operation to which it is attached starts.

    - parameter timeout: a `NSTimeInterval` value.
    */
    public init(timeout: NSTimeInterval) {
        self.timeout = timeout
    }

    /**
    Conforms to `OperationObserver`, when the operation starts, it triggers
    a block using dispatch_after and the time interval. When the block runs,
    if the operation has not finished and is not cancelled, then it will
    cancel it with an error of `OperationError.OperationTimedOut`
    
    - parameter operation: the `Operation` which will be cancelled if the timeout is reached.
    */
    public func operationDidStart(operation: Operation) {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))

        dispatch_after(when, Queue.Default.queue) {
            if !operation.finished && !operation.cancelled {
                let error = OperationError.OperationTimedOut(self.timeout)
                operation.cancelWithError(error)
            }
        }
    }

    /// Conforms to `OperationObserver`, has no opertion for when another operation is produced.
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {}

    /// Conforms to `OperationObserver`, has no opertion for when the operation finishes
    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {}
}



