//
//  ComposedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 28/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class ComposedOperation<T: NSOperation>: GroupOperation {

    public var operation: T

    public convenience init(_ composed: T) {
        self.init(operation: composed)
    }

    init(operation composed: T) {
        self.operation = composed
        super.init(operations: [composed])
        name = "Composed <\(T.self)>"
        addObserver(WillCancelObserver { [unowned self] operation, errors in
            guard operation === self else { return }
            if !errors.isEmpty, let op =  self.operation as? Operation {
                op.cancelWithError(OperationError.ParentOperationCancelledWithErrors(errors))
            }
            else {
                self.operation.cancel()
            }
        })
    }
}
