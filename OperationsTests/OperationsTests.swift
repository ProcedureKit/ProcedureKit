//
//  OperationsTests.swift
//  OperationsTests
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit
import XCTest

@testable
import Operations

class TestOperation: Operation {
    
    let numberOfSeconds: Double
    let simulatedError: ErrorType?
    var didExecute: Bool = false
    
    init(delay: Int = 1, error: ErrorType? = .None) {
        numberOfSeconds = Double(delay)
        simulatedError = error
    }

    override func execute() {
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(numberOfSeconds * Double(NSEC_PER_SEC)))
        dispatch_after(after, dispatch_get_main_queue()) {
            self.didExecute = true
            self.finish(self.simulatedError)
        }
    }

    func addCompletionBlockToTestOperation(operation: TestOperation, withExpectation expectation: XCTestExpectation) {
        operation.completionBlock = { [weak operation] in
            if let weakOperation = operation {
                XCTAssertTrue(weakOperation.didExecute)
                expectation.fulfill()
            }
        }
    }
}

class TestQueueDelegate: OperationQueueDelegate {

    typealias DidFinishOperation = (NSOperation, [ErrorType]) -> Void

    let didFinishOperation: DidFinishOperation?

    var did_willAddOperation: Bool = false
    var did_operationDidFinish: Bool = false
    var did_numberOfErrorThatOperationDidFinish: Int = 0

    init(didFinishOperation: DidFinishOperation? = .None) {
        self.didFinishOperation = didFinishOperation
    }

    func operationQueue(queue: OperationQueue, willAddOperation operation: NSOperation) {
        did_willAddOperation = true
    }

    func operationQueue(queue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [ErrorType]) {
        did_operationDidFinish = true
        did_numberOfErrorThatOperationDidFinish = errors.count
        didFinishOperation?(operation, errors)
    }
}

class OperationTests: XCTestCase {
    
    var queue: OperationQueue!
    var delegate: TestQueueDelegate!
    
    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        delegate = TestQueueDelegate()
    }

    override func tearDown() {
        queue = nil
        delegate = nil
        super.tearDown()
    }

    func runOperation(operation: Operation) {
        queue.delegate = delegate
        queue.addOperation(operation)
    }

    func test__queue_delegate_is_notified_when_operation_starts() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        let operation = TestOperation(delay: 1)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(delegate.did_willAddOperation)
        XCTAssertTrue(delegate.did_operationDidFinish)
    }


    func test__executing_basic_operation() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        let operation = TestOperation(delay: 1)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)

        queue.addOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
    }
}

class BlockOperationTests: OperationTests {

    func test__that_block_in_block_operation_executes() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var didExecuteBlock: Bool = false
        let operation = BlockOperation {
            didExecuteBlock = true
            expectation.fulfill()
        }
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__that_block_operation_with_no_block_finishes_immediately() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = BlockOperation()
        operation.addCompletionBlock {
            expectation.fulfill()
        }
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
    }
}

class DelayOperationTests: OperationTests {

    func test__delay_operation_with_negative_time_interval_finishes_immediately() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = DelayOperation(interval: -9_000_000)
        runOperation(operation)
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(after, dispatch_get_main_queue()) {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(operation.finished)
    }

    func test__delay_operation_with_distant_past_finishes_immediately() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = DelayOperation(date: NSDate.distantPast())
        runOperation(operation)
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(after, dispatch_get_main_queue()) {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(operation.finished)
    }

    func test__delay_operation_completes_after_interval() {
        var started: NSDate!
        var ended: NSDate!
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let interval: NSTimeInterval = 1
        let operation = DelayOperation(interval: interval)
        operation.addCompletionBlock {
            ended = NSDate()
            expectation.fulfill()
        }
        started = NSDate()
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
        let timeTaken = ended.timeIntervalSinceDate(started)
        XCTAssertGreaterThanOrEqual(timeTaken, interval)
        XCTAssertLessThanOrEqual(timeTaken - interval, 1.0)
    }
}


