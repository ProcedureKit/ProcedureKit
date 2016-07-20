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
start, produces new operation and finsihed.

Any produced `OldOperation` instances will automatically get their
own logger attached.
*/
@available(iOS, deprecated=9, message="Use the log property of OldOperation directly.")
@available(OSX, deprecated=10.11, message="Use the log property of OldOperation directly.")
public struct LoggingObserver: OperationObserver {
    public typealias LoggerBlockType = (message: String) -> Void

    let logger: LoggerBlockType
    let queue: dispatch_queue_t

    /**
    Create a logging observer. Accepts as the final argument a block which receives a
    `String` message to be logged. By default this just uses `print()`, but construct
    with a custom block to send logs to other systems. The block is executed on a
    dispatch queue.

    - parameter queue: a queue, by detault it uses it's own serial queue.
    - parameter logger: a logging block. By detault the logger uses `println`
    however, for custom loggers provide a block which receives a `String`.
    */
    public init(queue: dispatch_queue_t = Queue.Initiated.serial("me.danthorpe.Operations.Logger"), logger: LoggerBlockType = { print($0) }) {
        self.queue = queue
        self.logger = logger
    }

    /**
    Conforms to `OperationObserver`. The logger is sent a string which uses the
    `name` parameter of the operation if provived.

       "My OldOperation: did start."

    - parameter operation: the `OldOperation` which has started.
    */
    public func willExecuteOperation(operation: OldOperation) {
        log("\(operation.operationName): will execute.")
    }

    /**
     Conforms to `OperationObserver`. The logger is sent a string which uses the
     `name` parameter of the operation if provived.

     "My OldOperation: did cancel."

     - parameter operation: the `OldOperation` which has started.
     */
    public func willCancelOperation(operation: OldOperation, errors: [ErrorType]) {
        let detail = errors.count > 0 ? "error(s): \(errors)" : "no errors"
        log("\(operation.operationName): will cancel with \(detail).")
    }

    /**
     Conforms to `OperationObserver`. The logger is sent a string which uses the
     `name` parameter of the operation if provived.

     "My OldOperation: did cancel."

     - parameter operation: the `OldOperation` which has started.
     */
    public func didCancelOperation(operation: OldOperation) {
        log("\(operation.operationName): did cancel.")
    }

    /**
    Conforms to `OperationObserver`. The logger is sent a string which uses the
    `name` parameter of the operation if provived.

        "My OldOperation: did produce operation: My Other OldOperation."

    If the produced operation is an `OldOperation`, then a new `LoggingObserver` with
    same queue and logger will be attached to it as an observer. Meaning that when
    the produced operation starts/produces/finishes, it will also generate log
    output.

    - parameter operation: the `OldOperation` producer.
    - parameter newOperation: the `OldOperation` which has been produced.
    */
    public func operation(operation: OldOperation, didProduceOperation newOperation: NSOperation) {
        let detail = newOperation.operationName

        if let newOperation = newOperation as? OldOperation {
            newOperation.addObserver(LoggingObserver(queue: queue, logger: logger))
        }

        log("\(operation.operationName): did produce operation: \(detail).")
    }

    /**
     Conforms to `OperationObserver`. The logger is sent a string which uses the
     `name` parameter of the operation if provived. If there were errors, output
     looks like

     "My OldOperation: finsihed with error(s): [My OldOperation Error]."

     or if no errors:

     "My OldOperation: finsihed with no errors."

     - parameter operation: the `OldOperation` that finished.
     - parameter errors: an array of `ErrorType`, not that these will be printed out.
     */
    public func willFinishOperation(operation: OldOperation, errors: [ErrorType]) {
        let detail = errors.count > 0 ? "error(s): \(errors)" : "no errors"
        log("\(operation.operationName): will finish with \(detail).")
    }

    /**
    Conforms to `OperationObserver`. The logger is sent a string which uses the
    `name` parameter of the operation if provived. If there were errors, output
    looks like

        "My OldOperation: finsihed with error(s): [My OldOperation Error]."

    or if no errors:

        "My OldOperation: finsihed with no errors."

    - parameter operation: the `OldOperation` that finished.
    - parameter errors: an array of `ErrorType`, not that these will be printed out.
    */
    public func didFinishOperation(operation: OldOperation, errors: [ErrorType]) {
        let detail = errors.count > 0 ? "error(s): \(errors)" : "no errors"
        log("\(operation.operationName): did finish with \(detail).")
    }

    private func log(message: String) {
        dispatch_async(queue) {
            self.logger(message: message)
        }
    }
}
