//
//  BlockObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A `OperationObserver` which accepts three different blocks for start,
produce and finish.
*/
public struct BlockObserver: OperationObserver {

    public typealias StartHandler = Operation -> Void
    public typealias ProduceHandler = (Operation, NSOperation) -> Void
    public typealias FinishHandler = (Operation, [ErrorType]) -> Void

    let startHandler: StartHandler?
    let produceHandler: ProduceHandler?
    let finishHandler: FinishHandler?

    /**
    A `OperationObserver` which accepts three different blocks for start,
    produce and finish.

    The arguments all default to `.None` which means that the most
    typical use case for observing when the operation finishes. e.g.

        operation.addObserver(BlockObserver { _, errors in
            // The operation finished, maybe with errors,
            // which you should handle.
        })

    - parameter startHandler, a optional block of type Operation -> Void
    - parameter produceHandler, a optional block of type (Operation, NSOperation) -> Void
    - parameter finishHandler, a optional block of type (Operation, [ErrorType]) -> Void
    */
    public init(startHandler: StartHandler? = .None, produceHandler: ProduceHandler? = .None, finishHandler: FinishHandler? = .None) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }

    /// Conforms to `OperationObserver`, executes the optional startHandler.
    public func operationDidStart(operation: Operation) {
        startHandler?(operation)
    }

    /// Conforms to `OperationObserver`, executes the optional produceHandler.
    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        produceHandler?(operation, newOperation)
    }

    /// Conforms to `OperationObserver`, executes the optional finishHandler.
    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        finishHandler?(operation, errors)
    }
}

