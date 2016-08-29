//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class GroupStressTests: ProcedureKitTestCase {

    func test__group_cancel() {

        stress { batch, iteration, dispatchGroup in
            dispatchGroup.enter()

            let group = TestGroup(operations: TestProcedure(delay: 0))
            group.addDidFinishBlockObserver { _, _ in
                let newValue = iteration.counter.increment_barrier()
                if newValue == 1 {
                    dispatchGroup.leave()
                }
            }
            batch.queue.add(operation: group)
            group.cancel()
        }
    }
}
