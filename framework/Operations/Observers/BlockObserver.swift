//
//  BlockObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public struct BlockObserver: OperationObserver {
    public typealias StartHandler = Operation -> Void
    public typealias ProduceHandler = (Operation, NSOperation) -> Void
    public typealias FinishHandler = (Operation, [ErrorType]) -> Void

    let startHandler: StartHandler?
    let produceHandler: ProduceHandler?
    let finishHandler: FinishHandler?

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

