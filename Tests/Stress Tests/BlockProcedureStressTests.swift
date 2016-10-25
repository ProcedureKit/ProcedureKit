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
            batch.dispatchGroup.enter() // enter once for cancel
            batch.dispatchGroup.enter() // enter once for finish
            let semaphore = DispatchSemaphore(value: 0)
            let block = BlockProcedure {
                // prevent the BlockProcedure from finishing before it is cancelled
                semaphore.wait()
            }
            block.addDidCancelBlockObserver { _, _ in
                batch.dispatchGroup.leave() // leave once for cancel
                semaphore.signal()
            }
            block.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave() // leave once for finish
            }
            batch.queue.add(operation: block)
            block.cancel()
        }
    }
}
