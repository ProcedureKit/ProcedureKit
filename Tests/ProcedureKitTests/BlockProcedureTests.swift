//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
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
        PKAssertProcedureFinished(block)
    }

    func test__block_does_not_execute_if_cancelled() {
        var blockDidExecute = false
        let block = BlockProcedure { blockDidExecute = true }
        block.cancel()
        wait(for: block)
        XCTAssertFalse(blockDidExecute)
        PKAssertProcedureCancelled(block)
    }

    func test__block_which_throws_finishes_with_error() {
        let error = TestError()
        let block = BlockProcedure { throw error }
        wait(for: block)
        PKAssertProcedureFinishedWithError(block, error)
    }

    func test__block_did_execute_observer() {
        let block = BlockProcedure { /* does nothing */ }
        var didExecuteBlockObserver = false
        block.addDidExecuteBlockObserver { procedure in
            didExecuteBlockObserver = true
        }
        wait(for: block)
        XCTAssertTrue(didExecuteBlockObserver)
        PKAssertProcedureFinished(block)
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
        PKAssertProcedureFinished(block)
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
        PKAssertProcedureCancelled(block)
    }

    func test__block_which_finishes_with_error() {
        let error = TestError()
        let block = AsyncBlockProcedure { finishWithResult in
            self.dispatchQueue.async {
                finishWithResult(.failure(error))
            }
        }
        wait(for: block)
        PKAssertProcedureFinishedWithError(block, error)
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
        PKAssertProcedureFinished(block)
    }
}

class UIBlockProcedureTests: ProcedureKitTestCase {

    func test__block_executes() {
        var blockDidExecute = false
        let block = UIBlockProcedure {
            blockDidExecute = true
        }
        wait(for: block)
        XCTAssertTrue(blockDidExecute)
        PKAssertProcedureFinished(block)
    }

    func test__didFinishObserversCalled() {
        var blockDidExecute = false
        var observerDidExecute = false
        let block = UIBlockProcedure {
            blockDidExecute = true
        }
        block.addDidFinishBlockObserver { (_, error) in
            observerDidExecute = true
        }
        var dependencyDidExecute = false
        let dep = BlockProcedure {
            dependencyDidExecute = true
        }
        wait(for: block, dep)
        XCTAssertTrue(blockDidExecute)
        XCTAssertTrue(observerDidExecute)
        XCTAssertTrue(dependencyDidExecute)
        PKAssertProcedureFinished(block)
        PKAssertProcedureFinished(dep)
    }
}
