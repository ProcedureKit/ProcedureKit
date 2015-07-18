//
//  BlockObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

struct BlockObserver: OperationObserver {
    typealias StartHandler = Operation -> Void
    typealias ProduceHandler = (Operation, NSOperation) -> Void
    typealias FinishHandler = (Operation, [ErrorType]) -> Void

    let startHandler: StartHandler?
    let produceHandler: ProduceHandler?
    let finishHandler: FinishHandler?

    init(startHandler: StartHandler? = .None, produceHandler: ProduceHandler? = .None, finishHandler: FinishHandler? = .None) {
        self.startHandler = startHandler
        self.produceHandler = produceHandler
        self.finishHandler = finishHandler
    }

    func operationDidStart(operation: Operation) {
        startHandler?(operation)
    }

    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        produceHandler?(operation, newOperation)
    }

    func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        finishHandler?(operation, errors)
    }
}

