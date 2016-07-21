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

    func disable_test__completion_blocks() {
        (0..<batchSize).forEach { i in
            let expectation = self.expectation(description: "Interation: \(i)")
            let operation = OldBlockOperation { }
            operation.addCompletionBlock { expectation.fulfill() }
            self.queue.addOperation(operation)
        }
        waitForExpectations(timeout: 5, handler: nil)
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
        // Without the code fix (marked with SR-192) in OldOperationQueue.swift, 
        // this test will crash with EXC_BAD_ACCESS, or sometimes other errors.
        //
        class TestDelegate: OperationQueueDelegate {
            func operationQueue(_ queue: OldOperationQueue, willAddOperation operation: Operation) { /* do nothing */ }
            func operationQueue(_ queue: OldOperationQueue, willFinishOperation operation: Operation, withErrors errors: [ErrorProtocol]) { /* do nothing */ }
            func operationQueue(_ queue: OldOperationQueue, didFinishOperation operation: Operation, withErrors errors: [ErrorProtocol]) { /* do nothing */ }
            func operationQueue(_ queue: OldOperationQueue, willProduceOperation operation: Operation) { /* do nothing */ }
        }
        
        let expectation = self.expectation(description: "Test: \(#function)")
        var success = false
        
        (Queue.initiated.queue).async {
            let group = DispatchGroup()
            for _ in 0..<1000000 {
                let testQueue = OldOperationQueue()
                testQueue.delegate = TestDelegate()
                
                Queue.default.queue.async(group: group) {
                    let _ = testQueue.delegate
                }
                Queue.default.queue.async(group: group) {
                    let _ =  testQueue.delegate
                }
            }
            let _ = group.wait(timeout: .distantFuture)
            success = true
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 60, handler: nil)
        XCTAssertTrue(success)
    }
    
    class Counter {
        private(set) var count: Int32 = 0
        
        @discardableResult
        func increment() -> Int32 {
            return OSAtomicIncrement32(&count)
        }
        
        @discardableResult
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
                let operationDispatchGroup = DispatchGroup()
                weak var didFinishAllOperationsExpectation = expectation(description: "Test: \(#function), Finished All Operations, batch \(batch)")

                (0..<batchSize).forEach { i in
                    operationDispatchGroup.enter()
                    let operationFinishCount = Counter()
                    let operationCancelCount = Counter()
                    let operation = OldBlockOperation { usleep(500) }
                    operation.addObserver(DidCancelObserver(didCancel: { (operation) in
                        operationCancelCount.increment_barrier()
                        cancelCount.increment()
                    }))
                    operation.addObserver(DidFinishObserver(didFinish: { (operation, errors) in
                        let newValue = operationFinishCount.increment_barrier()
                        finishCount.increment_barrier()
                        if newValue == 1 {
                            operationDispatchGroup.leave()
                        }
                    }))
                    self.queue.addOperation(operation)
                    operation.cancel()
                }

                operationDispatchGroup.notify(queue: DispatchQueue.main, execute: {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                waitForExpectations(timeout: batchTimeout, handler: nil)
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
                let queue = OldOperationQueue()
                queue.isSuspended = false
                let finishCount = Counter()
                let operationDispatchGroup = DispatchGroup()
                weak var didFinishAllOperationsExpectation = expectation(description: "Test: \(#function), Finished All Operations, batch \(batch)")

                (0..<batchSize).forEach { _ in
                    operationDispatchGroup.enter()
                    let operationFinishCount = Counter()
                    let currentGroupOperation = GroupOperation(operations: [TestOperation(delay: 0.0)])
                    currentGroupOperation.addObserver(DidFinishObserver(didFinish: { (operation, errors) in
                        let newValue = operationFinishCount.increment_barrier()
                        finishCount.increment_barrier()
                        if newValue == 1 {
                            operationDispatchGroup.leave()
                        }
                    }))
                    queue.addOperation(currentGroupOperation)
                    currentGroupOperation.cancel()
                }

                operationDispatchGroup.notify(queue: DispatchQueue.main, execute: {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                waitForExpectations(timeout: batchTimeout, handler: nil)
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
            let operationsToAddOnExecute: [Operation]
            init(operations: [Operation], operationsToAddOnExecute: [Operation]) {
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
                let queue = OldOperationQueue()
                queue.isSuspended = false
                let operationDispatchGroup = DispatchGroup()
                weak var didFinishAllOperationsExpectation = expectation(description: "Test: \(#function), Finished All Operations, batch \(batch)")

                (0..<batchSize).forEach { i in
                    operationDispatchGroup.enter()
                    let currentGroupOperation = TestGroupOperation_AddOperationAfterSuperInit(operations: [TestOperation()], operationsToAddOnExecute: [TestOperation()])
                    currentGroupOperation.addCompletionBlock({
                        operationDispatchGroup.leave()
                    })
                    queue.addOperation(currentGroupOperation)
                    currentGroupOperation.cancel()
                }

                operationDispatchGroup.notify(queue: DispatchQueue.main, execute: {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                waitForExpectations(timeout: batchTimeout, handler: nil)
                let batchFinishTime = CFAbsoluteTimeGetCurrent()
                let batchDuration = batchFinishTime - batchStartTime
                print ("\(#function): Finished batch: \(batch), in \(batchDuration) seconds")
            }
        }
    }

    func test__repeated_operation_cancel() {
        let batchTimeout = Double(batchSize) / 333.0
        print ("\(#function): Parameters: batch size: \(batchSize); batches: \(batches)")
        
        final class TestOperation3: OldOperation, Repeatable {
            init(number: Int) {
                super.init()
                name = "TestOperation3_\(number)"
            }
            
            override func execute() {
                guard !isCancelled else { return }
                sleep(1)
                finish()
                return
            }
            
            func shouldRepeat(_ count: Int) -> Bool {
                return true
            }
        }
        
        (1...batches).forEach { batch in
            autoreleasepool {
                let batchStartTime = CFAbsoluteTimeGetCurrent()
                let queue = OldOperationQueue()
                queue.isSuspended = false
                let operationDispatchGroup = DispatchGroup()
                weak var didCreateAllOperationsExpectation = expectation(description: "Test: \(#function), Finished Creating Operations, batch \(batch)")
                weak var didFinishAllOperationsExpectation = expectation(description: "Test: \(#function), Finished All Operations, batch \(batch)")
                
                let batchSize = self.batchSize
                Queue.default.queue.async {
                    (0..<batchSize).forEach { i in
                        operationDispatchGroup.enter()
                        
                        let currentGroupOperation = RepeatedOperation<TestOperation3>(strategy: WaitStrategy.immediate, generator: AnyIterator({ TestOperation3(number: i) }))
                        currentGroupOperation.qualityOfService = QualityOfService.default
                        currentGroupOperation.name = "RepeatedOperation_\(i)"
                        currentGroupOperation.addCompletionBlock({
                            operationDispatchGroup.leave()
                        })
                        
                        queue.addOperation(currentGroupOperation)
                        currentGroupOperation.cancel()
                    }
                    guard let didCreateAllOperationsExpectation = didCreateAllOperationsExpectation else { print("Test: \(#function): Finished creating operations after timeout"); return }
                    didCreateAllOperationsExpectation.fulfill()
                }

                operationDispatchGroup.notify(queue: DispatchQueue.main, execute: {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                waitForExpectations(timeout: batchTimeout, handler: nil)
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
                let operationDispatchGroup = DispatchGroup()
                weak var didFinishAllOperationsExpectation = expectation(description: "Test: \(#function), Finished All Operations, batch \(batch)")
                
                (0..<batchSize).forEach { i in
                    operationDispatchGroup.enter()
                    
                    let child1 = TestOperation(delay: 0.4)
                    let child2 = TestOperation(delay: 0.4)
                    let group = GroupOperation(operations: [ child1, child2 ])

                    group.addCompletionBlock {
                        let child1Finished = child1.isFinished
                        let child2Finished = child2.isFinished
                        if child1Finished { child1FinishCount.increment_barrier() }
                        if child2Finished { child2FinishCount.increment_barrier() }
                        operationDispatchGroup.leave()
                    }
                    
                    runOperation(group)
                    group.cancel()
                }
                
                operationDispatchGroup.notify(queue: DispatchQueue.main, execute: {
                    guard let didFinishAllOperationsExpectation = didFinishAllOperationsExpectation else { print("Test: \(#function): Finished operations after timeout"); return }
                    didFinishAllOperationsExpectation.fulfill()
                })
                
                waitForExpectations(timeout: batchTimeout, handler: nil)
                XCTAssertEqual(Int(child1FinishCount.count), batchSize)
                XCTAssertEqual(Int(child2FinishCount.count), batchSize)
                let batchFinishTime = CFAbsoluteTimeGetCurrent()
                let batchDuration = batchFinishTime - batchStartTime
                print ("\(#function): Finished batch: \(batch), in \(batchDuration) seconds")
            }
        }
        
    }
}

