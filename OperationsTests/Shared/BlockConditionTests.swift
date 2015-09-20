//
//  BlockConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class BlockConditionTests: OperationTests {

    func test__operation_with_successful_block_condition_finishes() {

        let operation = TestOperation()
        operation.addCondition(BlockCondition { true })

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
    }

    func test__operation_with_unsuccess_block_condition_errors() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation()
        operation.addCondition(BlockCondition { false })

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            receivedErrors = errors
            expectation.fulfill()
        }))

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)
        if let error = receivedErrors[0] as? BlockCondition.Error {
            XCTAssertTrue(error == BlockCondition.Error.BlockConditionFailed)
        }
        else {
            XCTFail("No error message was observed")
        }
    }


}
