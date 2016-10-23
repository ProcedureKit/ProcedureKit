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

    func test__enqueue_a_sequence_of_operations() {
        addCompletionBlockTo(procedure: procedure, withExpectationDescription: "\(#function)")
        [procedure].enqueue()
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__enqueue_a_sequence_of_operations_deallocates_queue() {
        addCompletionBlockTo(procedure: procedure, withExpectationDescription: "\(#function)")
        var nilQueue: ProcedureQueue! = ProcedureQueue()
        weak var weakQueue = nilQueue
        [procedure].enqueue(on: weakQueue!)
        nilQueue = nil
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertNil(nilQueue)
        XCTAssertNil(weakQueue)
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
        XCTAssertNotEqual(UserIntent.initiated, UserIntent.sideEffect)
    }
}

class ProcedureTests: ProcedureKitTestCase {

    func test__procedure_name() {
        let block = BlockProcedure { }
        XCTAssertEqual(block.name, "BlockProcedure")

        let group = GroupProcedure(operations: [])
        XCTAssertEqual(group.name, "GroupProcedure")
    }

    func test__identity_is_equatable() {
        let identity1 = procedure.identity
        let identity2 = procedure.identity
        XCTAssertEqual(identity1, identity2)
    }

    func test__identity_description() {
        XCTAssertTrue(procedure.identity.description.hasPrefix("TestProcedure #"))
        procedure.name = nil
        XCTAssertTrue(procedure.identity.description.hasPrefix("Unnamed Procedure #"))
    }
}

class DependencyTests: ProcedureKitTestCase {

    func test__operation_added_using_then_follows_receiver() {
        let another = TestProcedure()
        let operations = procedure.then(do: another)
        XCTAssertEqual(operations, [procedure, another])
        wait(for: procedure, another)
        XCTAssertLessThan(procedure.executedAt, another.executedAt)
    }

    func test__operation_added_using_then_via_closure_follows_receiver() {
        let another = TestProcedure()
        let operations = procedure.then { another }
        XCTAssertEqual(operations, [procedure, another])
        wait(for: procedure, another)
        XCTAssertLessThan(procedure.executedAt, another.executedAt)
    }

    func test__operation_added_using_then_via_closure_returning_nil() {
        XCTAssertEqual(procedure.then { nil }, [procedure])
    }

    func test__operation_added_using_then_via_closure_throwing_error() {
        do {
            let _ = try procedure.then { throw TestError() }
        }
        catch is TestError { }
        catch { XCTFail("Caught unexpected error.") }
    }

    func test__operation_added_to_array_using_then() {
        let one = TestProcedure()
        let two = TestProcedure(delay: 1)
        let another = TestProcedure()
        let all = [one, two, procedure].then(do: another)
        XCTAssertEqual(all.count, 4)
        wait(for: one, two, procedure, another)
        XCTAssertProcedureFinishedWithoutErrors(another)
        XCTAssertLessThan(one.executedAt, another.executedAt)
        XCTAssertLessThan(two.executedAt, another.executedAt)
        XCTAssertLessThan(procedure.executedAt, another.executedAt)
    }

    func test__operation_added_to_array_using_then_via_closure() {
        let one = TestProcedure()
        let two = TestProcedure(delay: 1)
        let another = TestProcedure()
        let all = [one, two, procedure].then { another }
        XCTAssertEqual(all.count, 4)
        wait(for: one, two, procedure, another)
        XCTAssertProcedureFinishedWithoutErrors(another)
        XCTAssertLessThan(one.executedAt, another.executedAt)
        XCTAssertLessThan(two.executedAt, another.executedAt)
        XCTAssertLessThan(procedure.executedAt, another.executedAt)
    }

    func test__operation_added_to_array_using_then_via_closure_throwing_error() {
        let one = TestProcedure()
        let two = TestProcedure(delay: 1)
        do {
            let _ = try [one, two, procedure].then { throw TestError() }
        }
        catch is TestError { }
        catch { XCTFail("Caught unexpected error.") }
    }

    func test__operation_added_to_array_using_then_via_closure_returning_nil() {
        let one = TestProcedure()
        let two = TestProcedure(delay: 1)
        let all = [one, two, procedure].then { nil }
        XCTAssertEqual(all.count, 3)
    }
}




