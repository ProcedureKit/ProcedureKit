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
            let condition = TestCondition(name: "Condition \(i)", isMutuallyExclusive: false, dependency: TestOperation(), condition: { true })
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

}

