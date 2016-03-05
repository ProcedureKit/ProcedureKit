//
//  GroupOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import XCTest
@testable import Operations

class GroupOperationTests: OperationTests {

    func createGroupOperations() -> [TestOperation] {
        return (0..<3).map { _ in TestOperation() }
    }

    func test__cancel_group_operation() {

        let operations = createGroupOperations()
        let operation = GroupOperation(operations: operations)
        operation.cancel()

        for op in operations {
            XCTAssertTrue(op.cancelled)
        }
    }

    func test__group_operations_are_performed_in_order() {
        let group = createGroupOperations()
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = GroupOperation(operations: group)
        operation.addCompletionBlock {
            expectation.fulfill()
        }

        runOperation(operation)
        waitForExpectationsWithTimeout(4, handler: nil)
        XCTAssertTrue(operation.finished)
        for op in group {
            XCTAssertTrue(op.didExecute)
        }
    }

    func test__adding_operation_to_running_group() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = GroupOperation(operations: TestOperation(), TestOperation())
        operation.addCompletionBlock {
            expectation.fulfill()
        }
        let extra = TestOperation()
        runOperation(operation)
        operation.addOperation(extra)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(extra.didExecute)
    }

    func test__that_group_conditions_are_evaluated_before_the_child_operations() {
        let operations: [TestOperation] = (0..<3).map { i in
            let op = TestOperation()
            op.addCondition(BlockCondition { true })
            let exp = self.expectationWithDescription("Group Operation, child \(i): \(__FUNCTION__)")
            self.addCompletionBlockToTestOperation(op, withExpectation: exp)
            return op
        }

        let group = GroupOperation(operations: operations)
        addCompletionBlockToTestOperation(group, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))

        runOperation(group)
        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(group.finished)
    }

    func test__that_adding_multiple_operations_to_a_group_works() {
        let group = GroupOperation(operations: [])
        let operations: [TestOperation] = (0..<3).map { _ in TestOperation() }
        group.addOperations(operations)

        addCompletionBlockToTestOperation(group, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(group)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(group.finished)
        XCTAssertTrue(operations[0].didExecute)
        XCTAssertTrue(operations[1].didExecute)
        XCTAssertTrue(operations[2].didExecute)
    }

    func test__group_operation_exits_correctly_when_child_errors() {

        let numberOfOperations = 10_000
        let operations = (0..<numberOfOperations).map { i -> Operation in
            let block = BlockOperation { (completion: BlockOperation.ContinuationBlockType) in
                let error = NSError(domain: "me.danthorpe.Operations.Tests", code: -9_999, userInfo: nil)
                completion(error: error)
            }
            block.name = "Block \(i)"
            return block
        }

        let group = GroupOperation(operations: operations)

        let waiter = BlockOperation { }
        waiter.addDependency(group)

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        addCompletionBlockToTestOperation(waiter, withExpectation: expectation)
        runOperations(group, waiter)
        waitForExpectationsWithTimeout(5.0, handler: nil)

        XCTAssertTrue(group.finished)
        XCTAssertEqual(group.aggregateErrors.count, numberOfOperations)
    }

    func test__group_operation_exits_correctly_when_child_group_finishes_with_errors() {
        let operation = TestOperation(error: TestOperation.Error.SimulatedError)
        let child = GroupOperation(operations: [operation])
        let group = GroupOperation(operations: [child])

        let waiter = BlockOperation { }
        waiter.addDependency(group)

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        addCompletionBlockToTestOperation(waiter, withExpectation: expectation)
        runOperations(group, waiter)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(group.finished)
        XCTAssertEqual(group.aggregateErrors.count, 1)
    }

    func test__group_operation_exits_correctly_when_multiple_nested_groups_finish_with_errors() {
        let operation = TestOperation(error: TestOperation.Error.SimulatedError)
        let child1 = GroupOperation(operations: [operation])
        let child = GroupOperation(operations: [child1])
        let group = GroupOperation(operations: [child])

        let waiter = BlockOperation { }
        waiter.addDependency(group)

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        addCompletionBlockToTestOperation(waiter, withExpectation: expectation)
        runOperations(group, waiter)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(group.finished)
        XCTAssertEqual(group.aggregateErrors.count, 1)
    }
}
