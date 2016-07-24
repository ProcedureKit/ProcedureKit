//
//  GroupOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import XCTest
@testable import Operations

class GroupOperationTests: OperationTests {

    func createGroupOperations() -> [TestOperation] {
        return (0..<3).map { _ in TestOperation() }
    }

    func test__cancel_group_operation() {

        let operations = createGroupOperations()
        let operation = GroupOperation(operations: operations)
        operation.cancel()

        for op in operations {
            XCTAssertTrue(op.cancelled)
        }
    }
    
    func test__cancel_running_group_operation_race_condition() {
        
        let delay = DelayOperation(interval: 10)
        let group = GroupOperation(operations: [delay])
        
        let expectation = expectationWithDescription("Test: \(#function)")
        group.addObserver(DidFinishObserver { observedOperation, errors in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                XCTAssertTrue(observedOperation.cancelled)
                expectation.fulfill()
            }
        })
        
        runOperation(group)
        group.cancel()
        
        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(group.cancelled)
    }

    func test__group_operations_are_performed_in_order() {
        let group = createGroupOperations()
        let expectation = expectationWithDescription("Test: \(#function)")
        let operation = GroupOperation(operations: group)
        operation.addCompletionBlock {
            expectation.fulfill()
        }

        runOperation(operation)
        waitForExpectationsWithTimeout(4, handler: nil)
        XCTAssertTrue(operation.finished)
        for op in group {
            XCTAssertTrue(op.didExecute)
        }
    }

    func test__adding_operation_to_running_group() {
        let expectation = expectationWithDescription("Test: \(#function)")
        let operation = GroupOperation(operations: TestOperation(), TestOperation())
        operation.addCompletionBlock {
            expectation.fulfill()
        }
        let extra = TestOperation()
        runOperation(operation)
        operation.addOperation(extra)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(extra.didExecute)
    }

    func test__that_group_conditions_are_evaluated_before_the_child_operations() {
        let operations: [TestOperation] = (0..<3).map { i in
            let op = TestOperation()
            op.addCondition(BlockCondition { true })
            let exp = self.expectationWithDescription("Group Operation, child \(i): \(#function)")
            self.addCompletionBlockToTestOperation(op, withExpectation: exp)
            return op
        }

        let group = GroupOperation(operations: operations)
        addCompletionBlockToTestOperation(group, withExpectation: expectationWithDescription("Test: \(#function)"))

        runOperation(group)
        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(group.finished)
    }

    func test__that_adding_multiple_operations_to_a_group_works() {
        let group = GroupOperation(operations: [])
        let operations: [TestOperation] = (0..<3).map { _ in TestOperation() }
        group.addOperations(operations)

        addCompletionBlockToTestOperation(group, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(group)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(group.finished)
        XCTAssertTrue(operations[0].didExecute)
        XCTAssertTrue(operations[1].didExecute)
        XCTAssertTrue(operations[2].didExecute)
    }

    func test__group_operation_exits_correctly_when_child_errors() {

        let numberOfOperations = 10_000
        let operations = (0..<numberOfOperations).map { i -> Operation in
            let block = BlockOperation { (completion: BlockOperation.ContinuationBlockType) in
                let error = NSError(domain: "me.danthorpe.Operations.Tests", code: -9_999, userInfo: nil)
                completion(error: error)
            }
            block.name = "Block \(i)"
            return block
        }

        let group = GroupOperation(operations: operations)

        let waiter = BlockOperation { }
        waiter.addDependency(group)

        let expectation = expectationWithDescription("Test: \(#function)")
        addCompletionBlockToTestOperation(waiter, withExpectation: expectation)
        runOperations(group, waiter)
        waitForExpectationsWithTimeout(5.0, handler: nil)

        XCTAssertTrue(group.finished)
        XCTAssertEqual(group.errors.count, numberOfOperations)
    }

    func test__group_operation_exits_correctly_when_child_group_finishes_with_errors() {
        let operation = TestOperation(error: TestOperation.Error.SimulatedError)
        let child = GroupOperation(operations: [operation])
        let group = GroupOperation(operations: [child])

        let waiter = BlockOperation { }
        waiter.addDependency(group)

        let expectation = expectationWithDescription("Test: \(#function)")
        addCompletionBlockToTestOperation(waiter, withExpectation: expectation)
        runOperations(group, waiter)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(group.finished)
        XCTAssertEqual(group.errors.count, 1)
    }

    func test__group_operation_exits_correctly_when_multiple_nested_groups_finish_with_errors() {
        let operation = TestOperation(error: TestOperation.Error.SimulatedError)
        let child1 = GroupOperation(operations: [operation])
        let child = GroupOperation(operations: [child1])
        let group = GroupOperation(operations: [child])

        let waiter = BlockOperation { }
        waiter.addDependency(group)

        let expectation = expectationWithDescription("Test: \(#function)")
        addCompletionBlockToTestOperation(waiter, withExpectation: expectation)
        runOperations(group, waiter)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(group.finished)
        XCTAssertEqual(group.errors.count, 1)
    }
    
    func test__will_add_child_observer__gets_called() {
        let child1 = TestOperation()
        let group = GroupOperation(operations: [child1])
        
        var blockCalledWith: (GroupOperation, NSOperation)? = .None
        let observer = WillAddChildObserver { group, child in
            blockCalledWith = (group, child)
        }
        group.addObserver(observer)
        
        waitForOperation(group)

        guard let (observedGroup, observedChild) = blockCalledWith else {
            XCTFail("Observer not called"); return
        }
        
        XCTAssertEqual(group, observedGroup)
        XCTAssertEqual(child1, observedChild)
    }
    
    func test__group_operation_which_cancels_propagates_error_to_children() {
        
        let child = TestOperation()
        
        var childErrors: [ErrorType] = []
        child.addObserver(DidCancelObserver { op in
            childErrors = op.errors
        })
        
        let group = GroupOperation(operations: [child])
        
        let groupError = TestOperation.Error.SimulatedError
        group.cancelWithError(groupError)
        
        addCompletionBlockToTestOperation(group)
        runOperation(group)
        waitForExpectationsWithTimeout(3, handler: nil)
        
        XCTAssertEqual(childErrors.count, 1)
        
        guard let error = childErrors.first as? OperationError else {
            XCTFail("Incorrect error received"); return
        }
        
        switch error {
        case let .ParentOperationCancelledWithErrors(parentErrors):
            guard let parentError = parentErrors.first as? TestOperation.Error else {
                XCTFail("Incorrect error received"); return
            }            
            XCTAssertEqual(parentError, groupError)
        default:
            XCTFail("Incorrect error received"); return
        }
    }
    
    func test__group_operation__gets_user_intent_from_initial_operations() {
        let test1 = TestOperation()
        test1.userIntent = .Initiated
        let test2 = TestOperation()
        let test3 = NSBlockOperation { }
        
        let group = GroupOperation(operations: [ test1, test2, test3 ])
        XCTAssertEqual(group.userIntent, Operation.UserIntent.Initiated)
    }
    
    func test__group_operation__sets_user_intent_on_child_operations() {
        let test1 = TestOperation()
        test1.userIntent = .Initiated
        let test2 = TestOperation()
        let test3 = NSBlockOperation { }
        
        let group = GroupOperation(operations: [ test1, test2, test3 ])
        group.userIntent = .SideEffect
        XCTAssertEqual(test1.userIntent, Operation.UserIntent.SideEffect)
        XCTAssertEqual(test2.userIntent, Operation.UserIntent.SideEffect)
        XCTAssertEqual(test3.qualityOfService, NSQualityOfService.UserInitiated)
    }

    func test__group_operation__initial_operations_only_added_once_to_operations_array() {
        let child1 = TestOperation()
        let group = GroupOperation(operations: [child1])

        waitForOperation(group)

        XCTAssertEqual(group.operations.count, 1)
        XCTAssertEqual(group.operations[0], child1)
    }

    func test__group_operation__does_not_finish_before_child_operations_have_finished() {
        for _ in 0..<100 {
            let child1 = TestOperation(delay: 1.0)
            let child2 = TestOperation(delay: 1.0)
            let group = GroupOperation(operations: [ child1, child2 ])

            weak var expectation = expectationWithDescription("Test: \(#function)")
            group.addCompletionBlock {
                let child1Finished = child1.finished
                let child2Finished = child2.finished
                dispatch_async(Queue.Main.queue, {
                    guard let expectation = expectation else { return }
                    XCTAssertTrue(child1Finished)
                    XCTAssertTrue(child2Finished)
                    expectation.fulfill()
                })
            }

            runOperation(group)
            group.cancel()

            waitForExpectationsWithTimeout(5, handler: nil)
            XCTAssertTrue(group.cancelled)
        }
    }

    func test__group_operation__does_not_finish_before_child_groupoperations_are_finished() {
        for _ in 0..<100 {
            let child1 = GroupOperation(operations: [BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
                sleep(5)
                continuation(error: nil)
            }])
            let child2 = GroupOperation(operations: [BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
                sleep(5)
                continuation(error: nil)
            }])
            let group = GroupOperation(operations: [ child1, child2 ])

            weak var expectation = expectationWithDescription("Test: \(#function)")
            group.addCompletionBlock {
                let child1Finished = child1.finished
                let child2Finished = child2.finished
                dispatch_async(Queue.Main.queue, {
                    guard let expectation = expectation else { return }
                    XCTAssertTrue(child1Finished)
                    XCTAssertTrue(child2Finished)
                    expectation.fulfill()
                })
            }

            runOperation(group)
            group.cancel()

            waitForExpectationsWithTimeout(5, handler: nil)
            XCTAssertTrue(group.cancelled)
        }
    }
    
    func test__group_operation_does_not_finish_before_child_produced_operations_are_finished() {
        
        weak var didFinishExpectation = expectationWithDescription("Test: \(#function), DidFinish GroupOperation")
        let child = TestOperation(delay: 0.1)
        child.name = "ChildOperation"
        let childProducedOperation = TestOperation(delay: 0.5)
        childProducedOperation.name = "ChildProducedOperation"
        let group = GroupOperation(operations: [child])
        child.addObserver(WillExecuteObserver { operation in
            operation.produceOperation(childProducedOperation)
        })
        
        group.addCompletionBlock {
            dispatch_async(Queue.Main.queue, {
                guard let didFinishExpectation = didFinishExpectation else { return }
                didFinishExpectation.fulfill()
            })
        }
        
        runOperation(group)
        
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertTrue(group.finished)
        XCTAssertTrue(childProducedOperation.finished)
    }

    func test__group_operation__execute_is_called_when_cancelled_before_running() {
        class TestGroupOperation: GroupOperation {
            private(set) var didExecute: Bool = false

            override func execute() {
                didExecute = true
                super.execute()
            }
        }

        let child = TestOperation()
        let group = TestGroupOperation(operations: [child])

        group.cancel()
        XCTAssertFalse(group.didExecute)

        waitForOperation(group)

        XCTAssertTrue(group.cancelled)
        XCTAssertTrue(group.didExecute)
        XCTAssertTrue(group.finished)
    }

    func test__group_operation_cancellation__queue_is_empty_when_finished() {
        (0..<100).forEach { i in
            weak var didFinishExpectation = expectationWithDescription("Test: \(#function), DidFinish GroupOperation: \(i)")
            let child1 = TestOperation(delay: 1.0)
            let child2 = TestOperation(delay: 1.0)
            let group = GroupOperation(operations: [child1, child2])
            group.addCompletionBlock {
                let child1Finished = child1.finished
                let child2Finished = child2.finished
                dispatch_async(Queue.Main.queue, {
                    guard let didFinishExpectation = didFinishExpectation else { return }
                    XCTAssertTrue(child1Finished)
                    XCTAssertTrue(child2Finished)
                    didFinishExpectation.fulfill()
                })
            }

            runOperation(group)
            group.cancel()

            waitForExpectationsWithTimeout(5, handler: nil)

            XCTAssertEqual(group.queue.operations.count, 0)
            XCTAssertTrue(group.queue.suspended)
        }
    }
    
    func test__group_operation_operations_array_receives_operations_produced_by_children() {
        
        weak var didFinishExpectation = expectationWithDescription("Test: \(#function), DidFinish GroupOperation")
        let child = TestOperation(delay: 0.1)
        child.name = "ChildOperation"
        let childProducedOperation = TestOperation(delay: 0.2)
        childProducedOperation.name = "ChildProducedOperation"
        let group = GroupOperation(operations: [child])
        child.addObserver(WillExecuteObserver { operation in
            operation.produceOperation(childProducedOperation)
        })
        
        group.addCompletionBlock {
            dispatch_async(Queue.Main.queue, {
                guard let didFinishExpectation = didFinishExpectation else { return }
                didFinishExpectation.fulfill()
            })
        }
        
        runOperation(group)
        
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertEqual(group.operations.count, 2)
        XCTAssertTrue(group.operations.contains(child))
        XCTAssertTrue(group.operations.contains(childProducedOperation))
    }
    
    func test__group_operation_ignores_queue_delegate_calls_from_other_queues() {
        class PoorlyWrittenGroupOperationSubclass: GroupOperation {
            private var subclassQueue = OperationQueue()
            override init(underlyingQueue: dispatch_queue_t? = .None, operations: [NSOperation]) {
                super.init(underlyingQueue: underlyingQueue, operations: operations)
                subclassQueue.delegate = self
            }
            override func execute() {
                let operation = TestOperation()
                subclassQueue.addOperation(operation)
                subclassQueue.suspended = false
                super.execute()
            }
            // since GroupOperation already satisfies OperationQueueDelegate, this compiles
        }
        
        weak var didFinishExpectation = expectationWithDescription("Test: \(#function), DidFinish GroupOperation")
        let childOperation = TestOperation()
        let groupOperation = PoorlyWrittenGroupOperationSubclass(operations: [childOperation])
        var addedOperationFromOtherQueue = false
        
        groupOperation.addObserver(WillAddChildObserver{ (group, child) in
            if child !== childOperation {
                addedOperationFromOtherQueue = true
            }
        })
        
        groupOperation.addCompletionBlock {
            dispatch_async(Queue.Main.queue, {
                guard let didFinishExpectation = didFinishExpectation else { return }
                didFinishExpectation.fulfill()
            })
        }
        
        runOperation(groupOperation)
        
        waitForExpectationsWithTimeout(5, handler: nil)
        
        XCTAssertFalse(addedOperationFromOtherQueue)
    }

    func test__group_operation_suspended() {
        let group = GroupOperation(operations: [])
        let firstOperation = BlockOperation(block: { [unowned group] continuation in
            group.suspended = true
            continuation(error: nil)
        })
        let secondOperation = TestOperation(delay: 0.0)
        secondOperation.addDependency(firstOperation)

        weak var firstOpDidFinishExpectation = expectationWithDescription("Test: \(#function); firstOperation Did Finish")
        firstOperation.addObserver(DidFinishObserver { operation, errors in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                guard let firstOpDidFinishExpectation = firstOpDidFinishExpectation else { return }
                firstOpDidFinishExpectation.fulfill()
            }
        })

        group.addOperations([firstOperation, secondOperation])

        runOperation(group)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(group.suspended)
        XCTAssertFalse(group.finished)
        XCTAssertTrue(firstOperation.finished)
        XCTAssertFalse(secondOperation.finished)

        weak var groupDidFinishExpectation = expectationWithDescription("Test: \(#function); group operation Did Finish")
        group.addObserver(DidFinishObserver { observedOperation, errors in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                guard let groupDidFinishExpectation = groupDidFinishExpectation else { return }
                groupDidFinishExpectation.fulfill()
            }
        })

        group.suspended = false

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(group.suspended)
        XCTAssertTrue(group.finished)
        XCTAssertTrue(firstOperation.finished)
        XCTAssertTrue(secondOperation.finished)
    }
    
    func test__group_operation_suspended_before_execute() {
        let child = TestOperation(delay: 0.0)
        let group = GroupOperation(operations: [child])
        group.suspended = true

        let childOperationWillExecuteGroup = dispatch_group_create()
        dispatch_group_enter(childOperationWillExecuteGroup)
        child.addObserver(WillExecuteObserver { operation in
            dispatch_group_leave(childOperationWillExecuteGroup)
        })

        let groupOperationWillExecuteGroup = dispatch_group_create()
        dispatch_group_enter(groupOperationWillExecuteGroup)
        group.addObserver(WillExecuteObserver { operation in
            dispatch_group_leave(groupOperationWillExecuteGroup)
        })

        weak var expectation = expectationWithDescription("Test: \(#function); DidFinish Group")
        group.addObserver(DidFinishObserver { observedOperation, errors in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                guard let expectation = expectation else { return }
                expectation.fulfill()
            }
        })

        runOperation(group)

        let groupExecuteWait = dispatch_time(DISPATCH_TIME_NOW, Int64(3.0 * Double(NSEC_PER_SEC)))
        XCTAssertEqual(dispatch_group_wait(groupOperationWillExecuteGroup, groupExecuteWait), 0, "Group Operation has not yet executed.")

        let childWait = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
        XCTAssertNotEqual(dispatch_group_wait(childOperationWillExecuteGroup, childWait), 0, "Child operation executed when GroupOperation was suspended.")

        XCTAssertFalse(child.finished)
        XCTAssertFalse(group.finished)

        group.suspended = false

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(child.finished)
        XCTAssertTrue(group.finished)
    }
}

class GroupOperationMaxConcurrentOperationCountTests: OperationTests {

    private class ConcurrencyRegistrar {
        private let _sharedRunningOperations = Protector([NSOperation]())
        private let _maxConcurrentOperationsDetectedCount = Protector(Int(0))
        var maxConcurrentOperationsDetectedCount: Int {
            get {
                return _maxConcurrentOperationsDetectedCount.read { $0 }
            }
        }
        private func recordOperationsCount(currentOperationsCount: Int) {
            _maxConcurrentOperationsDetectedCount.write { (inout ward: Int) in
                if currentOperationsCount > ward {
                    ward = currentOperationsCount
                }
            }
        }
        func registerRunning(op: NSOperation) {
            _sharedRunningOperations.write { (inout ward: [NSOperation]) in
                ward.append(op)
                self.recordOperationsCount(ward.count)
            }
        }
        func deregisterRunning(op: NSOperation) {
            _sharedRunningOperations.write { (inout ward: [NSOperation]) in
                if let foundOperation = ward.indexOf(op) {
                    ward.removeAtIndex(foundOperation)
                }
            }
        }
        func atLeastOneOperationIsRunning(otherThan exception: NSOperation? = nil) -> Bool {
            return _sharedRunningOperations.read { ward -> Bool in
                for op in ward {
                    if op !== exception {
                        return true
                    }
                }
                return false
            }
        }
    }
    private class RegistersWhenRunningOperation: Operation {
        private weak var concurrencyRegistrar: ConcurrencyRegistrar?
        private let microsecondsToSleep: useconds_t
        init(microsecondsToSleep: useconds_t, registrar: ConcurrencyRegistrar) {
            self.concurrencyRegistrar = registrar
            self.microsecondsToSleep = microsecondsToSleep
            super.init()
        }
        override func execute() {
            concurrencyRegistrar?.registerRunning(self)
            usleep(microsecondsToSleep)
            concurrencyRegistrar?.deregisterRunning(self)
            finish()
        }
    }

    func test__group_operation_maxConcurrentOperationCount_1() {
        let childDelayMicroseconds: useconds_t = 500000 // 0.5 seconds
        let concurrency = ConcurrencyRegistrar()
        let children = (0..<3).map { _ in RegistersWhenRunningOperation(microsecondsToSleep: childDelayMicroseconds, registrar: concurrency) }
        let group = GroupOperation(operations: children)
        group.maxConcurrentOperationCount = 1

        weak var expectation = expectationWithDescription("Test: \(#function); DidFinish Group")
        group.addObserver(DidFinishObserver { observedOperation, errors in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                guard let expectation = expectation else { return }
                expectation.fulfill()
            }
        })

        let startTime = CFAbsoluteTimeGetCurrent()
        runOperation(group)
        waitForExpectationsWithTimeout(4, handler: nil)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = Double(endTime) - Double(startTime)

        XCTAssertEqual(concurrency.maxConcurrentOperationsDetectedCount, 1)
        for i in children.enumerate() {
            XCTAssertTrue(i.element.finished, "Child operation [\(i.index)] did not finish")
        }
        XCTAssertGreaterThanOrEqual(duration, Double(useconds_t(children.count) * childDelayMicroseconds) / 1000000.0)
    }

    func test__group_operation_maxConcurrentOperationCount_2() {
        let childDelayMicroseconds: useconds_t = 500000 // 0.5 seconds
        let concurrency = ConcurrencyRegistrar()
        let children = (0..<3).map { _ in RegistersWhenRunningOperation(microsecondsToSleep: childDelayMicroseconds, registrar: concurrency) }
        let group = GroupOperation(operations: children)
        group.maxConcurrentOperationCount = 2

        weak var expectation = expectationWithDescription("Test: \(#function); DidFinish Group")
        group.addObserver(DidFinishObserver { observedOperation, errors in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                guard let expectation = expectation else { return }
                expectation.fulfill()
            }
        })

        runOperation(group)
        waitForExpectationsWithTimeout(4, handler: nil)

        XCTAssertEqual(concurrency.maxConcurrentOperationsDetectedCount, 2)
        for i in children.enumerate() {
            XCTAssertTrue(i.element.finished, "Child operation [\(i.index)] did not finish")
        }
    }
}

