//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class GroupStressTests: GroupTestCase {

    func test__group_cancel() {

        stress(atLevel: .low) { batch, iteration, dispatchGroup in
            dispatchGroup.enter()
            let group = TestGroup(operations: TestProcedure(delay: 0))
            group.addDidFinishBlockObserver { _, _ in
                dispatchGroup.leave()
            }
            queue.add(operation: group)
            group.cancel()
        }
    }
}
