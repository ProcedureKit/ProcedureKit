//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class BlockConditionTests: ProcedureKitTestCase {

    func test__procedure_with_successfull_block_finishes() {
        procedure.add(condition: BlockCondition { true })
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__procedure_with_unsuccessful_block_cancels_without_errors() {
        procedure.add(condition: BlockCondition { false })
        wait(for: procedure)
        XCTAssertProcedureCancelledWithoutErrors()
    }

    func test__procedure_with_throwing_block_cancels_with_error() {
        procedure.add(condition: BlockCondition { throw TestError() })
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 1)
    }
}

