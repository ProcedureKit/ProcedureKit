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

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
    }

    func test__operation_with_unsuccessful_block_condition_errors() {

        weak var expectation = expectationWithDescription("Test: \(#function)")
        let operation = TestOperation()
        operation.addCondition(BlockCondition { false })

        var receivedErrors = [ErrorType]()
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
            dispatch_async(Queue.Main.queue, {
                guard let expectation = expectation else { print("Test: \(#function): Finished expectation after timeout"); return }
                expectation.fulfill()
            })
        })

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

    func test__operation_with_block_which_throws_condition_errors() {
        weak var expectation = expectationWithDescription("Test: \(#function)")

        let operation = TestOperation()
        operation.addCondition(BlockCondition { throw TestOperation.Error.SimulatedError })

        var receivedErrors = [ErrorType]()
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
            dispatch_async(Queue.Main.queue, {
                guard let expectation = expectation else { print("Test: \(#function): Finished expectation after timeout"); return }
                expectation.fulfill()
            })
        })

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)
        if let error = receivedErrors[0] as? TestOperation.Error {
            XCTAssertTrue(error == TestOperation.Error.SimulatedError)
        }
        else {
            XCTFail("No error message was observed")
        }
    }
}
