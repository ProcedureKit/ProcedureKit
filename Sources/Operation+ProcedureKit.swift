//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public extension Operation {

    /**
     Returns a non-optional `String` to use as the name
     of an Operation. If the `name` property is not
     set, this resorts to the class description.
     */
    var operationName: String {
        return name ?? "Unnamed Operation"
    }

    func addCompletionBlock(block: @escaping () -> Void) {
        if let existing = completionBlock {
            completionBlock = {
                existing()
                block()
            }
        }
        else {
            completionBlock = block
        }
    }
}
