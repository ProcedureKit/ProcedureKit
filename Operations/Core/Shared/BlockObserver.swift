//
//  BlockObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A `BlockObserver` which accepts three different blocks for start, 
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
    A `BlockObserver` which accepts three different blocks for start,
    produce and finish.

    The arguments all default to `.None` which means that the most
    typical use case for observing when the operation finishes. e.g.

        operation.addObserver(BlockObserver { (_, errors) in
            // The operation finished, maybe with errors,
            // which you should handle.
        })

    :param: startHandler, a optional block of type Operation -> Void
    :param: produceHandler, a optional block of type (Operation, NSOperation) -> Void
    :param: finishHandler, a optional block of type (Operation, [ErrorType]) -> Void
    */
    public init(startHandler: StartHandler? = .None, produceHandler: ProduceHandler? = .None, finishHandler: FinishHandler? = .None) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }

    public func operationDidStart(operation: Operation) {
        startHandler?(operation)
    }

    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        produceHandler?(operation, newOperation)
    }

    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        finishHandler?(operation, errors)
    }
}

