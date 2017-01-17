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

    func test__procedure_did_cancel_called_after_cancelled() {
        var observerCalled = false
        procedure.addDidCancelBlockObserver { procedure, _ in
            XCTAssertTrue(procedure.isCancelled)
            XCTAssertTrue(procedure.procedureDidCancelCalled)
            observerCalled = true
        }
        procedure.cancel()
        wait(for: procedure)
        XCTAssertTrue(observerCalled)
    }

    func test__procedured_cancelled_before_running_is_not_set_to_finished_until_started() {

        let didCancelCalled = DispatchSemaphore(value: 0)
        procedure.addDidCancelBlockObserver { _, _ in
            didCancelCalled.signal()
        }
        procedure.cancel()

        XCTAssertTrue(procedure.isCancelled)
        XCTAssertFalse(procedure.didExecute)
        XCTAssertFalse(procedure.procedureWillFinishCalled)
        XCTAssertFalse(procedure.procedureDidFinishCalled)
        XCTAssertFalse(procedure.isFinished)

        XCTAssertEqual(didCancelCalled.wait(timeout: .now() + 1.0), DispatchTimeoutResult.success)

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

    func test__procedure_cancelled_then_finished_from_within_execute() {

        class TestCancelFinishFromExecuteProcedure: Procedure {
            var didCancel = Protector((false, false))
            let error = TestError()
            override func execute() {
                cancel()
                finish(withError: error)
            }
            override func procedureDidCancel(withErrors: [Error]) {
                didCancel.overwrite(with: (true, isFinished))
            }
        }

        let special = TestCancelFinishFromExecuteProcedure()

        wait(for: special)

        XCTAssertTrue(special.didCancel.access.0)
        XCTAssertFalse(special.didCancel.access.1)  // isFinished should be false when the didcancel observers run
        XCTAssertTrue(special.isCancelled)
        XCTAssertTrue(special.isFinished)
    }

    func test__procedure_cancelled_then_finished_async_during_execute() {

        class TestCancelFinishAsyncFromExecuteProcedure: Procedure {
            var didCancel = Protector(false)
            override func execute() {
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.global().async { [unowned self] in
                    self.cancel()
                    self.finish()
                    semaphore.signal()
                }
                semaphore.wait()
            }
            override func procedureDidCancel(withErrors: [Error]) {
                didCancel.overwrite(with: true)
            }
        }

        let special = TestCancelFinishAsyncFromExecuteProcedure()

        wait(for: special)

        XCTAssertTrue(special.didCancel.access)
        XCTAssertTrue(special.isCancelled)
        XCTAssertTrue(special.isFinished)
    }

    func test__procedure_finished_then_cancelled_from_within_execute() {

        class TestFinishCancelFromExecuteProcedure: Procedure {
            var didCancel = Protector(false)
            override func execute() {
                finish()
                cancel()
            }
            override func procedureDidCancel(withErrors: [Error]) {
                didCancel.overwrite(with: true)
            }
        }

        let special = TestFinishCancelFromExecuteProcedure()

        wait(for: special)

        XCTAssertTrue(special.isFinished)
        XCTAssertFalse(special.didCancel.access)
        XCTAssertFalse(special.isCancelled)
    }

    func test__procedure_finished_then_cancelled_async_during_execute() {

        class TestFinishCancelAsyncFromExecuteProcedure: Procedure {
            var didCancel = Protector(false)
            override func execute() {
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.global().async { [unowned self] in
                    self.finish()
                    self.cancel()
                    semaphore.signal()
                }
                semaphore.wait()
            }
            override func procedureDidCancel(withErrors: [Error]) {
                didCancel.overwrite(with: true)
            }
        }

        let special = TestFinishCancelAsyncFromExecuteProcedure()

        wait(for: special)

        XCTAssertTrue(special.isFinished)
        XCTAssertFalse(special.didCancel.access)
        XCTAssertFalse(special.isCancelled)
    }

    func test__cancel_from_didcancel_observer_is_ignored() {

        enum ShouldNotHappen: Error {
            case CancelledFromWithinDidCancel
        }
        procedure.addDidCancelBlockObserver { procedure, error in
            procedure.cancel(withError: ShouldNotHappen.CancelledFromWithinDidCancel)
        }

        procedure.cancel()
        wait(for: procedure)
        XCTAssertProcedureCancelledWithoutErrors(procedure)
    }

    func test__cancel_from_willfinish_observer_is_ignored() {

        enum ShouldNotHappen: Error {
            case CancelledFromWithinWillFinish
        }
        procedure.addWillFinishBlockObserver { procedure, error, _ in
            procedure.cancel(withError: ShouldNotHappen.CancelledFromWithinWillFinish)
        }

        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
    }
}
