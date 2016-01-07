//
//  ComposedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

internal protocol ComposedOperationType: class {
    typealias Composed: NSOperation
}

public class ComposedOperation<O: NSOperation>: Operation, OperationDidFinishObserver, ComposedOperationType {
    typealias Composed = O

    public let operation: O
    private var target: Operation? = nil

    public required init(_ compose: O) {
        operation = compose
        super.init()
    }

    public override func execute() {
        addOperation(operation as? Operation ?? GroupOperation(operations: [operation]))
    }

    internal func addOperation(operation: Operation) {
        target = operation
        operation.addObserver(self)
        produceOperation(operation)
    }

    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        if operation == target {
            finish(errors)
        }
    }
}

