//
//  GroupOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import XCTest
import Operations

class GroupOperationTests: OperationTests {

    func createGroupOperations() -> [TestOperation] {
        return (0..<3).map { _ in TestOperation() }
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
}

