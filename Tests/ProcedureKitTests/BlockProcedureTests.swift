//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class BlockProcedureTests: ProcedureKitTestCase {

    func test__block_executes() {
        var blockDidExecute = false
        let block = BlockProcedure { blockDidExecute = true }
        wait(for: block)
        XCTAssertTrue(blockDidExecute)
    }

    func test__block_does_not_execute_if_cancelled() {
        var blockDidExecute = false
        let block = BlockProcedure { blockDidExecute = true }
        block.cancel()
        wait(for: block)
        XCTAssertFalse(blockDidExecute)
    }

    func test__block_which_throws_finishes_with_error() {
        let block = BlockProcedure { throw TestError() }
        wait(for: block)
        XCTAssertProcedureFinishedWithErrors(block, count: 1)
    }

    func test__block_did_execute_observer() {
        let block = BlockProcedure { /* does nothing */ }
        var didExecuteBlockObserver = false
        block.addDidExecuteBlockObserver { procedure in
            didExecuteBlockObserver = true
        }
        wait(for: block)
        XCTAssertTrue(didExecuteBlockObserver)
    }
}

class AsyncBlockProcedureTests: ProcedureKitTestCase {

    var dispatchQueue: DispatchQueue!

    override func setUp() {
        super.setUp()
        dispatchQueue = DispatchQueue.initiated
    }

    override func tearDown() {
        dispatchQueue = nil
        super.tearDown()
    }

    func test__block_executes() {
        var blockDidExecute = false
        let block = AsyncBlockProcedure { finishWithResult in
            self.dispatchQueue.async {
                blockDidExecute = true
                finishWithResult(success)
            }
        }
        wait(for: block)
        XCTAssertTrue(blockDidExecute)
    }

    func test__block_does_not_execute_if_cancelled() {
        var blockDidExecute = false
        let block = AsyncBlockProcedure { finishWithResult in
            self.dispatchQueue.async {
                blockDidExecute = true
                finishWithResult(success)
            }
        }
        block.cancel()
        wait(for: block)
        XCTAssertFalse(blockDidExecute)
    }

    func test__block_which_finishes_with_error() {
        let block = AsyncBlockProcedure { finishWithResult in
            self.dispatchQueue.async {
                finishWithResult(.failure(TestError()))
            }
        }
        wait(for: block)
        XCTAssertProcedureFinishedWithErrors(block, count: 1)
    }

    func test__block_did_execute_observer() {
        let block = AsyncBlockProcedure { finishWithResult in
            self.dispatchQueue.async { finishWithResult(success) }
        }
        var didExecuteBlockObserver = false
        block.addDidExecuteBlockObserver { procedure in
            didExecuteBlockObserver = true
        }
        wait(for: block)
        XCTAssertTrue(didExecuteBlockObserver)
    }
}

