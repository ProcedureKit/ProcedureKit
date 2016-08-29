//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

extension Collection where Iterator.Element: Operation {

    var operationsAndProcedures: ([Operation], [Procedure]) {
        return reduce(([], [])) { result, element in
            var (operations, procedures) = result
            if let procedure = element as? Procedure {
                procedures.append(procedure)
            }
            else {
                operations.append(element)
            }
            return (operations, procedures)
        }
    }

    func forEachProcedure(body: (Procedure) throws -> Void) rethrows {
        try forEach {
            if let procedure = $0 as? Procedure {
                try body(procedure)
            }
        }
    }
}
