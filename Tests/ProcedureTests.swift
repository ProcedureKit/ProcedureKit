//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class QueueDelegateTests: ProcedureKitTestCase {

    func test__delegate__is_notified_when_procedure_starts() {
        wait(for: procedure)
        XCTAssertNotNil(delegate.procedureQueueWillAddOperation)
        XCTAssertNotNil(delegate.procedureQueueDidFinishOperation)
    }
}

class ExecutionTest: ProcedureKitTestCase {

    func test__procedure_executes() {
        wait(for: procedure)
        XCTAssertTrue(procedure.didExecute)
    }

    func test__procedure_add_multiple_completion_blocks() {
        weak var expect = expectation(description: "Test: \(#function), \(UUID())")

        var completionBlockOneDidRun = 0
        procedure.addCompletionBlock {
            completionBlockOneDidRun += 1
        }

        var completionBlockTwoDidRun = 0
        procedure.addCompletionBlock {
            completionBlockTwoDidRun += 1
        }

        var finalCompletionBlockDidRun = 0
        procedure.addCompletionBlock {
            finalCompletionBlockDidRun += 1
            DispatchQueue.main.async {
                guard let expect = expect else { print("Test: \(#function): Finished expectation after timeout"); return }
                expect.fulfill()
            }
        }

        wait(for: procedure)

        XCTAssertEqual(completionBlockOneDidRun, 1)
        XCTAssertEqual(completionBlockTwoDidRun, 1)
        XCTAssertEqual(finalCompletionBlockDidRun, 1)

    }

}

class CancellationTests: ProcedureKitTestCase {

    func test__procedure_cancel_with_nil_error() {
        procedure.cancel(withError: nil)
        XCTAssertFalse(procedure.didExecute)
        XCTAssertTrue(procedure.isCancelled)
        XCTAssertFalse(procedure.failed)
    }

    func test__procedure_cancel_with_error() {
        procedure.cancel(withError: TestProcedure.SimulatedError())
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
}
