//
//  StressTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 17/04/2016.
//
//

import Foundation
import XCTest
@testable import Operations

class StressTest: OperationTests {

    let batches = 1
    let batchSize = 10_000

    func test__completion_blocks() {
        (0..<batchSize).forEach { i in
            let expectation = self.expectationWithDescription("Interation: \(i)")
            let operation = BlockOperation { }
            operation.addCompletionBlock { expectation.fulfill() }
            self.queue.addOperation(operation)
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func test__conditions() {
        let operation = TestOperation()
        (0..<batchSize).forEach { i in
            operation.addCondition(TrueCondition())
        }
        addCompletionBlockToTestOperation(operation)
        waitForOperation(operation)
        XCTAssertTrue(operation.didExecute)
    }

    func test__conditions_with_single_dependency() {
        let operation = TestOperation()
        (0..<batchSize).forEach { i in
            let condition = TestConditionOperation(dependencies: [TestOperation()]) { true }
            condition.name = "Condition \(i)"
            operation.addCondition(condition)
        }
        addCompletionBlockToTestOperation(operation)
        waitForOperation(operation)
        XCTAssertTrue(operation.didExecute)
    }
    
    func test__SR_192_OperationQueue_delegate_weak_var_thread_safety() {
        //
        // (SR-192): Weak properties are not thread safe when reading
        // https://bugs.swift.org/browse/SR-192
        //
        // Affects: Swift < 3
        // Fixed in: Swift 3.0+
        // Without the code fix (marked with SR-192) in OperationQueue.swift, 
        // this test will crash with EXC_BAD_ACCESS, or sometimes other errors.
        //
        class TestDelegate: OperationQueueDelegate {
            func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) { /* do nothing */ }
            func operationQueue(queue: OperationQueue, willFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) { /* do nothing */ }
            func operationQueue(queue: OperationQueue, didFinishOperation operation: NSOperation, withErrors errors: [ErrorType]) { /* do nothing */ }
            func operationQueue(queue: OperationQueue, willProduceOperation operation: NSOperation) { /* do nothing */ }
        }
        
        let expectation = expectationWithDescription("Test: \(#function)")
        var success = false
        
        dispatch_async(Queue.Initiated.queue) {
            let group = dispatch_group_create()
            for _ in 0..<1000000 {
                let testQueue = OperationQueue()
                testQueue.delegate = TestDelegate()
                dispatch_group_async(group, dispatch_get_global_queue(0, 0), {
                    let _ = testQueue.delegate
                })
                dispatch_group_async(group, dispatch_get_global_queue(0, 0), {
                    let _ = testQueue.delegate
                })
            }
            dispatch_group_wait(group,DISPATCH_TIME_FOREVER)
            success = true
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(60, handler: nil)
        XCTAssertTrue(success)
    }
    
    class Counter {
        private(set) var count: Int32 = 0
        func increment() -> Int32 {
            return OSAtomicIncrement32(&count)
        }
        func increment_barrier() -> Int32 {
            return OSAtomicIncrement32Barrier(&count)
        }
    }

    func test__block_operation_cancel() {
        let batchTimeout = Double(batchSize) / 750.0
        print ("\(#function): Parameters: batch size: \(batchSize); batches: \(batches)")
        assert(batchSize <= Int(Int32.max), "Test uses OSAtomicIncrement32, and doesn't support batchSize > Int32.max")
        // NOTE: This test previously crashed most commonly with EXC_BAD_ACCESS.

        (1...batches).forEach { batch in
            autoreleasepool {
                let batchStartTime = CFAbsoluteTimeGetCurrent()
                let cancelCount = Counter()
                let finishCount = Counter()
                let operationDispatchGroup = dispatch_group_create()
                weak var didFinishAllOperationsExpectation = expectationWithDescription("Test: \(#function), Finished All Operations, batch \(batch)")

                (0..<batchSize).forEach { i in
                    dispatch_group_enter(operationDispatchGroup)
                    let operationFinishCount = Counter()
                    let operationCancelCount = Counter()
                    let operation = BlockOperation { usleep(500) }
                    operation.addObserver(DidCancelObserver(didCancel: { (operation) in
                        operationCancelCount.increment_barrier()
                        cancelCount.increment()
                    }))
                    operation.addObserver(DidFinishObserver(didFinish: { (operation, errors) in
                        let newValue = operationFinishCount.increment_barrier()
                        finishCount.increment_barrier()
                        if newValue == 1 {
                            dispatch_group_leave(operationDispatchGroup)
                        }
                    }))
                    self.queue.addOperation(operation)
                    operation.cancel()
                }

                dispatch_group_notify(operationDispatchGroup, dispatch_get_main_queue(), {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                waitForExpectationsWithTimeout(batchTimeout, handler: nil)
                XCTAssertEqual(Int(cancelCount.count), batchSize)
                XCTAssertEqual(Int(finishCount.count), batchSize)
                let batchFinishTime = CFAbsoluteTimeGetCurrent()
                let batchDuration = batchFinishTime - batchStartTime
                print ("\(#function): Finished batch: \(batch), in \(batchDuration) seconds")
            }
        }
    }

    func test__group_operation_cancel() {
        let batchTimeout = Double(batchSize) / 750.0
        print ("\(#function): Parameters: batch size: \(batchSize); batches: \(batches)")

        (1...batches).forEach { batch in
            autoreleasepool {
                let batchStartTime = CFAbsoluteTimeGetCurrent()
                let queue = OperationQueue()
                queue.suspended = false
                let finishCount = Counter()
                let operationDispatchGroup = dispatch_group_create()
                weak var didFinishAllOperationsExpectation = expectationWithDescription("Test: \(#function), Finished All Operations, batch \(batch)")

                (0..<batchSize).forEach { _ in
                    dispatch_group_enter(operationDispatchGroup)
                    let operationFinishCount = Counter()
                    let currentGroupOperation = GroupOperation(operations: [TestOperation(delay: 0.0)])
                    currentGroupOperation.addObserver(DidFinishObserver(didFinish: { (operation, errors) in
                        let newValue = operationFinishCount.increment_barrier()
                        finishCount.increment_barrier()
                        if newValue == 1 {
                            dispatch_group_leave(operationDispatchGroup)
                        }
                    }))
                    queue.addOperation(currentGroupOperation)
                    currentGroupOperation.cancel()
                }

                dispatch_group_notify(operationDispatchGroup, dispatch_get_main_queue(), {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                waitForExpectationsWithTimeout(batchTimeout, handler: nil)
                XCTAssertEqual(Int(finishCount.count), batchSize)
                let batchFinishTime = CFAbsoluteTimeGetCurrent()
                let batchDuration = batchFinishTime - batchStartTime
                print ("\(#function): Finished batch: \(batch), in \(batchDuration) seconds")
            }
        }
    }

    func test__group_operation_cancel_and_add_operation() {
        let batchTimeout = Double(batchSize) / 333.0
        print ("\(#function): Parameters: batch size: \(batchSize); batches: \(batches)")
        
        final class TestGroupOperation_AddOperationAfterSuperInit: GroupOperation {
            let operationsToAddOnExecute: [NSOperation]
            init(operations: [NSOperation], operationsToAddOnExecute: [NSOperation]) {
                self.operationsToAddOnExecute = operationsToAddOnExecute
                super.init(operations:[])
                self.name = "TestGroupOperation_AddOperationAfterSuperInit"
                self.addOperations(operations)  // add operations in init, after super.init()
            }
            
            override func execute() {
                addOperations(operationsToAddOnExecute) // add operations in execute
                super.execute()
            }
        }

        (1...batches).forEach { batch in
            autoreleasepool {
                let batchStartTime = CFAbsoluteTimeGetCurrent()
                let queue = OperationQueue()
                queue.suspended = false
                let operationDispatchGroup = dispatch_group_create()
                weak var didFinishAllOperationsExpectation = expectationWithDescription("Test: \(#function), Finished All Operations, batch \(batch)")

                (0..<batchSize).forEach { i in
                    dispatch_group_enter(operationDispatchGroup)
                    let currentGroupOperation = TestGroupOperation_AddOperationAfterSuperInit(operations: [TestOperation()], operationsToAddOnExecute: [TestOperation()])
                    currentGroupOperation.addCompletionBlock({
                        dispatch_group_leave(operationDispatchGroup)
                    })
                    queue.addOperation(currentGroupOperation)
                    currentGroupOperation.cancel()
                }

                dispatch_group_notify(operationDispatchGroup, dispatch_get_main_queue(), {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                waitForExpectationsWithTimeout(batchTimeout, handler: nil)
                let batchFinishTime = CFAbsoluteTimeGetCurrent()
                let batchDuration = batchFinishTime - batchStartTime
                print ("\(#function): Finished batch: \(batch), in \(batchDuration) seconds")
            }
        }
    }

    func test__repeated_operation_cancel() {
        let batchTimeout = Double(batchSize) / 333.0
        print ("\(#function): Parameters: batch size: \(batchSize); batches: \(batches)")
        
        final class TestOperation3: Operation, Repeatable {
            init(number: Int) {
                super.init()
                name = "TestOperation3_\(number)"
            }
            
            override func execute() {
                guard !cancelled else { return }
                sleep(1)
                finish()
                return
            }
            
            func shouldRepeat(count: Int) -> Bool {
                return true
            }
        }
        
        (1...batches).forEach { batch in
            autoreleasepool {
                let batchStartTime = CFAbsoluteTimeGetCurrent()
                let queue = OperationQueue()
                queue.suspended = false
                let operationDispatchGroup = dispatch_group_create()
                weak var didCreateAllOperationsExpectation = expectationWithDescription("Test: \(#function), Finished Creating Operations, batch \(batch)")
                weak var didFinishAllOperationsExpectation = expectationWithDescription("Test: \(#function), Finished All Operations, batch \(batch)")
                
                let batchSize = self.batchSize
                dispatch_async(Queue.Default.queue) {
                    (0..<batchSize).forEach { i in
                        dispatch_group_enter(operationDispatchGroup)
                        
                        let currentGroupOperation = RepeatedOperation<TestOperation3>(strategy: WaitStrategy.Immediate, generator: AnyGenerator(body: { TestOperation3(number: i)
                        }))
                        currentGroupOperation.qualityOfService = NSQualityOfService.Default
                        currentGroupOperation.name = "RepeatedOperation_\(i)"
                        currentGroupOperation.addCompletionBlock({
                            dispatch_group_leave(operationDispatchGroup)
                        })
                        
                        queue.addOperation(currentGroupOperation)
                        currentGroupOperation.cancel()
                    }
                    guard let didCreateAllOperationsExpectation = didCreateAllOperationsExpectation else { print("Test: \(#function): Finished creating operations after timeout"); return }
                    didCreateAllOperationsExpectation.fulfill()
                }

                dispatch_group_notify(operationDispatchGroup, dispatch_get_main_queue(), {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                waitForExpectationsWithTimeout(batchTimeout, handler: nil)
                let batchFinishTime = CFAbsoluteTimeGetCurrent()
                let batchDuration = batchFinishTime - batchStartTime
                print ("\(#function): Finished batch: \(batch), in \(batchDuration) seconds")
            }
        }
    }

    func test__group_operation__does_not_finish_before_child_operations_are_finished() {
        let batchTimeout = Double(batchSize) / 750.0
        print ("\(#function): Parameters: batch size: \(batchSize); batches: \(batches)")
        
        (1...batches).forEach { batch in
            autoreleasepool {
                let batchStartTime = CFAbsoluteTimeGetCurrent()
                let child1FinishCount = Counter()
                let child2FinishCount = Counter()
                let operationDispatchGroup = dispatch_group_create()
                weak var didFinishAllOperationsExpectation = expectationWithDescription("Test: \(#function), Finished All Operations, batch \(batch)")
                
                (0..<batchSize).forEach { i in
                    dispatch_group_enter(operationDispatchGroup)
                    
                    let child1 = TestOperation(delay: 0.4)
                    let child2 = TestOperation(delay: 0.4)
                    let group = GroupOperation(operations: [ child1, child2 ])

                    group.addCompletionBlock {
                        let child1Finished = child1.finished
                        let child2Finished = child2.finished
                        if child1Finished { child1FinishCount.increment_barrier() }
                        if child2Finished { child2FinishCount.increment_barrier() }
                        dispatch_group_leave(operationDispatchGroup)
                    }
                    
                    runOperation(group)
                    group.cancel()
                }
                
                dispatch_group_notify(operationDispatchGroup, dispatch_get_main_queue(), {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                
                waitForExpectationsWithTimeout(batchTimeout, handler: nil)
                XCTAssertEqual(Int(child1FinishCount.count), batchSize)
                XCTAssertEqual(Int(child2FinishCount.count), batchSize)
                let batchFinishTime = CFAbsoluteTimeGetCurrent()
                let batchDuration = batchFinishTime - batchStartTime
                print ("\(#function): Finished batch: \(batch), in \(batchDuration) seconds")
            }
        }
        
    }
}

