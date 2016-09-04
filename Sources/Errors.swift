//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public struct Errors {

    public struct ProgrammingError: Error {
        public let reason: String
    }

    public struct Cancelled: Error {
        let errors: [Error]
    }


}
