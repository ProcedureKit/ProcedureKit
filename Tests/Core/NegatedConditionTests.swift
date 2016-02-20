//
//  NegatedConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class NegatedConditionTests: OperationTests {

    func test__operation_with_successful_block_condition_fails() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation()
        operation.addCondition(NegatedCondition(BlockCondition { true }))

        var receivedErrors = [ErrorType]()
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
            expectation.fulfill()
        })
        
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)
        XCTAssertEqual(receivedErrors.count, 1)
        if let error = receivedErrors.first as? NegatedConditionError {
            XCTAssertTrue(error == .ConditionSatisfied("Block Condition"))
        }
        else {
            XCTFail("No error message was observed")
        }
    }

    func test__operation_with_unsuccessful_block_condition_executes() {

        let operation = TestOperation()
        operation.addCondition(NegatedCondition(BlockCondition { false }))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }

    func test__negated_condition_name() {
        let condition = NegatedCondition(NoFailedDependenciesCondition())
        XCTAssertEqual(condition.name, "Not<No Cancelled Condition>")
    }

    func test__negated_condition_is_mutually_exclusive_when_nested_condition_is_mutually_exclusive() {
        let condition = NegatedCondition(MutuallyExclusive<String>())
        XCTAssertTrue(condition.isMutuallyExclusive)
    }

    func test__negated_condition_is_not_mutually_exclusive_when_nested_condition_is_not_mutually_exclusive() {
        let condition = NegatedCondition(NoFailedDependenciesCondition())
        XCTAssertFalse(condition.isMutuallyExclusive)
    }

}
