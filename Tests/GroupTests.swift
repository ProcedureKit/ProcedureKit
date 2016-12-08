//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class GroupTests: GroupTestCase {

    // MARK: - Basic Group Tests

    func test__group_has_user_intent_set_from_input_operations() {
        let child = TestProcedure()
        child.userIntent = .initiated
        group = TestGroupProcedure(operations: [child, TestProcedure(), BlockOperation { }])
        XCTAssertEqual(group.userIntent, .initiated)
    }

    func test__group_sets_user_intent_on_children() {
        let child1 = TestProcedure()
        child1.userIntent = .initiated
        let child2 = TestProcedure()
        let child3 = BlockOperation { }
        group = TestGroupProcedure(operations: [child1, child2, child3])
        group.userIntent = .sideEffect

        XCTAssertEqual(child1.userIntent, .sideEffect)
        XCTAssertEqual(child2.userIntent, .sideEffect)
        XCTAssertEqual(child3.qualityOfService, .userInitiated)
    }

    // MARK: - Execution

    func test__group_children_are_executed() {
        wait(for: group)

        XCTAssertTrue(group.isFinished)
        for child in group.children {
            XCTAssertTrue(child.isFinished)
        }
        for testProcedures in group.children.flatMap({ $0 as? TestProcedure }) {
            XCTAssertTrue(testProcedures.didExecute)
        }
    }

    func test__group_adding_operation_to_running_group() {
        let semaphore = DispatchSemaphore(value: 0)
        group.add(child: BlockOperation {
            // prevent the Group from finishing before an extra child is added
            // after execute
            semaphore.wait()
        })
        let extra = TestProcedure(name: "Extra child")

        checkAfterDidExecute(procedure: group) {
            $0.add(child: extra)
            semaphore.signal()
        }

        XCTAssertTrue(group.isFinished)
        XCTAssertTrue(extra.didExecute)
    }

    func test__group_only_adds_initial_operations_to_children_property_once() {
        wait(for: group)
        XCTAssertEqual(group.children, children)
    }

    func test__group_will_add_child_observer_is_called() {
        var blockCalledWith: (GroupProcedure, Operation)? = nil
        group = TestGroupProcedure(operations: [children[0]])
        group.addWillAddOperationBlockObserver { group, child in
            blockCalledWith = (group, child)
        }
        wait(for: group)
        guard let (observedGroup, observedChild) = blockCalledWith else { XCTFail("Observer not called"); return }
        XCTAssertEqual(observedGroup, group)
        XCTAssertEqual(observedChild, children[0])
    }

    func test__group_did_add_child_observer_is_called() {
        var blockCalledWith: (GroupProcedure, Operation)? = nil
        group = TestGroupProcedure(operations: [children[0]])
        group.addDidAddOperationBlockObserver { group, child in
            blockCalledWith = (group, child)
        }
        wait(for: group)
        guard let (observedGroup, observedChild) = blockCalledWith else { XCTFail("Observer not called"); return }
        XCTAssertEqual(observedGroup, group)
        XCTAssertEqual(observedChild, children[0])
    }

    func test__group_is_not_suspended_at_start() {
        XCTAssertFalse(group.isSuspended)
    }

    func test__group_suspended_before_execute() {
        let child = children[0]
        group = TestGroupProcedure(operations: [child])
        group.isSuspended = true

        let childWillExecuteDispatchGroup = DispatchGroup()
        childWillExecuteDispatchGroup.enter()
        child.addWillExecuteBlockObserver { _ in
            childWillExecuteDispatchGroup.leave()
        }

        checkAfterDidExecute(procedure: group) { group in

            XCTAssertTrue(group.didExecute)
            XCTAssertTrue(group.isExecuting)

            XCTAssertNotEqual(childWillExecuteDispatchGroup.wait(timeout: DispatchTime.now() + 0.005), .success, "Child executed when group was suspended")

            XCTAssertFalse(child.isFinished)
            XCTAssertFalse(group.isFinished)

            group.isSuspended = false
        }

        XCTAssertTrue(child.isFinished)
        XCTAssertTrue(group.isFinished)
    }

    func test__group_suspended_during_execution_does_not_run_additional_children() {
        let child1 = children[0]
        let child2 = children[1]
        child2.add(dependency: child1)
        group = TestGroupProcedure(operations: [child1, child2])

        child1.addWillFinishBlockObserver { (_, _) in
            self.group.isSuspended = true
        }
        addCompletionBlockTo(procedure: child1)
        run(operation: group)

        waitForExpectations(timeout: 3)
        usleep(500)

        XCTAssertTrue(group.isSuspended)
        XCTAssertFalse(group.isFinished)
        XCTAssertTrue(child1.isFinished)
        XCTAssertFalse(child2.isFinished)

        addCompletionBlockTo(procedure: group)
        group.isSuspended = false
        waitForExpectations(timeout: 3)

        XCTAssertFalse(group.isSuspended)
        XCTAssertTrue(group.isFinished)
        XCTAssertTrue(child2.isFinished)
    }

    // MARK: - Error Tests

    func test__group_exits_correctly_when_child_errors() {
        children = createTestProcedures(shouldError: true)
        group = TestGroupProcedure(operations: children)

        wait(for: group)

        XCTAssertEqual(group.errors.count, children.count)
    }

    func test__group_exits_correctly_when_child_group_finishes_with_errors() {
        children = createTestProcedures(shouldError: true)
        let child = TestGroupProcedure(operations: children); child.name = "Child Group"
        group = TestGroupProcedure(operations: child)

        wait(for: group)
        XCTAssertEqual(child.errors.count, children.count)
        XCTAssertEqual(group.errors.count, 5)
    }

    // MARK: - Cancellation Tests

    func test__group_cancels_children() {
        group.cancel()
        for child in group.children {
            XCTAssertTrue(child.isCancelled)
        }
    }

    func test__group_cancels_children_when_running() {
        checkAfterDidExecute(procedure: group) { $0.cancel() }
        XCTAssertTrue(group.isCancelled)
    }

    func test__group_execute_is_called_when_cancelled_before_running() {
        group.cancel()
        XCTAssertFalse(group.didExecute)

        wait(for: group)

        XCTAssertTrue(group.isCancelled)
        XCTAssertTrue(group.didExecute)
        XCTAssertTrue(group.isFinished)
    }

    func test__group_cancel_with_errors_does_not_collect_errors_sent_to_children() {
        check(procedure: group) { $0.cancel(withError: TestError()) }
        XCTAssertProcedureCancelledWithErrors(group, count: 1)
    }

    func test__group_additional_children_are_cancelled_if_group_is_cancelled() {
        group.cancel()
        let additionalChild = TestProcedure(delay: 0)
        group.add(child: additionalChild)
        XCTAssertTrue(additionalChild.isCancelled)
    }

    // MARK: - Finishing Tests

    func test__group_does_not_finish_before_all_children_finish() {
        var didFinishBlockObserverWasCalled = false
        group.addWillFinishBlockObserver { group, _ in
            didFinishBlockObserverWasCalled = true
            for child in group.children {
                XCTAssertTrue(child.isFinished)
            }
        }
        wait(for: group)
        XCTAssertTrue(group.isFinished)
        XCTAssertTrue(didFinishBlockObserverWasCalled)
    }

    // MARK: - ProcedureQueue Delegate Tests

    func test__group_ignores_delegate_calls_from_other_queues() {
        // The base GroupProcedure ProcedureQueue delegate implementation should ignore
        // other queues' delegate callbacks, or various bad things may happen, including:
        //  - Observers may be improperly notified
        //  - The Group may wait to finish on non-child operations

        group = TestGroupProcedure(operations: [])
        let otherQueue = ProcedureQueue()
        otherQueue.delegate = group

        var observerCalledFromGroupDelegate = false
        group.addWillAddOperationBlockObserver { group, child in
            observerCalledFromGroupDelegate = true
        }
        group.addDidAddOperationBlockObserver { group, child in
            observerCalledFromGroupDelegate = true
        }

        // Adding a TestProcedure to the otherQueue should not result in the Group's
        // Will/DidAddChild observers being called, nor should the Group wait
        // on the other queue's TestProcedure to finish.
        otherQueue.add(operation: TestProcedure())
        wait(for: group)
        XCTAssertTrue(group.isFinished)
        XCTAssertFalse(observerCalledFromGroupDelegate)
    }

    // MARK: - Child Produce Operation Tests

    func test__child_can_produce_operation() {
        let producedOperation = TestProcedure(name: "ProducedOperation", delay: 0.05)
        let child = TestProcedure(name: "Child", delay: 0.05, produced: producedOperation)
        addCompletionBlockTo(procedure: child)
        addCompletionBlockTo(procedure: producedOperation)
        group = TestGroupProcedure(operations: child)
        wait(for: group)
        XCTAssertProcedureFinishedWithoutErrors(group)
        XCTAssertProcedureFinishedWithoutErrors(child)
        XCTAssertProcedureFinishedWithoutErrors(producedOperation)
    }

    func test__group_does_not_finish_before_child_produced_operations_are_finished() {
        let child = TestProcedure(name: "Child", delay: 0.01)
        let childProducedOperation = TestProcedure(name: "ChildProducedOperation", delay: 0.2)
        childProducedOperation.add(dependency: child)
        let group = GroupProcedure(operations: [child])
        child.addWillExecuteBlockObserver { operation in
            try! operation.produce(operation: childProducedOperation)
        }
        wait(for: group)
        XCTAssertProcedureFinishedWithoutErrors(group)
        XCTAssertProcedureFinishedWithoutErrors(childProducedOperation)
    }

    func test__group_children_array_receives_operations_produced_by_children() {
        let child = TestProcedure(name: "Child", delay: 0.01)
        let childProducedOperation = TestProcedure(name: "ChildProducedOperation", delay: 0.2)
        childProducedOperation.add(dependency: child)
        let group = GroupProcedure(operations: [child])
        child.addWillExecuteBlockObserver { operation in
            try! operation.produce(operation: childProducedOperation)
        }
        wait(for: group)
        XCTAssertEqual(group.children.count, 2)
        XCTAssertTrue(group.children.contains(child))
        XCTAssertTrue(group.children.contains(childProducedOperation))
    }

    // MARK: - Condition Tests
}

class GroupConcurrencyTests: GroupConcurrencyTestCase {

    // MARK: - MaxConcurrentOperationCount Tests

    func test__group_maxConcurrentOperationCount_1() {
        let children: Int = 3
        let delayMicroseconds: useconds_t = 500000 // 0.5 seconds
        let timeout: TimeInterval = 4
        let results = concurrencyTestGroup(children: children, withDelayMicroseconds: delayMicroseconds, withTimeout: timeout,
            withConfigureBlock: { (group) in
                group.maxConcurrentOperationCount = 1
            },
            withExpectations: Expectations(
                checkMinimumDetected: 1,
                checkMaximumDetected: 1,
                checkAllProceduresFinished: true,
                checkMinimumDuration: TimeInterval(useconds_t(children) * delayMicroseconds) / 1000000.0
            )
        )
        XCTAssertEqual(results.group.maxConcurrentOperationCount, 1)
    }

    func test__group_operation_maxConcurrentOperationCount_2() {
        let children: Int = 3
        let delayMicroseconds: useconds_t = 500000 // 0.5 seconds
        let timeout: TimeInterval = 3
        let results = concurrencyTestGroup(children: children, withDelayMicroseconds: delayMicroseconds, withTimeout: timeout,
            withConfigureBlock: { (group) in
                group.maxConcurrentOperationCount = 2
            },
            withExpectations: Expectations(
                checkMinimumDetected: 1,
                checkMaximumDetected: 2,
                checkAllProceduresFinished: true
            )
        )
        XCTAssertEqual(results.group.maxConcurrentOperationCount, 2)
    }
}

