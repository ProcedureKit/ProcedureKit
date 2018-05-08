//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class CancelBlockProcedureStessTests: StressTestCase {

    func test__cancel_block_procedure() {

        stress(level: .custom(10, 5_000)) { batch, _ in
            batch.dispatchGroup.enter() // enter once for cancel
            batch.dispatchGroup.enter() // enter once for finish
            let block = CancellableBlockProcedure { isCancelled in
                // prevent the BlockProcedure from finishing before it is cancelled
                while !isCancelled() {
                    usleep(10)
                }
            }
            block.addDidCancelBlockObserver { _, _ in
                batch.dispatchGroup.leave() // leave once for cancel
            }
            block.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave() // leave once for finish
            }
            batch.queue.add(operation: block)
            block.cancel()
        }
    }

    func test_cancel_or_finish_block_procedure() {

        // NOTE:
        // It is possible for a BlockProcedure to finish prior to the call to
        // `block.cancel()` (depending on timing) and thus not all of the
        // BlockProcedures created below may be effectively cancelled.
        // However, all of the BlockProcedures should finish.

        stress(level: .custom(10, 5_000)) { batch, _ in
            batch.dispatchGroup.enter()
            let block = BlockProcedure { }
            block.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: block)
            block.cancel()
        }
    }
}
