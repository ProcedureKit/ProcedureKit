//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class GroupCancelStressTests: StressTestCase {

    override func ended(batch: BatchProtocol) {
        XCTAssertEqual(Int(batch.counter.count), batch.size)
    }

    func test__group_cancel() {

        stress(level: .low) { batch, iteration in
            batch.dispatchGroup.enter()
            let group = TestGroup(operations: TestProcedure(delay: 0))
            group.addDidFinishBlockObserver { _, _ in
                let _ = batch.counter.barrierIncrement()
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: group)
            group.cancel()
        }
    }
}
