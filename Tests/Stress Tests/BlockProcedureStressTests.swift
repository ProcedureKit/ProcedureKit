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

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let block = BlockProcedure { usleep(500) }
            block.addDidCancelBlockObserver { procedure, errors in
                batch.incrementCounter(named: "cancelled", withBarrier: false)
            }
            block.addDidFinishBlockObserver { procedure, errors in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: block)
            block.cancel()
        }
    }

    override func ended(batch: BatchProtocol) {
        XCTAssertEqual(batch.counter(named: "cancelled"), batch.size)
    }
}
