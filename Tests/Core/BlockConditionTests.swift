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

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)

        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertTrue(operation.isFinished)
    }

    func test__operation_with_unsuccessful_block_condition_errors() {

        let expectation = self.expectation(description: "Test: \(#function)")
        let operation = TestOperation()
        operation.addCondition(BlockCondition { false })

        var receivedErrors = [ErrorProtocol]()
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
            expectation.fulfill()
        })

        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertFalse(operation.didExecute)
        if let error = receivedErrors[0] as? BlockCondition.Error {
            XCTAssertTrue(error == BlockCondition.Error.blockConditionFailed)
        }
        else {
            XCTFail("No error message was observed")
        }
    }

    func test__operation_with_block_which_throws_condition_errors() {
        let expectation = self.expectation(description: "Test: \(#function)")

        let operation = TestOperation()
        operation.addCondition(BlockCondition { throw TestOperation.Error.simulatedError })

        var receivedErrors = [ErrorProtocol]()
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
            expectation.fulfill()
        })

        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertFalse(operation.didExecute)
        if let error = receivedErrors[0] as? TestOperation.Error {
            XCTAssertTrue(error == TestOperation.Error.simulatedError)
        }
        else {
            XCTFail("No error message was observed")
        }
    }
}
