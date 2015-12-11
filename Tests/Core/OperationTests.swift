//
//  OperationTests.swift
//  OperationTests
//
//  Created by Daniel Thorpe on 26/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestOperation: Operation {

    enum Error: ErrorType {
        case SimulatedError
    }

    let numberOfSeconds: Double
    let simulatedError: ErrorType?
    let producedOperation: NSOperation?
    var didExecute: Bool = false
    
    init(delay: Double = 0.001, error: ErrorType? = .None, produced: NSOperation? = .None) {
        numberOfSeconds = delay
        simulatedError = error
        producedOperation = produced
        super.init()
    }

    override func execute() {

        if let producedOperation = self.producedOperation {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(numberOfSeconds * Double(0.001) * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Main.queue) {
                self.produceOperation(producedOperation)
            }
        }

        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(numberOfSeconds * Double(NSEC_PER_SEC)))
        dispatch_after(after, Queue.Main.queue) {
            self.didExecute = true
            self.finish(self.simulatedError)
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
        ExclusivityManager.sharedInstance.__tearDownForUnitTesting()
        super.tearDown()
    }

    func runOperation(operation: NSOperation) {
        queue.delegate = delegate
        queue.addOperation(operation)
    }

    func runOperations(operations: Operation...) {
        queue.delegate = delegate
        queue.addOperations(operations, waitUntilFinished: false)
    }

    func addCompletionBlockToTestOperation(operation: Operation, withExpectation expectation: XCTestExpectation) {
        weak var weakExpectation = expectation
        operation.addObserver(BlockObserver { (_, _) in
            weakExpectation?.fulfill()
        })
    }
}

class BasicTests: OperationTests {

    func test__queue_delegate_is_notified_when_operation_starts() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        let operation = TestOperation()
        addCompletionBlockToTestOperation(operation, withExpectation: expectation)

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(delegate.did_willAddOperation)
        XCTAssertTrue(delegate.did_operationDidFinish)
    }

    func test__executing_basic_operation() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        let operation = TestOperation()

        addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
    }

    func test__operation_error_is_equatable() {
        XCTAssertEqual(OperationError.ConditionFailed, OperationError.ConditionFailed)
        XCTAssertEqual(OperationError.OperationTimedOut(1.0), OperationError.OperationTimedOut(1.0))
        XCTAssertNotEqual(OperationError.ConditionFailed, OperationError.OperationTimedOut(1.0))
        XCTAssertNotEqual(OperationError.OperationTimedOut(2.0), OperationError.OperationTimedOut(1.0))
    }

    func test__add_multiple_completion_blocks() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation()

        var completionBlockOneDidRun = 0
        operation.addCompletionBlock {
            completionBlockOneDidRun += 1
        }

        var completionBlockTwoDidRun = 0
        operation.addCompletionBlock {
            completionBlockTwoDidRun += 1
        }

        var finalCompletionBlockDidRun = 0
        operation.addCompletionBlock {
            finalCompletionBlockDidRun += 1
            expectation.fulfill()
        }

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(completionBlockOneDidRun, 1)
        XCTAssertEqual(completionBlockTwoDidRun, 1)
        XCTAssertEqual(finalCompletionBlockDidRun, 1)
    }

    func test__add_multiple_dependencies() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        let dep1 = TestOperation()
        let dep2 = TestOperation()

        let operation = TestOperation()
        operation.addDependencies([dep1, dep2])

        addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        runOperations(dep1, dep2, operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(dep1.didExecute)
        XCTAssertTrue(dep2.didExecute)
    }

    func test__getting_user_initiated_default_false() {
        let operation = TestOperation()
        XCTAssertFalse(operation.userInitiated)
    }

    func test__setting_user_initiated() {
        let operation = TestOperation()
        operation.userInitiated = true
        XCTAssertTrue(operation.userInitiated)
    }

    func test__cancel_with_nil_error() {
        let operation = TestOperation()
        operation.cancelWithError(.None)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__cancel_with_error() {
        let operation = TestOperation()
        operation.cancelWithError(OperationError.OperationTimedOut(1.0))
        XCTAssertTrue(operation.cancelled)
        XCTAssertTrue(operation.failed)
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
        addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
    }
}

private var completionBlockObservationContext = 0

class CompletionBlockOperationTests: OperationTests {

    func test__block_operation_with_default_block_runs_completion_block_once() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var numberOfTimesCompletionBlockIsRun = 0

        let operation = BlockOperation()
        operation.log.severity = .Verbose

        operation.completionBlock = {
            numberOfTimesCompletionBlockIsRun += 1
        }

        let delay = DelayOperation(interval: 0.1)
        delay.addObserver(BlockObserver { op, errors in
            expectation.fulfill()
        })
        delay.addDependency(operation)

        runOperations(delay, operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(numberOfTimesCompletionBlockIsRun, 1)
    }

    func test__nsblockoperation_runs_completion_block_once() {
        let _queue = NSOperationQueue()
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = NSBlockOperation()

        operation.completionBlock = {
            print("*** I'm in a completion block on \(String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)))")
            expectation.fulfill()
        }

        _queue.addOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
    }
}

class DelayOperationTests: OperationTests {

    func test__delay_operation_with_negative_time_interval_finishes_immediately() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = DelayOperation(interval: -9_000_000)
        runOperation(operation)
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
        dispatch_after(after, Queue.Main.queue) {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(operation.finished)
    }

    func test__delay_operation_with_distant_past_finishes_immediately() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = DelayOperation(date: NSDate.distantPast())
        runOperation(operation)
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
        dispatch_after(after, Queue.Main.queue) {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(operation.finished)
    }

    func test__delay_operation_completes_after_interval() {
        var started: NSDate!
        var ended: NSDate!
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let interval: NSTimeInterval = 0.5
        let operation = DelayOperation(interval: interval)
        operation.addCompletionBlock {
            ended = NSDate()
            expectation.fulfill()
        }
        started = NSDate()
        runOperation(operation)
        waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(operation.finished)
        let timeTaken = ended.timeIntervalSinceDate(started)
        XCTAssertGreaterThanOrEqual(timeTaken, interval)
        XCTAssertLessThanOrEqual(timeTaken - interval, 1.0)
    }
}


