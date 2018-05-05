//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/**
 Compose another `Procedure` subclass to ignore any errors that it generates.
*/
final public class IgnoreErrorsProcedure<T: Procedure>: ComposedProcedure<T> {

    public convenience init(_ composed: T) {
        self.init(operation: composed)
    }

    override public init(dispatchQueue: DispatchQueue? = nil, operation: T) {
        super.init(dispatchQueue: dispatchQueue, operation: operation)
    }

    override public func child(_ child: Procedure, willFinishWithErrors errors: [Error]) {
        assert(!child.isFinished, "child(_:willFinishWithErrors:) called with a child that has already finished")

        // No errors - call the super.
        guard !errors.isEmpty else {
            super.child(child, willFinishWithErrors: errors)
            return
        }

        // If there are errors, just log them.
        log.warning(message: "Ignoring \(errors.count) errors from \(child.operationName).")
    }
}
