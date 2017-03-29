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
            let group = TestGroupProcedure(operations: TestProcedure(delay: 0))
            group.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: group)
            group.cancel()
        }
    }
}

class GroupCancelAndAddOperationStressTests: StressTestCase {

    final class TestGroupProcedureWhichAddsOperationsAfterSuperInit: GroupProcedure {
        let operationsToAddOnExecute: [Operation]

        init(operations: [Operation] = [TestProcedure(delay: 0)], operationsToAddOnExecute: [Operation] = [TestProcedure(delay: 0)]) {
            self.operationsToAddOnExecute = operationsToAddOnExecute
            super.init(operations: [])
            name = "TestGroupProcedureWhichAddsOperationsAfterSuperInit"
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
            let group = TestGroupProcedureWhichAddsOperationsAfterSuperInit()
            group.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: group)
            group.cancel()
        }
    }
}

class GroupDoesNotFinishBeforeChildOperationsAreFinished: StressTestCase {

    func test__group_does_not_finish_before_child_operations_are_finished() {
        stress { batch, _ in
            batch.dispatchGroup.enter()

            let child1 = TestProcedure(delay: 0.004)
            let child2 = TestProcedure(delay: 0.006)
            let group = GroupProcedure(operations: child1, child2)

            group.addDidFinishBlockObserver { _, _ in
                if child1.isFinished {
                    batch.incrementCounter(named: "child 1 finished")
                }
                if child2.isFinished {
                    batch.incrementCounter(named: "child 2 finished")
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
        super.ended(batch: batch)
    }
}

class GroupCancellationHandlerConcurrencyTest: StressTestCase {

    func test__cancelled_group_no_concurrent_events() {

        stress(level: StressLevel.custom(2, 1000)) { batch, iteration in
            batch.dispatchGroup.enter()
            let group = EventConcurrencyTrackingGroupProcedure(operations: [TestProcedure(), TestProcedure()])
            group.addDidFinishBlockObserver(block: { (group, error) in
                DispatchQueue.main.async {
                    self.XCTAssertProcedureNoConcurrentEvents(group)
                    batch.dispatchGroup.leave()
                }
            })
            batch.queue.add(operation: group)
            group.cancel()
        }
    }

    func test__group_simultaneous_child_finish_no_concurrent_events() {

        stress(level: StressLevel.custom(2, 50)) { batch, iteration in
            batch.dispatchGroup.enter()
            let children = (0..<3).map { i -> Procedure in
                let procedure = BlockProcedure { }
                procedure.name = "Child: \(i)"
                return procedure
            }
            let group = EventConcurrencyTrackingGroupProcedure(operations: children)
            group.addDidFinishBlockObserver(block: { (group, error) in
                DispatchQueue.main.async {
                    self.XCTAssertProcedureNoConcurrentEvents(group)
                    batch.dispatchGroup.leave()
                }
            })
            batch.queue.add(operation: group)
        }
    }

    func test__group_add_child_no_concurrent_events() {

        stress(level: StressLevel.custom(2, 50)) { batch, iteration in
            batch.dispatchGroup.enter()
            let additionalChildren = (1..<3).map { i -> Procedure in
                let procedure = BlockProcedure { }
                procedure.name = "Child: \(i)"
                return procedure
            }
            let group = EventConcurrencyTrackingGroupProcedure(operations: [])
            let initialChild = BlockProcedure {
                group.add(children: additionalChildren)
            }
            initialChild.name = "Child: 0 (initial)"
            group.add(child: initialChild)
            group.addDidFinishBlockObserver(block: { (group, error) in
                DispatchQueue.main.async {
                    self.XCTAssertProcedureNoConcurrentEvents(group)
                    batch.dispatchGroup.leave()
                }
            })
            batch.queue.add(operation: group)
        }
    }
}
