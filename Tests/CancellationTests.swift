//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit


class CancellationTests: ProcedureKitTestCase {

    func test__procedure_cancel_with_nil_error() {
        procedure.cancel(withError: nil)
        XCTAssertFalse(procedure.didExecute)
        XCTAssertTrue(procedure.isCancelled)
        XCTAssertFalse(procedure.failed)
    }

    func test__procedure_cancel_with_error() {
        procedure.cancel(withError: TestError())
        XCTAssertFalse(procedure.didExecute)
        XCTAssertTrue(procedure.isCancelled)
        XCTAssertTrue(procedure.failed)
    }

    func test__procedure_will_cancel_called_before_cancelled() {
        var observerCalled = false
        procedure.addWillCancelBlockObserver { procedure, _ in
            XCTAssertTrue(procedure.procedureWillCancelCalled)
            XCTAssertFalse(procedure.isCancelled)
            XCTAssertFalse(procedure.procedureDidCancelCalled)
            observerCalled = true
        }
        procedure.cancel()
        wait(for: procedure)
        XCTAssertTrue(observerCalled)
    }

    func test__procedure_did_cancel_called_after_cancelled() {
        var observerCalled = false
        procedure.addDidCancelBlockObserver { procedure, _ in
            XCTAssertTrue(procedure.procedureWillCancelCalled)
            XCTAssertTrue(procedure.isCancelled)
            XCTAssertTrue(procedure.procedureDidCancelCalled)
            observerCalled = true
        }
        procedure.cancel()
        wait(for: procedure)
        XCTAssertTrue(observerCalled)
    }

    func test__procedured_cancelled_before_running_is_not_set_to_finished_until_started() {

        procedure.cancel()

        XCTAssertTrue(procedure.isCancelled)
        XCTAssertTrue(procedure.procedureDidCancelCalled)
        XCTAssertFalse(procedure.didExecute)
        XCTAssertFalse(procedure.procedureWillFinishCalled)
        XCTAssertFalse(procedure.procedureDidFinishCalled)
        XCTAssertFalse(procedure.isFinished)

        wait(for: procedure)

        XCTAssertTrue(procedure.procedureDidFinishCalled)
        XCTAssertTrue(procedure.isFinished)
    }

    func test__procedure_with_disables_automatic_finishing_does_not_finish_automatically_when_cancelled() {

        class TestHandlesFinishOperation: Procedure {
            override init() {
                super.init(disableAutomaticFinishing: true)
            }

            override func execute() {
                // deliberately does not finish
            }
            
            func triggerFinish() {
                self.finish()
            }
        }

        let special = TestHandlesFinishOperation()

        let _ = addCompletionBlockTo(procedure: special)
        run(operation: special)

        special.cancel()

        XCTAssertTrue(special.isCancelled)
        XCTAssertFalse(special.isFinished)
        sleep(1)
        XCTAssertFalse(special.isFinished)

        special.triggerFinish()

        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertTrue(special.isFinished)
    }
}
