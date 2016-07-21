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

        let expectation = self.expectation(description: "Test: \(#function)")
        var didExecuteBlock: Bool = false
        let operation = OldBlockOperation {
            didExecuteBlock = true
            expectation.fulfill()
        }
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__that_block_operation_with_no_block_finishes_immediately() {
        let expectation = self.expectation(description: "Test: \(#function)")
        let operation = OldBlockOperation()
        addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertTrue(operation.isFinished)
    }

    func test__that_block_operation_does_not_execute_if_cancelled_before_ready() {
        var blockDidRun = 0

        let delay = DelayOperation(interval: 2)

        let block = OldBlockOperation { (continuation: OldBlockOperation.ContinuationBlockType) in
            blockDidRun += 2
            continuation(error: nil)
        }

        let blockToCancel = OldBlockOperation { (continuation: OldBlockOperation.ContinuationBlockType) in
            blockDidRun += 1
            continuation(error: nil)
        }

        addCompletionBlockToTestOperation(block, withExpectation: expectation(description: "Test: \(#function)"))

        block.addDependency(delay)
        blockToCancel.addDependency(delay)

        runOperations(delay, block, blockToCancel)
        blockToCancel.cancel()
        waitForExpectations(timeout: 3, handler: nil)
        
        XCTAssertEqual(blockDidRun, 2)
    }
}

