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

    public convenience init(_ composed: T) {
        self.init(operation: composed)
    }

    init(operation composed: T) {
        self.target = composed as? Operation ?? GroupOperation(operations: [composed])
        self.operation = composed
        super.init()
        name = "Composed Operation"
        target.name = target.name ?? "Composed <\(T.self)>"
        target.addObserver(DidFinishObserver { [unowned self] _, errors in
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
