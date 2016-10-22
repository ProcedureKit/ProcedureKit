//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class CancelBlockProcedureStessTests: StressTestCase {

    func test__cancel_block_procedure() {

        stress(level: .custom(10, 5_000)) { batch, _ in
            batch.dispatchGroup.enter()
            let block = BlockProcedure { }
            block.addDidCancelBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: block)
            block.cancel()
        }
    }
}
