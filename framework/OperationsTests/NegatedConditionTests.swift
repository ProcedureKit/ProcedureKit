//
//  NegatedConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations

class NegatedConditionTests: OperationTests {

    func test__operation_with_successful_block_condition_fails() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation()
        operation.addCondition(NegatedCondition(BlockCondition { true }))

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver(finishHandler: { (_, errors) in
            receivedErrors = errors
            expectation.fulfill()
        }))
        
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.cancelled)
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

        runOperation(operation)
        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.cancelled)
    }


}
