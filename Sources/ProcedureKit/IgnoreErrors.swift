//
//  ProcedureKit
//
//  Copyright © 2016-2018 ProcedureKit. All rights reserved.
//

import Foundation

/**
 Compose another `Procedure` subclass to ignore any errors that it generates.
*/
final public class IgnoreErrorsProcedure<T: Procedure>: ComposedProcedure<T> {

    /// Override to supress errors from the composed procedure
    override public func child(_ child: Procedure, willFinishWithError error: Error?) {
        assert(!child.isFinished, "child(_:willFinishWithErrors:) called with a child that has already finished")

        // No errors - call the super.
        guard let e = error else {
            super.child(child, willFinishWithError: error)
            return
        }

        // If there are errors, just log them.
        log.warning.message("Ignoring \(e) errors from \(child.operationName).")
    }
}
