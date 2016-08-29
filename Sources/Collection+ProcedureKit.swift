//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

extension Collection where Iterator.Element: Operation {

    internal var operationsAndProcedures: ([Operation], [Procedure]) {
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

    internal var userIntent: Procedure.UserIntent {
        get {
            let (_, procedures) = operationsAndProcedures
            return procedures.map { $0.userIntent }.max { $0.rawValue < $1.rawValue } ?? .none
        }
    }

    internal func forEachProcedure(body: (Procedure) throws -> Void) rethrows {
        try forEach {
            if let procedure = $0 as? Procedure {
                try body(procedure)
            }
        }
    }
}
