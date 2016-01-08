//
//  ComposedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class ComposedOperation<T: NSOperation>: Operation, OperationDidFinishObserver {

    public let operation: T
    public let target: Operation

    public required init(operation op: T) {
        target = op as? Operation ?? GroupOperation(operations: [op])
        operation = op
        super.init()
        name = "Composed Operation<\(operation.dynamicType)>"
        target.addObserver(self)
    }

    public override func cancel() {
        operation.cancel()
        super.cancel()
    }

    public override func execute() {
        produceOperation(target)
    }

    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        if operation == target {
            finish(errors)
        }
    }
}

