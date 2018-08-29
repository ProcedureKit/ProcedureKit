//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class QueueDelegateTests: ProcedureKitTestCase {

    class WeakExpectation {
        private(set) weak var expectation: XCTestExpectation?
        init(_ expectation: XCTestExpectation) {
            self.expectation = expectation
        }
    }
    var expectOperations: Protector<[Operation: WeakExpectation]>!
    var expectProcedures: Protector<[Procedure: WeakExpectation]>!

    open override func setUp() {
        super.setUp()
        let expectOperations = Protector<[Operation: WeakExpectation]>([:])
        let expectProcedures = Protector<[Procedure: WeakExpectation]>([:])
        self.expectOperations = expectOperations
        self.expectProcedures = expectProcedures

        set(queueDelegate: QueueTestDelegate() { callback in
            switch callback {
            case .didFinishOperation(_, let operation):
                if let expForOperation = expectOperations.read({ (ward) -> WeakExpectation? in
                    return ward[operation]
                }) {
                    DispatchQueue.main.async {
                        expForOperation.expectation?.fulfill()
                    }
                }
            case .didFinishProcedure(_, let procedure, _):
                if let expForProcedure = expectProcedures.read({ (ward) -> WeakExpectation? in
                    return ward[procedure]
                }) {
                    DispatchQueue.main.async {
                        expForProcedure.expectation?.fulfill()
                    }
                }
                break
            default: break
            }
        })
    }

    open override func tearDown() {
        expectOperations = nil
        expectProcedures = nil
        super.tearDown()
    }

    func expectQueueDelegateDidFinishFor(operations: [Operation] = [], procedures: [Procedure] = []) {
        var operationExpectations = [Operation: WeakExpectation]()
        operations.forEach {
            assert(!($0 is Procedure), "Passed a Procedure (\($0)) to `operations:` - use `procedures:`. Different delegate callbacks are provided for Operations vs Procedures.")
            operationExpectations[$0] = WeakExpectation(expectation(description: "Expecting \($0.operationName) to generate didFinishOperation delegate callback."))
        }
        var procedureExpectations = [Procedure: WeakExpectation]()
        procedures.forEach {
            procedureExpectations[$0] = WeakExpectation(expectation(description: "Expecting \($0.operationName) to generate didFinishProcedure delegate callback."))
        }

        expectOperations.overwrite(with: operationExpectations)
        expectProcedures.overwrite(with: procedureExpectations)
    }

    func test__delegate__operation_notifications() {

        weak var expAddFinished = expectation(description: "Test: \(#function), queue.add did finish")
        weak var expOperationFinished = expectation(description: "Test: \(#function), Operation did finish")
        let operation = BlockOperation { }
        let finishedProcedure = BlockProcedure { }
        finishedProcedure.addDependency(operation)
        finishedProcedure.addDidFinishBlockObserver { _, _ in
            DispatchQueue.main.async {
                expOperationFinished?.fulfill()
            }
        }

        expectQueueDelegateDidFinishFor(operations: [operation], procedures: [finishedProcedure])

        queue.addOperations([operation, finishedProcedure]).then(on: DispatchQueue.main) {
            expAddFinished?.fulfill()
        }
        waitForExpectations(timeout: 3)

        XCTAssertFalse(delegate.procedureQueueWillAddOperation.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidAddOperation.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidFinishOperation.isEmpty)
    }

    func test___delegate__procedure_notifications() {

        weak var expAddFinished = expectation(description: "Test: \(#function), queue.add did finish")
        addCompletionBlockTo(procedure: procedure)

        expectQueueDelegateDidFinishFor(procedures: [procedure])

        queue.addOperation(procedure).then(on: DispatchQueue.main) {
            expAddFinished?.fulfill()
        }
        waitForExpectations(timeout: 3)

        XCTAssertFalse(delegate.procedureQueueWillAddProcedure.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidAddProcedure.isEmpty)
        XCTAssertFalse(delegate.procedureQueueWillFinishProcedure.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidFinishProcedure.isEmpty)
    }

    func test__delegate__operationqueue_addoperation() {
        // Testing OperationQueue's
        // `open func addOperation(_ op: Operation)`
        // on a ProcedureQueue to ensure that it goes through the
        // overriden ProcedureQueue add path.

        weak var didExecuteOperation = expectation(description: "Test: \(#function), did execute block")
        let operation = BlockOperation{
            DispatchQueue.main.async {
                didExecuteOperation?.fulfill()
            }
        }

        expectQueueDelegateDidFinishFor(operations: [operation])

        queue.addOperation(operation)

        waitForExpectations(timeout: 3)

        XCTAssertFalse(delegate.procedureQueueWillAddOperation.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidAddOperation.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidFinishOperation.isEmpty)
    }

    func test__delegate__operationqueue_addoperation_waituntilfinished() {
        // Testing OperationQueue's
        // `open func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool)`
        // on a ProcedureQueue to ensure that it goes through the
        // overriden ProcedureQueue add path and that it *doesn't* wait.

        weak var didExecuteOperation = expectation(description: "Test: \(#function), Operation did finish without being waited on by addOperations(_:waitUntilFinished:)")
        let operationCanProceed = DispatchSemaphore(value: 0)
        let operation = BlockOperation{
            guard operationCanProceed.wait(timeout: .now() + 1.0) == .success else {
                // do not fulfill expectation, because main never signaled that this
                // operation can proceed
                return
            }
            DispatchQueue.main.async {
                didExecuteOperation?.fulfill()
            }
        }

        expectQueueDelegateDidFinishFor(operations: [operation])

        queue.addOperations([operation], waitUntilFinished: true)
        operationCanProceed.signal()

        waitForExpectations(timeout: 2)

        XCTAssertFalse(delegate.procedureQueueWillAddOperation.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidAddOperation.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidFinishOperation.isEmpty)
    }

    func test__delegate__operationqueue_addoperation_block() {
        // Testing OperationQueue's
        // `open func addOperation(_ block: @escaping () -> Swift.Void)`
        // on a ProcedureQueue to ensure that it goes through the
        // overriden ProcedureQueue add path.

        weak var didExecuteBlock = expectation(description: "Test: \(#function), did execute block")
        queue.isSuspended = true
        queue.addOperation({
            DispatchQueue.main.async {
                didExecuteBlock?.fulfill()
            }
        })

        // check the queue to see if a new BlockOperation has been created
        XCTAssertEqual(queue.operations.count, 1)
        XCTAssertTrue(queue.operations[0] is BlockOperation, "First item in Queue is not the expected BlockOperation")

        expectQueueDelegateDidFinishFor(operations: [queue.operations[0]])

        // resume the queue and wait for the BlockOperation to finish
        queue.isSuspended = false
        waitForExpectations(timeout: 3)

        XCTAssertFalse(delegate.procedureQueueWillAddOperation.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidAddOperation.isEmpty)
        XCTAssertFalse(delegate.procedureQueueDidFinishOperation.isEmpty)
    }
}

class ExecutionTests: ProcedureKitTestCase {

    func test__procedure_executes() {
        wait(for: procedure)
        XCTAssertTrue(procedure.didExecute)
    }

    func test__procedure_add_multiple_completion_blocks() {
        weak var expect = expectation(description: "Test: \(#function), \(UUID())")

        var completionBlockOneDidRun = 0
        procedure.addCompletionBlock {
            completionBlockOneDidRun += 1
        }

        var completionBlockTwoDidRun = 0
        procedure.addCompletionBlock {
            completionBlockTwoDidRun += 1
        }

        var finalCompletionBlockDidRun = 0
        procedure.addCompletionBlock {
            finalCompletionBlockDidRun += 1
            DispatchQueue.main.async {
                guard let expect = expect else { print("Test: \(#function): Finished expectation after timeout"); return }
                expect.fulfill()
            }
        }

        wait(for: procedure)

        XCTAssertEqual(completionBlockOneDidRun, 1)
        XCTAssertEqual(completionBlockTwoDidRun, 1)
        XCTAssertEqual(finalCompletionBlockDidRun, 1)
    }

    func test__enqueue_a_sequence_of_operations() {
        addCompletionBlockTo(procedure: procedure, withExpectationDescription: "\(#function)")
        [procedure].enqueue()
        waitForExpectations(timeout: 3, handler: nil)
        PKAssertProcedureFinished(procedure)
    }

    func test__enqueue_a_sequence_of_operations_deallocates_queue() {
        addCompletionBlockTo(procedure: procedure, withExpectationDescription: "\(#function)")
        var nilQueue: ProcedureQueue! = ProcedureQueue()
        weak var weakQueue = nilQueue
        [procedure].enqueue(on: weakQueue!)
        nilQueue = nil
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertNil(nilQueue)
        XCTAssertNil(weakQueue)
    }

    func test__procedure_executes_on_underlying_queue_of_procedurequeue() {
        // If a Procedure is added to a ProcedureQueue with an `underlyingQueue` configured,
        // the Procedure's `execute()` function should run on the underlyingQueue.

        class TestExecuteOnUnderlyingQueueProcedure: Procedure {

            public typealias Block = () -> Void
            private let block: Block

            public init(block: @escaping Block) {
                self.block = block
                super.init()
            }

            open override func execute() {
                block()
                finish()
            }
        }

        let customDispatchQueueLabel = "run.kit.procedure.ProcedureKit.Tests.TestUnderlyingQueue"
        let customDispatchQueue = DispatchQueue(label: customDispatchQueueLabel, attributes: [.concurrent])
        let customScheduler = ProcedureKit.Scheduler(queue: customDispatchQueue)

        let procedureQueue = ProcedureQueue()
        procedureQueue.underlyingQueue = customDispatchQueue

        let didExecuteOnDesiredQueue = Protector(false)
        let procedure = TestExecuteOnUnderlyingQueueProcedure {
            // inside execute()
            if customScheduler.isOnScheduledQueue {
                didExecuteOnDesiredQueue.overwrite(with: true)
            }
        }

        addCompletionBlockTo(procedure: procedure)
        procedureQueue.addOperation(procedure)
        waitForExpectations(timeout: 3)

        XCTAssertTrue(didExecuteOnDesiredQueue.access, "execute() did not execute on the desired underlyingQueue")
    }
}

import Dispatch

class QualityOfServiceTests: ProcedureKitTestCase {

    private func testQoSClassLevels(_ block: (QualityOfService) -> Void) {
        #if os(macOS)
        block(.userInteractive)
        block(.userInitiated)
        #else
        block(.userInteractive)
        block(.userInitiated)
        block(.`default`)
        #endif
    }

    func test__procedure__set_quality_of_service__procedure_execute() {
        testQoSClassLevels { desiredQoS in
            let recordedQoSClass = Protector<DispatchQoS.QoSClass>(.unspecified)
            let procedure = BlockProcedure {
                recordedQoSClass.overwrite(with: DispatchQueue.currentQoSClass)
            }
            procedure.qualityOfService = desiredQoS
            wait(for: procedure, withExpectationDescription: "Procedure Did Finish (QoSClassLevel: \(desiredQoS.qosClass))")
            XCTAssertEqual(recordedQoSClass.access, desiredQoS.qosClass)
        }
    }

    func test__procedure__set_quality_of_service__will_execute_observer() {
        testQoSClassLevels { desiredQoS in
            let recordedQoSClass = Protector<DispatchQoS.QoSClass>(.unspecified)
            let procedure = TestProcedure()
            procedure.addWillExecuteBlockObserver { procedure, _ in
                recordedQoSClass.overwrite(with: DispatchQueue.currentQoSClass)
            }
            procedure.qualityOfService = desiredQoS
            wait(for: procedure, withExpectationDescription: "Procedure Did Finish (QoSClassLevel: \(desiredQoS.qosClass))")
            XCTAssertEqual(recordedQoSClass.access, desiredQoS.qosClass)
        }
    }

    func test__procedure__set_quality_of_service__execute_after_will_execute_on_custom_queue() {
        testQoSClassLevels { desiredQoS in
            let recordedQoSClass_willExecute_otherQueue = Protector<DispatchQoS.QoSClass>(.unspecified)
            let recordedQoSClass_willExecute = Protector<DispatchQoS.QoSClass>(.unspecified)
            let recordedQoSClass_execute = Protector<DispatchQoS.QoSClass>(.unspecified)
            let procedure = BlockProcedure {
                recordedQoSClass_execute.overwrite(with: DispatchQueue.currentQoSClass)
            }
            // 1st WillExecute observer has a custom queue with no specified QoS level
            // the submitted observer block should run with a QoS at least that of the desiredQoS level
            let otherQueue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.Testing.OtherQueue")
            procedure.addWillExecuteBlockObserver(synchronizedWith: otherQueue) { procedure, _ in
                recordedQoSClass_willExecute_otherQueue.overwrite(with: DispatchQueue.currentQoSClass)
            }
            // 2nd WillExecute observer has no custom queue (runs on the Procedure's EventQueue)
            // the observer block should run with a QoS level equal to the desiredQoS level
            procedure.addWillExecuteBlockObserver { procedure, _ in
                recordedQoSClass_willExecute.overwrite(with: DispatchQueue.currentQoSClass)
            }
            procedure.qualityOfService = desiredQoS
            wait(for: procedure, withExpectationDescription: "Procedure Did Finish (QoSClassLevel: \(desiredQoS.qosClass))")
            XCTAssertGreaterThanOrEqual(recordedQoSClass_willExecute_otherQueue.access, desiredQoS.qosClass)
            XCTAssertEqual(recordedQoSClass_willExecute.access, desiredQoS.qosClass)
            XCTAssertEqual(recordedQoSClass_execute.access, desiredQoS.qosClass)
        }
    }

    func test__procedure__set_quality_of_service__did_cancel_observer() {
        testQoSClassLevels { desiredQoS in
            weak var expDidCancel = expectation(description: "did cancel Procedure with qualityOfService: \(desiredQoS.qosClass)")
            let recordedQoSClass = Protector<DispatchQoS.QoSClass>(.unspecified)
            let procedure = TestProcedure()
            procedure.addDidCancelBlockObserver { procedure, _ in
                recordedQoSClass.overwrite(with: DispatchQueue.currentQoSClass)
                DispatchQueue.main.async { expDidCancel?.fulfill() }
            }
            procedure.qualityOfService = desiredQoS
            procedure.cancel()
            waitForExpectations(timeout: 3)
            // DidCancel observers should be executed with the qualityOfService of the Procedure
            XCTAssertEqual(recordedQoSClass.access, desiredQoS.qosClass)
        }
    }
}

class ProcedureTests: ProcedureKitTestCase {

    func test__procedure_name() {
        let block = BlockProcedure { }
        XCTAssertEqual(block.name, "BlockProcedure")

        let group = GroupProcedure(operations: [])
        XCTAssertEqual(group.name, "GroupProcedure")

        wait(for: group)
    }

    func test__identity_is_equatable() {
        let identity1 = procedure.identity
        let identity2 = procedure.identity
        XCTAssertEqual(identity1, identity2)
    }

    func test__identity_description() {
        XCTAssertTrue(procedure.identity.description.hasPrefix("TestProcedure #"))
        procedure.name = nil
        XCTAssertTrue(procedure.identity.description.hasPrefix("Unnamed Procedure #"))
    }
}

class DependencyTests: ProcedureKitTestCase {

    func test__operation_added_using_then_follows_receiver() {
        let another = TestProcedure()
        let operations = procedure.then(do: another)
        XCTAssertEqual(operations, [procedure, another])
        wait(for: procedure, another)
        XCTAssertLessThan(procedure.executedAt, another.executedAt)
    }

    func test__operation_added_using_then_via_closure_follows_receiver() {
        let another = TestProcedure()
        let operations = procedure.then { another }
        XCTAssertEqual(operations, [procedure, another])
        wait(for: procedure, another)
        XCTAssertLessThan(procedure.executedAt, another.executedAt)
    }

    func test__operation_added_using_then_via_closure_returning_nil() {
        XCTAssertEqual(procedure.then { nil }, [procedure])
    }

    func test__operation_added_using_then_via_closure_throwing_error() {
        do {
            let _ = try procedure.then { throw TestError() }
        }
        catch is TestError { }
        catch { XCTFail("Caught unexpected error.") }
    }

    func test__operation_added_to_array_using_then() {
        let one = TestProcedure()
        let two = TestProcedure(delay: 1)
        let didFinishAnother = DispatchGroup()
        didFinishAnother.enter()
        let another = TestProcedure()
        another.addDidFinishBlockObserver { _, _ in
            didFinishAnother.leave()
        }
        let all = [one, two, procedure].then(do: another)
        XCTAssertEqual(all.count, 4)
        run(operation: another)
        wait(for: procedure)
        // wait should time out because all of `one`, `two`, `procedure` should be waited on to start `another`
        XCTAssertEqual(didFinishAnother.wait(timeout: .now() + 0.1), .timedOut)

        weak var expDidFinishAnother = expectation(description: "DidFinish: another")
        didFinishAnother.notify(queue: DispatchQueue.main) {
            expDidFinishAnother?.fulfill()
        }
        wait(for: one, two) // wait for `one`, `two` and `another` (after `one` and `two`) to finish
        PKAssertProcedureFinished(another)
        XCTAssertLessThan(one.executedAt, another.executedAt)
        XCTAssertLessThan(two.executedAt, another.executedAt)
        XCTAssertLessThan(procedure.executedAt, another.executedAt)
    }

    func test__operation_added_to_array_using_then_via_closure() {
        let one = TestProcedure()
        let two = TestProcedure(delay: 1)
        let another = TestProcedure()
        let all = [one, two, procedure].then { another }
        XCTAssertEqual(all.count, 4)
        wait(for: one, two, procedure, another)
        PKAssertProcedureFinished(another)
        XCTAssertLessThan(one.executedAt, another.executedAt)
        XCTAssertLessThan(two.executedAt, another.executedAt)
        XCTAssertLessThan(procedure.executedAt, another.executedAt)
    }

    func test__operation_added_to_array_using_then_via_closure_throwing_error() {
        let one = TestProcedure()
        let two = TestProcedure(delay: 1)
        do {
            let _ = try [one, two, procedure].then { throw TestError() }
        }
        catch is TestError { }
        catch { XCTFail("Caught unexpected error.") }
    }

    func test__operation_added_to_array_using_then_via_closure_returning_nil() {
        let one = TestProcedure()
        let two = TestProcedure(delay: 1)
        let all = [one, two, procedure].then { nil }
        XCTAssertEqual(all.count, 3)
    }
}

class ProduceTests: ProcedureKitTestCase {

    func test__procedure_produce_operation() {
        let producedOperation = BlockProcedure { usleep(5000) }
        producedOperation.name = "ProducedOperation"
        let procedure = EventConcurrencyTrackingProcedure() { procedure in
            try! procedure.produce(operation: producedOperation) // swiftlint:disable:this force_try
            procedure.finish()
        }
        addCompletionBlockTo(procedure: producedOperation) // also wait for the producedOperation to finish
        wait(for: procedure)
        PKAssertProcedureFinished(producedOperation)
        PKAssertProcedureFinished(procedure)
        PKAssertProcedureNoConcurrentEvents(procedure)
    }

    func test__procedure_produce_operation_before_execute() {
        let producedOperation = BlockProcedure { usleep(5000) }
        producedOperation.name = "ProducedOperation"
        let procedure = EventConcurrencyTrackingProcedure() { procedure in
            procedure.finish()
        }
        procedure.addWillExecuteBlockObserver { procedure, pendingExecute in
            try! procedure.produce(operation: producedOperation, before: pendingExecute) // swiftlint:disable:this force_try
        }
        addCompletionBlockTo(procedure: producedOperation) // also wait for the producedOperation to finish
        wait(for: procedure)
        PKAssertProcedureFinished(producedOperation)
        PKAssertProcedureFinished(procedure)
        PKAssertProcedureNoConcurrentEvents(procedure)
    }

    func test__procedure_produce_operation_before_execute_async() {
        let didExecuteWillAddObserverForProducedOperation = Protector(false)
        let procedureIsExecuting_InWillAddObserver = Protector(false)
        let procedureIsFinished_InWillAddObserver = Protector(false)

        let producedOperation = BlockProcedure { usleep(5000) }
        producedOperation.name = "ProducedOperation"
        let procedure = EventConcurrencyTrackingProcedure() { procedure in
            procedure.finish()
        }
        procedure.addWillExecuteBlockObserver { procedure, pendingExecute in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // despite this being executed long after the willExecute observer has returned
                // (and a delay), by passing the pendingExecute event to the produce function
                // it should ensure that `procedure` does not execute until producing the
                // operation succeeds (i.e. until all WillAdd observers have been fired and it's
                // added to the queue)
                try! procedure.produce(operation: producedOperation, before: pendingExecute) // swiftlint:disable:this force_try
            }
        }
        procedure.addWillAddOperationBlockObserver { procedure, operation in
            guard operation === producedOperation else { return }
            didExecuteWillAddObserverForProducedOperation.overwrite(with: true)
            procedureIsExecuting_InWillAddObserver.overwrite(with: procedure.isExecuting)
            procedureIsFinished_InWillAddObserver.overwrite(with: procedure.isFinished)
        }
        addCompletionBlockTo(procedure: producedOperation) // also wait for the producedOperation to finish
        wait(for: procedure)
        PKAssertProcedureFinished(producedOperation)
        PKAssertProcedureFinished(procedure)
        XCTAssertTrue(didExecuteWillAddObserverForProducedOperation.access, "procedure never executed its WillAddOperation observer for the produced operation")
        XCTAssertFalse(procedureIsExecuting_InWillAddObserver.access, "procedure was executing when its WillAddOperation observer was fired for the produced operation")
        XCTAssertFalse(procedureIsFinished_InWillAddObserver.access, "procedure was finished when its WillAddOperation observer was fired for the produced operation")
    }

    func test__procedure_produce_operation_before_finish() {
        let producedOperation = BlockProcedure { usleep(5000) }
        producedOperation.name = "ProducedOperation"
        let procedure = EventConcurrencyTrackingProcedure() { procedure in
            procedure.finish()
        }
        procedure.addWillFinishBlockObserver { procedure, errors, pendingFinish in
            try! procedure.produce(operation: producedOperation, before: pendingFinish) // swiftlint:disable:this force_try
        }
        addCompletionBlockTo(procedure: producedOperation) // also wait for the producedOperation to finish
        wait(for: procedure)
        PKAssertProcedureFinished(producedOperation)
        PKAssertProcedureFinished(procedure)
    }

    func test__procedure_produce_operation_before_finish_async() {
        let didExecuteWillAddObserverForProducedOperation = Protector(false)
        let procedureIsExecuting_InWillAddObserver = Protector(false)
        let procedureIsFinished_InWillAddObserver = Protector(false)

        let producedOperation = BlockProcedure { usleep(5000) }
        producedOperation.name = "ProducedOperation"
        let procedure = EventConcurrencyTrackingProcedure() { procedure in
            procedure.finish()
        }
        procedure.addWillFinishBlockObserver { procedure, errors, pendingFinish in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // despite this being executed long after the willFinish observer has returned
                // (and a delay), by passing the pendingFinish event to the produce function
                // it should ensure that `procedure` does not finish until producing the
                // operation succeeds (i.e. until all WillAdd observers have been fired and it's
                // added to the queue)
                try! procedure.produce(operation: producedOperation, before: pendingFinish) // swiftlint:disable:this force_try
            }
        }
        procedure.addWillAddOperationBlockObserver { procedure, operation in
            guard operation === producedOperation else { return }
            didExecuteWillAddObserverForProducedOperation.overwrite(with: true)
            procedureIsExecuting_InWillAddObserver.overwrite(with: procedure.isExecuting)
            procedureIsFinished_InWillAddObserver.overwrite(with: procedure.isFinished)
        }
        addCompletionBlockTo(procedure: producedOperation) // also wait for the producedOperation to finish
        wait(for: procedure)
        PKAssertProcedureFinished(producedOperation)
        PKAssertProcedureFinished(procedure)
        XCTAssertTrue(didExecuteWillAddObserverForProducedOperation.access, "procedure never executed its WillAddOperation observer for the produced operation")
        XCTAssertFalse(procedureIsExecuting_InWillAddObserver.access, "procedure was executing when its WillAddOperation observer was fired for the produced operation")
        XCTAssertFalse(procedureIsFinished_InWillAddObserver.access, "procedure was finished when its WillAddOperation observer was fired for the produced operation")
    }
}

class ObserverEventQueueTests: ProcedureKitTestCase {

    func test__custom_observer_with_event_queue() {
        let didFinishGroup = DispatchGroup()
        didFinishGroup.enter()
        let eventsNotOnSpecifiedQueue = Protector<[EventConcurrencyTrackingRegistrar.ProcedureEvent]>([])
        let eventsOnSpecifiedQueue = Protector<[EventConcurrencyTrackingRegistrar.ProcedureEvent]>([])
        let registrar = EventConcurrencyTrackingRegistrar()
        let customEventQueue = EventQueue(label: "run.kit.procedure.ProcedureKit.Testing.ObserverCustomEventQueue")
        let observer = ConcurrencyTrackingObserver(registrar: registrar, eventQueue: customEventQueue, callbackBlock: { procedure, event in
            guard customEventQueue.isOnQueue else {
                eventsNotOnSpecifiedQueue.append(event)//((procedure.operationName, event))
                return
            }
            eventsOnSpecifiedQueue.append(event)//((procedure.operationName, event))
        })
        let procedure = EventConcurrencyTrackingProcedure(name: "TestingProcedure") { procedure in
            procedure.finish()
        }
        procedure.addObserver(observer)
        procedure.addDidFinishBlockObserver { _, _ in
            didFinishGroup.leave()
        }

        let finishing = BlockProcedure { }
        finishing.addDependency(procedure)

        run(operation: procedure)
        wait(for: finishing)

        // Because Procedure signals isFinished KVO *prior* to calling DidFinish observers,
        // the above wait() may return before the ConcurrencyTrackingObserver is called to
        // record the DidFinish event.
        // Thus, wait on a second observer added *after* the ConcurrencyTrackingObserver
        // to ensure the event is captured by this test.
        weak var expDidFinishObserverFired = expectation(description: "DidFinishObserver was fired")
        didFinishGroup.notify(queue: DispatchQueue.main) {
            expDidFinishObserverFired?.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertTrue(eventsNotOnSpecifiedQueue.access.isEmpty, "Found events not on expected queue: \(eventsNotOnSpecifiedQueue.access)")

        let expectedEventsOnQueue: [EventConcurrencyTrackingRegistrar.ProcedureEvent] = [.observer_didAttach, .observer_willExecute, .observer_didExecute, .observer_willFinish, .observer_didFinish]

        XCTAssertEqual(eventsOnSpecifiedQueue.access, expectedEventsOnQueue)
    }

    func test__custom_observer_with_event_queue_same_as_self() {
        let procedure = EventConcurrencyTrackingProcedure(name: "TestingProcedure") { procedure in
            procedure.finish()
        }

        let registrar = EventConcurrencyTrackingRegistrar()
        // NOTE: Don't do this. This is just for testing.
        let observer = ConcurrencyTrackingObserver(registrar: registrar, eventQueue: procedure.eventQueue)
        procedure.addObserver(observer)

        let finishing = BlockProcedure { }
        finishing.addDependency(procedure)

        run(operation: procedure)
        wait(for: finishing) // This test should not timeout.
    }
}

class MainQueueTests: XCTestCase {

    func test__operation_queue_main_has_underlyingqueue_main() {
        guard let underlyingQueue = OperationQueue.main.underlyingQueue else {
            XCTFail("OperationQueue.main is missing any set underlyingQueue.")
            return
        }
        XCTAssertTrue(underlyingQueue.isMainDispatchQueue, "OperationQueue.main.underlyingQueue does not seem to be the same as DispatchQueue.main")
    }

    func test__procedure_queue_main_has_underlyingqueue_main() {
        guard let underlyingQueue = ProcedureQueue.main.underlyingQueue else {
            XCTFail("ProcedureQueue.main is missing any set underlyingQueue.")
            return
        }
        XCTAssertTrue(underlyingQueue.isMainDispatchQueue, "ProcedureQueue.main.underlyingQueue does not seem to be the same as DispatchQueue.main")
    }
}
