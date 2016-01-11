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
    public var creator: () -> T    
    public var operation: T

    public required init(@autoclosure(escaping) operation _creator: () -> T) {
        let op = _creator()
        creator = _creator
        target = op as? Operation ?? GroupOperation(operations: [op])
        operation = op
        super.init()
        name = "Composed Operation"
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

