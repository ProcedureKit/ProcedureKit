//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class GroupTests: GroupTestCase {

    // MARK: - Basic Group Tests

    func test__group_sets_name() {
       XCTAssertEqual(group.name, "Group")
    }

    // MARK: - Execution

    func test__group_is_not_suspended_at_start() {
        XCTAssertFalse(group.isSuspended)
    }

    func test__group_children_are_executed() {
        wait(for: group)

        XCTAssertTrue(group.isFinished)
        for child in group.children {
            XCTAssertTrue(child.isFinished)
        }
        for testProcedures in group.children.flatMap({ $0 as? TestProcedure }) {
            XCTAssertTrue(testProcedures.didExecute)
        }
    }

    func test__group_adding_operation_to_running_group() {
        let extra = TestProcedure(name: "Extra child")

        check(procedure: group) { $0.add(child: extra) }

        XCTAssertTrue(group.isFinished)
        XCTAssertTrue(extra.didExecute)
    }

    func test__group_only_adds_initial_operations_to_children_property_once() {
        wait(for: group)
        XCTAssertEqual(group.children, children)
    }

    // MARK: - Error Tests

    func test__group_exits_correctly_when_child_errors() {
        children = createTestProcedures(shouldError: true)
        group = TestGroup(operations: children)

        wait(for: group)

        XCTAssertEqual(group.errors.count, children.count)
    }

    func test__group_exits_correctly_when_child_group_finishes_with_errors() {
        children = createTestProcedures(shouldError: true)
        let child = TestGroup(operations: children); child.name = "Child Group"
        group = TestGroup(operations: child)

        wait(for: group)
        XCTAssertEqual(child.errors.count, children.count)
        XCTAssertEqual(group.errors.count, 5)
    }

    // MARK: - Cancellation Tests

    func test__group_cancels_children() {
        group.cancel()
        for child in group.children {
            XCTAssertTrue(child.isCancelled)
        }
    }

    func test__group_cancels_children_when_running() {
        check(procedure: group) { $0.cancel() }
        XCTAssertTrue(group.isCancelled)
    }

    func test__group_execute_is_called_when_cancelled_before_running() {
        group.cancel()
        XCTAssertFalse(group.didExecute)

        wait(for: group)

        XCTAssertTrue(group.isCancelled)
        XCTAssertTrue(group.didExecute)
        XCTAssertTrue(group.isFinished)
    }

    // MARK: - Finishing Tests

    // MARK: - Condition Tests
}
