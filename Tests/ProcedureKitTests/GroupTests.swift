//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class GroupTests: GroupTestCase {

    // MARK: - Execution

    func test__group_children_are_executed() {
        wait(for: group)

        XCTAssertTrue(group.isFinished)
        for child in group.children {
            XCTAssertTrue(child.isFinished)
        }
        for testProcedures in group.children.compactMap({ $0 as? TestProcedure }) {
            XCTAssertTrue(testProcedures.didExecute)
        }
    }

    func test__group_adding_operation_to_running_group() {
        let semaphore = DispatchSemaphore(value: 0)
        group.addChild(BlockOperation {
            // prevent the Group from finishing before an extra child is added
            // after execute
            semaphore.wait()
        })
        let extra = TestProcedure(name: "Extra child")

        checkAfterDidExecute(procedure: group) {
            $0.addChild(extra)
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
        child.addWillExecuteBlockObserver { _, _ in
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
        let groupDidFinish = DispatchGroup()
        let child1 = children[0]
        let child2 = children[1]
        child2.addDependency(child1)
        group = TestGroupProcedure(operations: [child1, child2])

        child1.addWillFinishBlockObserver { (_, _, _) in
            self.group.isSuspended = true
        }
        addCompletionBlockTo(procedure: child1)

        groupDidFinish.enter()
        group.addDidFinishBlockObserver { _, _ in
            groupDidFinish.leave()
        }
        run(operation: group)

        waitForExpectations(timeout: 3)
        usleep(500)

        XCTAssertTrue(group.isSuspended)
        XCTAssertFalse(group.isFinished)
        XCTAssertTrue(child1.isFinished)
        XCTAssertFalse(child2.isFinished)

        weak var expGroupDidFinish = expectation(description: "group did finish")
        group.isSuspended = false
        groupDidFinish.notify(queue: DispatchQueue.main, execute: {
            expGroupDidFinish?.fulfill()
        })
        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertFalse(group.isSuspended)
        XCTAssertTrue(group.isFinished)
        XCTAssertTrue(child2.isFinished)
    }

    func test__group_executes_on_procedure_queue_with_underlying_queue() {
        // If a GroupProcedure is added to a ProcedureQueue with an `underlyingQueue` configured,
        // the GroupProcedure's `execute()` function will run on the underlyingQueue.
        // This should succeed - previously, an assert failed in debug mode.

        class TestExecuteOnUnderlyingQueueGroupProcedure: GroupProcedure {
            public typealias Block = () -> Void
            private let block: Block

            public init(dispatchQueue underlyingQueue: DispatchQueue? = nil, operations: [Operation], executeCheckBlock: @escaping Block) {
                self.block = executeCheckBlock
                super.init(dispatchQueue: underlyingQueue, operations: operations)
            }
            open override func execute() {
                block()
                super.execute()
            }
        }

        let customDispatchQueueLabel = "run.kit.procedure.ProcedureKit.Tests.TestUnderlyingQueue"
        let customDispatchQueue = DispatchQueue(label: customDispatchQueueLabel, attributes: [.concurrent])
        let customScheduler = ProcedureKit.Scheduler(queue: customDispatchQueue)

        let procedureQueue = ProcedureQueue()
        procedureQueue.underlyingQueue = customDispatchQueue

        let didExecuteOnDesiredQueue = Protector(false)
        let child = TestProcedure()
        let group = TestExecuteOnUnderlyingQueueGroupProcedure(operations: [child]) {
            // inside execute()
            if customScheduler.isOnScheduledQueue {
                didExecuteOnDesiredQueue.overwrite(with: true)
            }
        }

        addCompletionBlockTo(procedure: group)
        procedureQueue.addOperation(group)
        waitForExpectations(timeout: 3)

        XCTAssertTrue(didExecuteOnDesiredQueue.access, "execute() did not execute on the desired underlyingQueue")
        PKAssertProcedureFinished(group)
        PKAssertProcedureFinished(child)
    }
}

// MARK: - Error Tests

extension GroupTests {

    func test__group_exits_correctly_when_child_errors() {
        children = createTestProcedures(shouldError: true)
        group = TestGroupProcedure(operations: children)

        wait(for: group)
        PKAssertProcedureFinished(group, withErrors: true)
        PKAssertGroupErrors(group, count: 5)
    }

    func test__group_exits_correctly_when_child_group_finishes_with_errors() {

        children = createTestProcedures(shouldError: true)
        let child = TestGroupProcedure(operations: children); child.name = "Child Group"
        group = TestGroupProcedure(operations: child)

        wait(for: group)
        PKAssertProcedureFinished(group, withErrors: true)
        PKAssertGroupErrors(group, count: 1)
        PKAssertGroupErrors(child, count: 5)
    }
}

// MARK: - Custom Error Handling Tests

class TestGroupChildWillFinishWithErrors: GroupProcedure {
    enum WillFinishWithErrorsAction {
        case none
        case callSuperWithError(Error?)
        case callSuperWithUnmodifiedInput
    }
    let receivedInput = Protector<[Procedure: Error?]>([:])
    let didReceiveDuplicate = Protector(false)
    let action: WillFinishWithErrorsAction
    init(operations: [Operation], action: WillFinishWithErrorsAction) {
        self.action = action
        super.init(operations: operations)
    }
    open override func child(_ child: Procedure, willFinishWithError error: Error?) {

        let hasExistingEntryForKey = receivedInput.write { ward in
            return ward.updateValue(error, forKey: child) != nil
        }
        if hasExistingEntryForKey {
            didReceiveDuplicate.overwrite(with: true)
        }

        // execute action
        switch action {
        case .callSuperWithError(let modifiedError):
            super.child(child, willFinishWithError: modifiedError)
        case .callSuperWithUnmodifiedInput:
            super.child(child, willFinishWithError: error)
        case .none: break
        }
    }
}

extension GroupTests {

    func test__group__transform_child_errors_block_receives_children_and_errors() {

        let receivedInput = Protector<[Procedure: Error?]>([:])
        let didReceiveDuplicate = Protector(false)
        children = createTestProcedures(shouldError: true)
        group = TestGroupProcedure(operations: children)
        group.transformChildErrorBlock = { (child, error) in
            let hasExistingEntryForKey = receivedInput.write { ward in
                return ward.updateValue(error, forKey: child) != nil
            }
            if hasExistingEntryForKey {
                didReceiveDuplicate.overwrite(with: true)
            }
        }

        wait(for: group)

        XCTAssertFalse(receivedInput.access.isEmpty, "transformChildErrorsBlock was not called")
        XCTAssertFalse(didReceiveDuplicate.access, "transformChildErrorsBlock received a duplicate call for the same child")

        for child in children {
            guard let error = receivedInput.access[child] else {
                XCTFail("transformChildErrorsBlock was not called for child: \(child)")
                continue
            }

            guard let blockError = error as? TestError else {
                XCTFail("Error provided to block was not a TestError")
                continue
            }
            guard let childError = child.error as? TestError else {
                XCTFail("Error in child was not a TestError")
                continue
            }
            XCTAssertEqual(blockError, childError)
        }

        PKAssertGroupErrors(group, count: children.count)
    }

    func test__group__transform_child_errors_block_removes_errors_from_child_willFinishWithError() {
        let modifiedError = TestError()
        children = createTestProcedures(shouldError: true)
        let group = TestGroupChildWillFinishWithErrors(operations: children, action: .callSuperWithUnmodifiedInput)
        let ignoredChild = children.first!
        group.transformChildErrorBlock = { (child, error) in
            if child === ignoredChild {
                error = modifiedError
            }
        }

        wait(for: group)

        XCTAssertNotNil(group.receivedInput.access, "child(_:willFinishWithError:) was not called")
        XCTAssertFalse(group.didReceiveDuplicate.access, "child(_:willFinishWithError:) received a duplicate call for the same child")
        for child in children {
            XCTAssertTrue(group.receivedInput.access.keys.contains(child), "child(_:willFinishWithError:) was not called for child: \(child)")
        }

        PKAssertGroupErrors(group, count: children.count)

        guard let receivedErrorsForIgnoredChild = group.receivedInput.access[ignoredChild] as? TestError else {
            XCTFail("child(_:willFinishWithError:) was not called for the ignoredChild")
            return
        }
        XCTAssertEqual(receivedErrorsForIgnoredChild, modifiedError)
    }

    func test__group__child_willFinishWithError_does_not_call_super() {
        children = createTestProcedures(shouldError: true)
        let group = TestGroupChildWillFinishWithErrors(operations: children, action: .none)

        wait(for: group)

        XCTAssertFalse(group.receivedInput.access.isEmpty, "child(_:willFinishWithError:) was not called")
        XCTAssertFalse(group.didReceiveDuplicate.access, "child(_:willFinishWithError:) received a duplicate call for the same child")
        for child in children {
            XCTAssertTrue(group.receivedInput.access.keys.contains(child), "child(_:willFinishWithError:) was not called for child: \(child)")
        }

        PKAssertGroupErrors(group, count: 0)
    }

    func test__group__child_willFinishWithError_calls_super_with_modified_errors() {

        children = createTestProcedures(shouldError: true)
        let group = TestGroupChildWillFinishWithErrors(operations: children, action: .callSuperWithError(nil))

        wait(for: group)

        XCTAssertFalse(group.receivedInput.access.isEmpty, "child(_:willFinishWithErrors:) was not called")
        XCTAssertFalse(group.didReceiveDuplicate.access, "child(_:willFinishWithErrors:) received a duplicate call for the same child")
        for child in children {
            XCTAssertTrue(group.receivedInput.access.keys.contains(child), "child(_:willFinishWithErrors:) was not called for child: \(child)")
        }

        PKAssertGroupErrors(group, count: 0)
    }
}

// MARK: - Cancellation Tests

extension GroupTests {

    func test__group_cancels_children() {
        weak var cancelledExpectation = expectation(description: "\(#function): group did cancel")
        group.addDidCancelBlockObserver { _, _ in
            DispatchQueue.main.async {
                cancelledExpectation?.fulfill()
            }
        }
        group.cancel()

        waitForExpectations(timeout: 2, handler: nil)

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
        let error = TestError()
        check(procedure: group) { $0.cancel(with: error) }
        PKAssertProcedureCancelledWithError(group, error)
    }

    func test__group_additional_children_are_cancelled_if_group_is_cancelled() {
        group.cancel()
        let additionalChild = TestProcedure(delay: 0)
        group.addChild(additionalChild)
        wait(for: group)
        XCTAssertTrue(additionalChild.isCancelled)
    }
}

// MARK: - Finishing Tests

extension GroupTests {

    func test__group_does_not_finish_before_all_children_finish() {
        var didFinishBlockObserverWasCalled = false
        group.addWillFinishBlockObserver { group, _, _ in
            didFinishBlockObserverWasCalled = true
            for child in group.children {
                XCTAssertTrue(child.isFinished)
            }
        }
        wait(for: group)
        XCTAssertTrue(group.isFinished)
        XCTAssertTrue(didFinishBlockObserverWasCalled)
    }

    func test__group_does_not_finish_before_child_operation_finishes() {
        // The Group should always wait on an Operation added to its internal queue.
        let child = BlockOperation {
            // wait for 1 second before finishing
            sleep(1)
        }
        let group = GroupProcedure(operations: [child])
        wait(for: group)
        XCTAssertTrue(child.isFinished)
    }

    // MARK: - ProcedureQueue Delegate Tests

    func test__group_ignores_delegate_calls_from_other_queues() {
        // The base GroupProcedure ProcedureQueue delegate implementation should ignore
        // other queues' delegate callbacks, or various bad things may happen, including:
        //  - Observers may be improperly notified
        //  - The Group may wait to finish on non-child operations

        group = TestGroupProcedure(operations: [])
        let otherQueue = ProcedureQueue()
        otherQueue.delegate = group.queueDelegate

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
        otherQueue.addOperation(TestProcedure())
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
        PKAssertProcedureFinished(group)
        PKAssertProcedureFinished(child)
        PKAssertProcedureFinished(producedOperation)
    }

    func test__group_does_not_finish_before_child_produced_operations_are_finished() {
        let child = TestProcedure(name: "Child", delay: 0.01)
        let childProducedOperation = TestProcedure(name: "ChildProducedOperation", delay: 0.2)
        childProducedOperation.addDependency(child)
        let group = GroupProcedure(operations: [child])
        child.addWillExecuteBlockObserver { operation, pendingExecute in
            try! operation.produce(operation: childProducedOperation, before: pendingExecute) // swiftlint:disable:this force_try
        }
        wait(for: group)
        PKAssertProcedureFinished(group)
        PKAssertProcedureFinished(childProducedOperation)
    }

    func test__group_children_array_receives_operations_produced_by_children() {
        let child = TestProcedure(name: "Child", delay: 0.01)
        let childProducedOperation = TestProcedure(name: "ChildProducedOperation", delay: 0.2)
        childProducedOperation.addDependency(child)
        let group = GroupProcedure(operations: [child])
        child.addWillExecuteBlockObserver { operation, pendingExecute in
            try! operation.produce(operation: childProducedOperation, before: pendingExecute) // swiftlint:disable:this force_try
        }
        wait(for: group)
        XCTAssertEqual(group.children.count, 2)
        XCTAssertTrue(group.children.contains(child))
        XCTAssertTrue(group.children.contains(childProducedOperation))
    }

    // MARK: - Child Operation Added Operation

    func test__group_child_operation_add_operation_subclass_via_operationqueue_current() {
        // The Group should always wait on an Operation added to its internal queue.
        //
        // NOTE: Previously, the first Operation subclass was waited on as side-effect
        // of the Group CanFinish handling, which picked up on the non-fishing operation
        // that was added to the children array of the Group.
        //
        // But the Operation added after the start of the Group was *not* properly waited on
        // because its willAddOperation event was not properly handled (for Operation - not
        // Procedure - subclasses).
        //
        let childProducedOperation = BlockOperation {
            // wait for 1 second before finishing
            sleep(1)
        }
        let child = BlockOperation {
            // Note: This is not recommended.
            guard let currentQueue = OperationQueue.current else { fatalError("Couldn't get current queue") }
            currentQueue.addOperation(childProducedOperation)
        }
        let group = GroupProcedure(operations: [child])
        wait(for: group)
        XCTAssertTrue(childProducedOperation.isFinished)
        XCTAssertEqual(group.children.count, 2)
        XCTAssertTrue(group.children.contains(child))
        XCTAssertTrue(group.children.contains(childProducedOperation))
    }

    // MARK: - Condition Tests

    class CheckChildEventsGroupProcedure: GroupProcedure {

        typealias ChildEventBlock = (GroupChildEvent, Operation) -> Void
        fileprivate var childEventBlock: ChildEventBlock

        enum GroupChildEvent {
            case willAddOperationObserver
            case didAddOperationObserver
            case groupWillAdd
            case childWillFinishWithError(Procedure, Error?)
            case transformChildErrorBlock(Procedure, Error?)
        }

        init(operations: [Operation], childEventBlock: @escaping ChildEventBlock = { _,_ in }) {
            self.childEventBlock = childEventBlock
            super.init(operations: operations)
            addWillAddOperationBlockObserver { group, child in
                group.childEventBlock(.willAddOperationObserver, child)
            }
            addDidAddOperationBlockObserver { group, child in
                group.childEventBlock(.didAddOperationObserver, child)
            }
            transformChildErrorBlock = { (child, error) in
                childEventBlock(.transformChildErrorBlock(child, error), child)
            }
        }

        // GroupProcedure Overrides
        open override func groupWillAdd(child: Operation) {
            childEventBlock(.groupWillAdd, child)
            super.groupWillAdd(child: child)
        }

        open override func child(_ child: Procedure, willFinishWithError error: Error?) {
            childEventBlock(.childWillFinishWithError(child, error), child)
            return super.child(child, willFinishWithError: error)
        }
    }

    class CheckForEvaluateConditionsGroupProcedure: CheckChildEventsGroupProcedure {
        var childEventsForEvaluateConditionsProcedure: [CheckChildEventsGroupProcedure.GroupChildEvent] {
            return _childEventsForEvaluateConditionsProcedure.access
        }

        private let _childEventsForEvaluateConditionsProcedure = Protector(Array<CheckChildEventsGroupProcedure.GroupChildEvent>())

        init(operations: [Operation]) {
            super.init(operations: operations)
            childEventBlock = { event, child in
                if child is Procedure.EvaluateConditions {
                    self._childEventsForEvaluateConditionsProcedure.append(event)
                }
            }
        }
    }

    func test__group_child_with_conditions_does_not_expose_evaluateconditions_procedure() {
        // Adding a child with conditions to a Group results in ProcedureQueue *also* adding an internal
        // "EvaluateConditions" Procedure to the Group's internal queue (to manage conditions).
        //
        // Ensure that this implementation detail is hidden from callbacks, observers, etc.

        let childWithFailingCondition = TestProcedure()
        childWithFailingCondition.addCondition(FalseCondition())
        let childWithSucceedingCondition = TestProcedure()
        childWithSucceedingCondition.addCondition(TrueCondition())

        let group = CheckForEvaluateConditionsGroupProcedure(operations: [childWithFailingCondition, childWithSucceedingCondition])
        wait(for: group)

        XCTAssertTrue(group.childEventsForEvaluateConditionsProcedure.isEmpty, "Received child event(s) for EvaluateConditions procedure: \(group.childEventsForEvaluateConditionsProcedure)")
        let evaluateConditionsChildren = group.children.filter { $0 is Procedure.EvaluateConditions }
        XCTAssertTrue(evaluateConditionsChildren.isEmpty, "EvaluateConditions should not appear in group.children")
    }
}

class GroupConcurrencyTests: GroupConcurrencyTestCase {

    // MARK: - MaxConcurrentOperationCount Tests

    func test__group_maxConcurrentOperationCount_1() {
        let children: Int = 3
        let delayMicroseconds: useconds_t = 200000 // 0.2 seconds
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
        let children: Int = 4
        let delayMicroseconds: useconds_t = 200000 // 0.2 seconds
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

class GroupEventConcurrencyTests: GroupTestCase {

    let expectedEndingEvents: [EventConcurrencyTrackingRegistrar.ProcedureEvent] = [.override_procedureWillFinish, .observer_willFinish, .override_procedureDidFinish, .observer_didFinish]
    var didFinishGroup: DispatchGroup!
    var baseObserver: ConcurrencyTrackingObserver!

    open override func setUp() {
        super.setUp()
        let didFinishGroup = DispatchGroup()
        self.didFinishGroup = didFinishGroup
        didFinishGroup.enter()
        baseObserver = ConcurrencyTrackingObserver() { procedure, event in
            assert(procedure is GroupProcedure)
            if event == .observer_didFinish {
                didFinishGroup.leave()
            }
        }
    }

    open override func tearDown() {
        didFinishGroup = nil
        baseObserver = nil
        super.tearDown()
    }

    private func waitForBaseObserverDidFinish(timeout: TimeInterval) {
        weak var expDidFinishObserverFired = expectation(description: "DidFinishObserver was fired")
        didFinishGroup.notify(queue: DispatchQueue.main) {
            expDidFinishObserverFired?.fulfill()
        }
        waitForExpectations(timeout: timeout)
    }

    func test_group_finish_no_concurrent_events() {
        let group = EventConcurrencyTrackingGroupProcedure(operations: children, registrar: EventConcurrencyTrackingRegistrar(recordHistory: true), baseObserver: baseObserver)
        wait(for: group)

        // Because Procedure signals isFinished KVO *prior* to calling DidFinish observers,
        // the above wait() may return before the ConcurrencyTrackingObserver is called to
        // record the DidFinish event.
        // Thus, wait for the Group's ConcurrencyTrackingObserver to receive the
        // .observer_DidFinish event.
        waitForBaseObserverDidFinish(timeout: 2)

        PKAssertProcedureFinished(group)
        PKAssertProcedureNoConcurrentEvents(group)

        let expectedBeginningEvents: [EventConcurrencyTrackingRegistrar.ProcedureEvent] = [.observer_didAttach, .observer_willExecute, .do_Execute]
        XCTAssertEqual(Array(group.concurrencyRegistrar.eventHistory?.prefix(expectedBeginningEvents.count) ?? []), expectedBeginningEvents)
        XCTAssertEqual(Array(group.concurrencyRegistrar.eventHistory?.suffix(expectedEndingEvents.count) ?? []), expectedEndingEvents)
    }

    func test_group_cancel_no_concurrent_events() {
        let group = EventConcurrencyTrackingGroupProcedure(operations: children, registrar: EventConcurrencyTrackingRegistrar(recordHistory: true), baseObserver: baseObserver)
        group.cancel()
        wait(for: group)

        // Because Procedure signals isFinished KVO *prior* to calling DidFinish observers,
        // the above wait() may return before the ConcurrencyTrackingObserver is called to
        // record the DidFinish event.
        // Thus, wait for the Group's ConcurrencyTrackingObserver to receive the
        // .observer_DidFinish event.
        waitForBaseObserverDidFinish(timeout: 2)

        PKAssertProcedureCancelled(group)
        PKAssertProcedureNoConcurrentEvents(group)

        let expectedBeginningEvents: [EventConcurrencyTrackingRegistrar.ProcedureEvent] = [.observer_didAttach, .override_procedureDidCancel, .observer_didCancel, .observer_willExecute, .do_Execute]
        XCTAssertEqual(Array(group.concurrencyRegistrar.eventHistory?.prefix(expectedBeginningEvents.count) ?? []), expectedBeginningEvents)
        XCTAssertEqual(Array(group.concurrencyRegistrar.eventHistory?.suffix(expectedEndingEvents.count) ?? []), expectedEndingEvents)
    }
}

class GroupAddChildConcurrencyTests: ProcedureKitTestCase {

    func test__group_add_child__prior_to_adding_group_to_queue() {
        let child = BlockProcedure { usleep(5000) }
        child.name = "ChildProcedure"
        addCompletionBlockTo(procedure: child)
        let group = EventConcurrencyTrackingGroupProcedure(operations: [], registrar: EventConcurrencyTrackingRegistrar(recordHistory: true))
        group.addChild(child)
        wait(for: group)
        PKAssertProcedureFinished(child)
        PKAssertProcedureFinished(group)
        PKAssertProcedureNoConcurrentEvents(group)
    }

    func test__group_add_child_operation__prior_to_adding_group_to_queue() {
        weak var expChildOperationFinished = expectation(description: "child did finish")
        let child = BlockOperation { usleep(5000) }
        child.name = "ChildOperation"
        let childFinishedOperation = BlockProcedure { DispatchQueue.main.async { expChildOperationFinished?.fulfill() } }
        childFinishedOperation.addDependency(child)
        let group = EventConcurrencyTrackingGroupProcedure(operations: [], registrar: EventConcurrencyTrackingRegistrar(recordHistory: true))
        group.addChild(child)
        wait(for: group, childFinishedOperation)
        XCTAssertTrue(child.isFinished)
        PKAssertProcedureFinished(group)
        PKAssertProcedureNoConcurrentEvents(group)
    }

    func test__group_add_child__from_an_observer_on_another_child() {
        let addedChild = BlockProcedure { usleep(5000) }
        addedChild.name = "AddedChildProcedure"
        let initialChild = BlockProcedure { usleep(5000) }
        initialChild.name = "ChildProcedure"
        addCompletionBlockTo(procedure: initialChild)
        addCompletionBlockTo(procedure: addedChild)
        let group = EventConcurrencyTrackingGroupProcedure(operations: [initialChild], registrar: EventConcurrencyTrackingRegistrar(recordHistory: true))
        initialChild.addWillExecuteBlockObserver { _, _ in
            group.addChild(addedChild)
        }
        wait(for: group)
        PKAssertProcedureFinished(initialChild)
        PKAssertProcedureFinished(addedChild)
        PKAssertProcedureFinished(group)
        PKAssertProcedureNoConcurrentEvents(group)
    }

    func test__group_add_child__before_procedure_execute_async() {
        var didExecuteWillAddObserverForAddedChildOperation = false
        var procedureIsExecuting_InWillAddObserver = false
        var procedureIsFinished_InWillAddObserver = false

        let addedChild = BlockProcedure { usleep(5000) }
        addedChild.name = "AddedChildOperation"
        let group = TestGroupProcedure(operations: [])

        // test if `procedure`'s execute can be properly delayed by group.add(child:before:)
        let procedure = BlockProcedure { }
        procedure.addWillExecuteBlockObserver { procedure, pendingExecute in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // despite this being executed long after the willExecute observer has returned
                // (and a delay), by passing the pendingExecute event to the add(child:before:) function
                // it should ensure that `procedure` does not execute until producing the
                // operation succeeds (i.e. until all WillAdd observers have been fired and it's
                // added to the group)
                group.addChild(addedChild, before: pendingExecute)
            }
        }
        group.addWillAddOperationBlockObserver { procedure, operation in
            guard operation === addedChild else { return }
            didExecuteWillAddObserverForAddedChildOperation = true
            procedureIsExecuting_InWillAddObserver = procedure.isExecuting
            procedureIsFinished_InWillAddObserver = procedure.isFinished
        }
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
        XCTAssertTrue(didExecuteWillAddObserverForAddedChildOperation, "group never executed its WillAddOperation observer for the added child operation")
        XCTAssertFalse(procedureIsExecuting_InWillAddObserver, "group was executing when its WillAddOperation observer was fired for the added child operation")
        XCTAssertFalse(procedureIsFinished_InWillAddObserver, "group was finished when its WillAddOperation observer was fired for the added child operation")
    }

    func test__group_add_child___before_procedure_finish_async() {
        var didExecuteWillAddObserverForAddedChildOperation = false
        var procedureIsExecuting_InWillAddObserver = false
        var procedureIsFinished_InWillAddObserver = false

        let addedChild = BlockProcedure { usleep(5000) }
        addedChild.name = "AddedChildOperation"
        let group = TestGroupProcedure(operations: [])

        // test if `procedure`'s finish can be properly delayed by group.add(child:before:)
        let procedure = BlockProcedure { }
        procedure.addWillFinishBlockObserver { procedure, _, pendingFinish in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // despite this being executed long after the willFinish observer has returned
                // (and a delay), by passing the pendingFinish event to the group's add(child:before:) function
                // it should ensure that `procedure` does not finish until producing the
                // operation succeeds (i.e. until all WillAdd observers have been fired and it's
                // added to the group)
                group.addChild(addedChild, before: pendingFinish)
            }
        }
        group.addWillAddOperationBlockObserver { procedure, operation in
            guard operation === addedChild else { return }
            didExecuteWillAddObserverForAddedChildOperation = true
            procedureIsExecuting_InWillAddObserver = procedure.isExecuting
            procedureIsFinished_InWillAddObserver = procedure.isFinished
        }
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
        XCTAssertTrue(didExecuteWillAddObserverForAddedChildOperation, "procedure never executed its WillAddOperation observer for the produced operation")
        XCTAssertFalse(procedureIsExecuting_InWillAddObserver, "procedure was executing when its WillAddOperation observer was fired for the produced operation")
        XCTAssertFalse(procedureIsFinished_InWillAddObserver, "procedure was finished when its WillAddOperation observer was fired for the produced operation")
    }
}
