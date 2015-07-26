//
//  LoggingObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
    Attach a `LoggingObserver to an operation to log when the operation
    start, produces new operation and finsihed. It doesn't yet report
    detailed error infomation.

    Any produced `Operation` instances will automatically get their
    own logger attached.
    
    - queue: Provide a queue, by detault it uses it's own serial queue.
    - logger: Provide a logging block. By detault the logger uses `println`
    however, for custom loggers provide a block which receives a `String`.
*/
public struct LoggingObserver: OperationObserver {
    public typealias LoggerBlockType = (message: String) -> Void

    let logger: LoggerBlockType
    let queue: dispatch_queue_t

    public init(queue: dispatch_queue_t = Queue.Initiated.serial("me.danthorpe.Operations.Logger"), logger: LoggerBlockType = { println($0) }) {
        self.queue = queue
        self.logger = logger
    }

    public func operationDidStart(operation: Operation) {
        log("\(operationName(operation)): did start.")
    }

    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        var detail = "\(newOperation)"

        if let newOperation = newOperation as? Operation {
            newOperation.addObserver(LoggingObserver(queue: queue, logger: logger))
            detail = "\(operationName(newOperation))"
        }

        log("\(operationName(operation)): did produce operation: \(detail).")
    }

    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        var detail = errors.count > 0 ? "\(errors.count) error(s)" : "no errors"
        log("\(operationName(operation)): finished with \(detail).")
    }

    private func operationName(operation: Operation) -> String {
        if let name = operation.name {
            return "\(name)"
        }
        return "\(operation)"
    }

    private func log(message: String) {
        dispatch_async(queue) {
            self.logger(message: message)
        }
    }
}

