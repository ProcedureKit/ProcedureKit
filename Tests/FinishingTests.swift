//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class FinishingTests: ProcedureKitTestCase {

    func test__procedure_will_finish_is_called() {
        wait(for: procedure)
        XCTAssertTrue(procedure.procedureWillFinishCalled)
    }

    func test__procedure_did_finish_is_called() {
        wait(for: procedure)
        XCTAssertTrue(procedure.procedureDidFinishCalled)
    }

    func test__procedure_with_disabled_automatic_finishing_manual_cancel_and_finish_on_will_execute_does_not_result_in_invalid_state_transition_to_executing() {

        class TestOperation_CancelsAndManuallyFinishesOnWillExecute: Procedure {
            override init() {
                super.init(disableAutomaticFinishing: true) // <-- disableAutomaticFinishing
                addWillExecuteBlockObserver { [weak self] _ in
                    guard let strongSelf = self else { return }
                    strongSelf.cancel()
                    strongSelf.finish() // manually finishes after cancelling
                }
            }
            override func execute() {
                finish()
            }
        }

        let special = TestOperation_CancelsAndManuallyFinishesOnWillExecute()

        wait(for: special)

        // Test initially failed with:
        // assertion failed: Attempting to perform illegal cyclic state transition, Finished -> Executing for operation: Unnamed Operation #UUID.: file Operations/Sources/Core/Shared/Operation.swift, line 399
        // This will crash the test execution if it happens.
    }
}
