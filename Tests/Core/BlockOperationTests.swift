//
//  BlockOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 17/04/2016.
//
//

import XCTest
@testable import Operations

class BlockOperationTests: OperationTests {

    func test__that_block_in_block_operation_executes() {

        let expectation = expectationWithDescription("Test: \(#function)")
        var didExecuteBlock: Bool = false
        let operation = BlockOperation {
            didExecuteBlock = true
            expectation.fulfill()
        }
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__that_block_operation_with_no_block_finishes_immediately() {
        let expectation = expectationWithDescription("Test: \(#function)")
        let operation = BlockOperation()
        addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
    }

    func test__that_block_operation_does_not_execute_if_cancelled_before_ready() {
        var blockDidRun = 0

        let delay = DelayOperation(interval: 2)

        let block = BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
            blockDidRun += 2
            continuation(error: nil)
        }

        let blockToCancel = BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
            blockDidRun += 1
            continuation(error: nil)
        }

        addCompletionBlockToTestOperation(block, withExpectation: expectationWithDescription("Test: \(#function)"))

        block.addDependency(delay)
        blockToCancel.addDependency(delay)

        runOperations(delay, block, blockToCancel)
        blockToCancel.cancel()
        waitForExpectationsWithTimeout(3, handler: nil)
        
        XCTAssertEqual(blockDidRun, 2)
    }
}

