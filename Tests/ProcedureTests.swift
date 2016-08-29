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

class ExecutionTests: ProcedureKitTestCase {

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

class UserIntentTests: ProcedureKitTestCase {

    func test__getting_user_intent_default_background() {
        XCTAssertEqual(procedure.userIntent, .none)
    }

    func test__set_user_intent__initiated() {
        procedure.userIntent = .initiated
        XCTAssertEqual(procedure.qualityOfService, .userInitiated)
    }

    func test__set_user_intent__side_effect() {
        procedure.userIntent = .sideEffect
        XCTAssertEqual(procedure.qualityOfService, .userInitiated)
    }

    func test__set_user_intent__initiated_then_background() {
        procedure.userIntent = .initiated
        procedure.userIntent = .none
        XCTAssertEqual(procedure.qualityOfService, .default)
    }

    func test__user_intent__equality() {
        XCTAssertNotEqual(Procedure.UserIntent.initiated, Procedure.UserIntent.sideEffect)
    }
}
