//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class AsyncBlockProcedureTests: ProcedureKitTestCase {

    func test__block_executes() {
        var blockDidExecute = false
        let block = AsyncBlockProcedure { finishWithResult in
            blockDidExecute = true
            finishWithResult(success)
        }
        wait(for: block)
        XCTAssertTrue(blockDidExecute)
    }

    func test__block_does_not_execute_if_cancelled() {
        var blockDidExecute = false
        let block = AsyncBlockProcedure { finishWithResult in
            blockDidExecute = true
            finishWithResult(success)
        }
        block.cancel()
        wait(for: block)
        XCTAssertFalse(blockDidExecute)
    }

    func test__block_which_finishes_with_error() {
        let block = AsyncBlockProcedure { finishWithResult in
            finishWithResult(.failure(TestError()))
        }
        wait(for: block)
        XCTAssertProcedureFinishedWithErrors(block, count: 1)
    }

    func test__block_did_execute_observer() {
        let block = AsyncBlockProcedure { $0(success) }
        var didExecuteBlockObserver = false
        block.addDidExecuteBlockObserver { procedure in
            didExecuteBlockObserver = true
        }
        wait(for: block)
        XCTAssertTrue(didExecuteBlockObserver)
    }
}
