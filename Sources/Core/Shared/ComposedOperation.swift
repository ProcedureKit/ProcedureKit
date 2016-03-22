//
//  ComposedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class ComposedOperation<T: NSOperation>: Operation {

    public let target: Operation
    public var operation: T

    public convenience init(_ op: T) {
        self.init(operation: op)
    }

    init(operation op: T) {
        self.target = op as? Operation ?? GroupOperation(operations: [op])
        self.operation = op
        super.init()
        name = "Composed Operation"
        target.name = target.name ?? "Composed <\(T.self)>"
        target.addObserver(DidFinishObserver {
            [unowned self] _, errors in
            self.finish(errors)
            })
    }

    public override func cancel() {
        operation.cancel()
        super.cancel()
    }

    public override func execute() {
        target.log.severity = log.severity
        produceOperation(target)
    }
}
