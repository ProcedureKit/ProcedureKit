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
                addWillExecuteBlockObserver { [weak self] _, _ in
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

    func test__cancelled_procedure_finish_called_before_execute_eventually_finishes() {
        // NOTE: Calling finish() prior to a Procedure being executed by a queue
        //       should be safe to do *after* the Procedure is cancelled.
        //
        //       Internally, the Procedure should delay processing the finish
        //       until it is started by the queue (which, if it is cancelled,
        //       should not be waiting on any dependencies).

        XCTAssertFalse(procedure.isFinished)
        procedure.cancel()
        XCTAssertTrue(procedure.isCancelled)
        XCTAssertFalse(procedure.isFinished)
        procedure.finish(withErrors: [TestError()])
        XCTAssertFalse(procedure.isFinished)
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(procedure, count: 1)
    }

    func test__cancelled_procedure_finish_called_before_execute_only_first_finish_succeeds() {
        XCTAssertFalse(procedure.isFinished)
        procedure.cancel()
        XCTAssertTrue(procedure.isCancelled)
        XCTAssertFalse(procedure.isFinished)
        procedure.finish(withErrors: [TestError()])
        XCTAssertFalse(procedure.isFinished)
        // calling finish a second time should be ignored - only the first call should succeed
        procedure.finish(withErrors: [])
        XCTAssertFalse(procedure.isFinished)
        wait(for: procedure)
        // the procedure should be cancelled with 1 error - if there is no error, the second call to finish
        // incorrectly succeeded
        XCTAssertProcedureCancelledWithErrors(procedure, count: 1)
    }

    func test__cancelled_procedure_finish_before_execute_from_didcancel_observer() {
        class FinishesFromDidCancelProcedure: Procedure {
            override init() {
                super.init()
                addDidCancelBlockObserver { procedure, _ in
                    procedure.finish(withError: TestError())
                }
            }
            override func execute() {
                finish()
            }
        }
        weak var expDidCancel = expectation(description: "did cancel")
        let procedure = FinishesFromDidCancelProcedure()
        procedure.addDidCancelBlockObserver { procedure, _ in
            DispatchQueue.main.async {
                expDidCancel?.fulfill()
            }
        }
        procedure.cancel()
        waitForExpectations(timeout: 3)
        XCTAssertTrue(procedure.isCancelled)
        XCTAssertFalse(procedure.isFinished)
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(procedure, count: 1)
    }

    func test__procedure_finish_from_willexecute_observer() {
        procedure.addWillExecuteBlockObserver { procedure, _ in
            procedure.finish(withErrors: [TestError()])
        }
        wait(for: procedure)
        XCTAssertTrue(procedure.isFinished)
        XCTAssertFalse(procedure.didExecute)
        XCTAssertFalse(procedure.isCancelled)
        XCTAssertTrue(procedure.failed)
    }

    func test__procedure_finish_after_cancel_from_willexecute_observer() {
        procedure.addWillExecuteBlockObserver { procedure, _ in
            procedure.cancel()
            procedure.finish(withErrors: [TestError()])
        }
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(procedure)
        XCTAssertFalse(procedure.didExecute)
    }

    func test__finish_from_willfinish_observer_is_ignored() {

        enum ShouldNotHappen: Error {
            case FinishedFromWithinWillFinish
        }
        procedure.addWillFinishBlockObserver { (procedure, error, _) in
            procedure.finish(withError: ShouldNotHappen.FinishedFromWithinWillFinish)
        }

        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
    }
}

class FinishingConcurrencyTests: ProcedureKitTestCase {

    func test__finish_on_other_thread_synchronously_from_execute() {
        // This test should not result in deadlock.

        class TestFinishSyncFromExecuteProcedure: Procedure {
            override init() {
                super.init()
                self.name = "TestFinishSyncFromExecuteProcedure"
            }
            override func execute() {
                guard !Thread.current.isMainThread else { fatalError("Procedure's execute() is on main thread.") }
                DispatchQueue.main.sync {
                    assert(Thread.current.isMainThread)
                    finish()
                }
            }
        }

        let procedure = TestFinishSyncFromExecuteProcedure()
        wait(for: procedure, withTimeout: 3, handler: { (error) in
            XCTAssertNil(error)
        })
        XCTAssertTrue(procedure.isFinished)
    }
}
