//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class NegatedConditionTests: ProcedureKitTestCase {

    func test__procedure_with_negated_successful_condition_fails() {
        procedure.add(condition: NegatedCondition(TrueCondition()))
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 1)
    }

    func test__procedure_with_negated_failed_condition_succeeds() {
        procedure.add(condition: NegatedCondition(FalseCondition()))
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__procedure_with_negated_ignored_condition_succeeds() {
        procedure.add(condition: NegatedCondition(IgnoredCondition(FalseCondition())))
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__negated_condition_name() {
        let negated = NegatedCondition(FalseCondition())
        XCTAssertEqual(negated.name, "Not<FalseCondition>")
    }
}
