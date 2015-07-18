//
//  TimeoutObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

struct TimeoutObserver: OperationObserver {

    private let timeout: NSTimeInterval

    init(timeout: NSTimeInterval) {
        self.timeout = timeout
    }

    func operationDidStart(operation: Operation) {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout * Double(NSEC_PER_SEC)))

        dispatch_after(when, Queue.Default.queue) {
            if !operation.finished && !operation.cancelled {
                let error = OperationError.OperationTimedOut(self.timeout)
                operation.cancelWithError(error)
            }
        }
    }

    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        // no-op
    }

    func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        // no-op
    }
}



