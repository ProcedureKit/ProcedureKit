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
        addObserver(WillCancelObserver { [unowned self] operation, errors in
            if operation === self {
                if errors.isEmpty {
                    self.target.cancel()
                }
                else {
                    self.target.cancelWithError(OperationError.ParentOperationCancelledWithErrors(errors))
                }
            }
        })
    }

    public override func execute() {
        target.log.severity = log.severity
        produceOperation(target)
    }
}
