//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class MapProcedureTests: ProcedureKitTestCase {

    func test__requirement_is_mapped_to_result() {
        let timesTwo = MapProcedure<Int, Int> { return $0 * 2 }
        timesTwo.requirement = 2
        wait(for: timesTwo)
        XCTAssertEqual(timesTwo.result, 4)
    }
}

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
}
