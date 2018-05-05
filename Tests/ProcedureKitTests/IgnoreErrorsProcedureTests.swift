//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class IgnoreErrorsProcedureTests: ProcedureKitTestCase {

    func test__procedure_which_errors_is_ignored() {

        let procedure = IgnoreErrorsProcedure(ResultProcedure { throw ProcedureKitError.unknown })
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
    }

    func test__procedure_which_does_not_error() {

        let procedure = IgnoreErrorsProcedure(ResultProcedure { "Hello" })
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
    }

    func test__procedure_output() {

        let procedure = IgnoreErrorsProcedure(ResultProcedure { "Hello" })
        wait(for: procedure)
        XCTAssertProcedureOutputSuccess(procedure, "Hello")       
    }
}

