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

        let expectation = self.expectation(withDescription: "Test: \(#function)")
        var didExecuteBlock: Bool = false
        let operation = Operations.BlockOperation {
            didExecuteBlock = true
            expectation.fulfill()
        }
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__that_block_operation_with_no_block_finishes_immediately() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        let operation = Operations.BlockOperation()
        addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)
        XCTAssertTrue(operation.isFinished)
    }

    func test__that_block_operation_does_not_execute_if_cancelled_before_ready() {
        var blockDidRun = 0

        let delay = DelayOperation(interval: 2)

        let block = Operations.BlockOperation { (continuation: Operations.BlockOperation.ContinuationBlockType) in
            blockDidRun += 2
            continuation(error: nil)
        }

        let blockToCancel = Operations.BlockOperation { (continuation: Operations.BlockOperation.ContinuationBlockType) in
            blockDidRun += 1
            continuation(error: nil)
        }

        addCompletionBlockToTestOperation(block, withExpectation: expectation(withDescription: "Test: \(#function)"))

        block.addDependency(delay)
        blockToCancel.addDependency(delay)

        runOperations(delay, block, blockToCancel)
        blockToCancel.cancel()
        waitForExpectations(withTimeout: 3, handler: nil)
        
        XCTAssertEqual(blockDidRun, 2)
    }
}

