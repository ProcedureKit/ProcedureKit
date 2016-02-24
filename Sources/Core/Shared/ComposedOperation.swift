//
//  ComposedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class ComposedOperation<T: NSOperation>: Operation, OperationDidFinishObserver {

    public let target: Operation
    public var operation: T

    public convenience init(_ op: T) {
        self.init(operation: op)
    }

    init(operation op: T) {
        target = op as? Operation ?? GroupOperation(operations: [op])
        operation = op
        super.init()
        name = "Composed Operation"
        target.name = "Composed <\(T.self)>"
        target.addObserver(self)
    }

    public override func cancel() {
        target.cancel()
        operation.cancel()
        super.cancel()
    }

    public override func execute() {
        target.log.severity = log.severity
        produceOperation(target)
    }

    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        if operation === target {
            finish(errors)
        }
    }
}

