//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class CancelGroupStressTests: StressTestCase {

    func test__group_cancel() {

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let group = TestGroup(operations: TestProcedure(delay: 0))
            group.addDidFinishBlockObserver { _, _ in
                batch.incrementCounter(named: "finished", withBarrier: true)
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: group)
            group.cancel()
        }
    }

    override func ended(batch: BatchProtocol) {
        XCTAssertEqual(batch.counter(named: "finished"), batch.size)
    }
}

class GroupCancelAndAddOperationStressTests: StressTestCase {

    final class TestGroupWhichAddsOperationsAfterSuperInit: Group {
        let operationsToAddOnExecute: [Operation]

        init(operations: [Operation] = [TestProcedure(delay: 0)], operationsToAddOnExecute: [Operation] = [TestProcedure(delay: 0)]) {
            self.operationsToAddOnExecute = operationsToAddOnExecute
            super.init(operations: [])
            name = "TestGroupWhichAddsOperationsAfterSuperInit"
            add(children: operations) // add operations during init, after super.init
        }

        override func execute() {
            add(children: operationsToAddOnExecute) // add operations during execute
            super.execute()
        }
    }

    func test__group_cancel_and_add() {

        stress { batch, _ in
            batch.dispatchGroup.enter()
            let group = TestGroupWhichAddsOperationsAfterSuperInit()
            group.addDidFinishBlockObserver { _, _ in
                batch.incrementCounter(named: "finished", withBarrier: true)
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: group)
            group.cancel()
        }
    }

    override func ended(batch: BatchProtocol) {
        XCTAssertEqual(batch.counter(named: "finished"), batch.size)
    }
}

class GroupDoesNotFinishBeforeChildOperationsAreFinished: StressTestCase {

    func test__group_does_not_finish_before_child_operations_are_finished() {
        stress { batch, _ in
            batch.dispatchGroup.enter()

            let child1 = TestProcedure(delay: 0.05)
            let child2 = TestProcedure(delay: 0.05)
            let group = Group(operations: child1, child2)

            group.addDidFinishBlockObserver { _, _ in
                if child1.isFinished {
                    batch.incrementCounter(named: "child 1 finished", withBarrier: true)
                }
                if child2.isFinished {
                    batch.incrementCounter(named: "child 2 finished", withBarrier: true)
                }
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: group)
            group.cancel()
        }
    }

    override func ended(batch: BatchProtocol) {
        XCTAssertEqual(batch.counter(named: "child 1 finished"), batch.size)
        XCTAssertEqual(batch.counter(named: "child 2 finished"), batch.size)
    }
}
