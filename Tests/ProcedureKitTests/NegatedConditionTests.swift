//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class NegatedConditionTests: ProcedureKitTestCase {

    func test__procedure_with_negated_successful_condition_fails() {
        procedure.addCondition(NegatedCondition(TrueCondition()))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.conditionFailed())
    }

    func test__procedure_with_negated_failed_condition_succeeds() {
        procedure.addCondition(NegatedCondition(FalseCondition()))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__procedure_with_negated_ignored_condition_succeeds() {
        procedure.addCondition(NegatedCondition(IgnoredCondition(FalseCondition())))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__negated_condition_name() {
        let negated = NegatedCondition(FalseCondition())
        XCTAssertEqual(negated.name, "Not<FalseCondition>")
    }
}
