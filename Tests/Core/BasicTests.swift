//
//  BasicTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 17/04/2016.
//
//

import XCTest
@testable import Operations

class BasicTests: OperationTests {
    
    var operation: TestOperation!
    
    override func setUp() {
        super.setUp()
        operation = TestOperation()
    }
    
    override func tearDown() {
        operation = nil
        super.tearDown()
    }

    func test__queue_delegate_is_notified_when_operation_starts() {

        waitForOperation(operation)
        
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(delegate.did_willAddOperation)
        XCTAssertTrue(delegate.did_operationDidFinish)
    }

    func test__executing_basic_operation() {
        
        waitForOperation(operation)

        XCTAssertTrue(operation.didExecute)
    }

    func test__operation_error_is_equatable() {
        XCTAssertEqual(OperationError.conditionFailed, OperationError.conditionFailed)
        XCTAssertEqual(OperationError.operationTimedOut(1.0), OperationError.operationTimedOut(1.0))
        XCTAssertNotEqual(OperationError.conditionFailed, OperationError.operationTimedOut(1.0))
        XCTAssertNotEqual(OperationError.operationTimedOut(2.0), OperationError.operationTimedOut(1.0))
    }

    func test__add_multiple_completion_blocks() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")

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

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertEqual(completionBlockOneDidRun, 1)
        XCTAssertEqual(completionBlockTwoDidRun, 1)
        XCTAssertEqual(finalCompletionBlockDidRun, 1)
    }

    func test__add_multiple_dependencies() {

        let dep1 = TestOperation()
        let dep2 = TestOperation()

        operation.addDependencies([dep1, dep2])

        waitForOperations(dep1, dep2, operation)
        
        XCTAssertTrue(dep1.didExecute)
        XCTAssertTrue(dep2.didExecute)
    }

    func test__cancel_with_nil_error() {
        operation.cancelWithError(.none)
        XCTAssertTrue(operation.isCancelled)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__cancel_with_error() {
        operation.cancelWithError(OperationError.operationTimedOut(1.0))
        XCTAssertTrue(operation.isCancelled)
        XCTAssertTrue(operation.failed)
    }

    func test__adding_array_of_operations() {
        let operations = (0..<3).map { _ in Operations.BlockOperation {  } }
        queue.addOperations(operations)
    }

    func test__adding_variable_argument_of_operations() {
        queue.addOperations(Operations.BlockOperation { }, Operations.BlockOperation { })
    }

    func test__operation_gets_finished_called() {
        waitForOperation(operation)
        XCTAssertTrue(operation.operationDidFinishCalled)
    }
    
    func test__operation_will_cancel_called_before_cancelled() {
        var operationWillCancelObserverCalled = false
        operation.addObserver(WillCancelObserver { _, _ in
            XCTAssertTrue(self.operation.operationWillCancelCalled)
            XCTAssertFalse(self.operation.isCancelled)
            XCTAssertFalse(self.operation.operationDidCancelCalled)
            operationWillCancelObserverCalled = true
            })
        operation.cancel()
        waitForOperation(operation)
        XCTAssertTrue(operationWillCancelObserverCalled)
    }
    
    func test__operation_did_cancel_called_before_cancelled() {
        var operationDidCancelObserverCalled = false
        operation.addObserver(DidCancelObserver { _ in
            XCTAssertTrue(self.operation.operationWillCancelCalled)
            XCTAssertTrue(self.operation.isCancelled)
            XCTAssertTrue(self.operation.operationDidCancelCalled)
            operationDidCancelObserverCalled = true
            })
        operation.cancel()
        waitForOperation(operation)
        XCTAssertTrue(operationDidCancelObserverCalled)
    }    
}

class UserIntentOperationTests: OperationTests {

    func test__getting_user_intent_default_background() {
        let operation = TestOperation()
        XCTAssertEqual(operation.userIntent, Operations.Operation.UserIntent.none)
    }

    func test__set_user_intent__initiated() {
        let operation = TestOperation()
        operation.userIntent = .initiated
        XCTAssertEqual(operation.qualityOfService, QualityOfService.userInitiated)
    }

    func test__set_user_intent__side_effect() {
        let operation = TestOperation()
        operation.userIntent = .sideEffect
        XCTAssertEqual(operation.qualityOfService, QualityOfService.userInitiated)
    }

    func test__set_user_intent__initiated_then_background() {
        let operation = TestOperation()
        operation.userIntent = .initiated
        operation.userIntent = .none
        XCTAssertEqual(operation.qualityOfService, QualityOfService.default)
    }

    func test__user_intent__equality() {
        XCTAssertNotEqual(Operations.Operation.UserIntent.initiated, Operations.Operation.UserIntent.sideEffect)
    }
}

class CompletionBlockOperationTests: OperationTests {

    func test__block_operation_with_default_block_runs_completion_block_once() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        var numberOfTimesCompletionBlockIsRun = 0

        let operation = Operations.BlockOperation()

        operation.completionBlock = {
            numberOfTimesCompletionBlockIsRun += 1
            print("** This is a completion block on \(String(cString: DISPATCH_CURRENT_QUEUE_LABEL.label))")
        }

        let delay = DelayOperation(interval: 0.1)
        delay.addObserver(BlockObserver { op, errors in
            expectation.fulfill()
            })
        delay.addDependency(operation)

        runOperations(delay, operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertEqual(numberOfTimesCompletionBlockIsRun, 1)
    }

    func test__nsblockoperation_runs_completion_block_once() {
        let _queue = Foundation.OperationQueue()
        let expectation = self.expectation(withDescription: "Test: \(#function)")

        let operation = Foundation.BlockOperation()
        operation.completionBlock = { expectation.fulfill() }

        _queue.addOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)
    }
}

class OperationDependencyTests: OperationTests {

    func test__dependent_operations_always_run() {
        queue.maxConcurrentOperationCount = 1
        let count = 1_000
        var counter1: Int = 0
        var counter2: Int = 0
        var counter3: Int = 0

        for i in 0..<count {

            let op1name = "Operation 1, iteration: \(i)"
            let op1Expectation = expectation(withDescription: op1name)
            let op1 = Operations.BlockOperation { (continuation: Operations.BlockOperation.ContinuationBlockType) in
                counter1 += 1
                op1Expectation.fulfill()
                continuation(error: nil)
            }

            let op2name = "Operation 2, iteration: \(i)"
            let op2Expectation = expectation(withDescription: op2name)
            let op2 = Operations.BlockOperation { (continuation: Operations.BlockOperation.ContinuationBlockType) in
                counter2 += 1
                op2Expectation.fulfill()
                continuation(error: nil)
            }

            let op3name = "Operation 3, iteration: \(i)"
            let op3Expectation = expectation(withDescription: op3name)
            let op3 = Operations.BlockOperation { (continuation: Operations.BlockOperation.ContinuationBlockType) in
                counter3 += 1
                op3Expectation.fulfill()
                continuation(error: nil)
            }

            op2.addDependency(op1)
            runOperations(op1, op2, op3)
        }

        waitForExpectations(withTimeout: 6, handler: nil)

        XCTAssertEqual(counter1, count)
        XCTAssertEqual(counter2, count)
        XCTAssertEqual(counter3, count)
    }
}

class DelayOperationTests: OperationTests {

    func test__delay_operation_with_interval_name() {
        let delay = DelayOperation(interval: 1)
        XCTAssertEqual(delay.name, "Delay for 1.0 seconds")
    }

    func test__delay_operation_with_date_name() {
        let date = Date()
        let delay = DelayOperation(date: date)
        XCTAssertEqual(delay.name, "Delay until \(DateFormatter().string(from: date))")
    }

    func test__delay_operation_with_negative_time_interval_finishes_immediately() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        let operation = DelayOperation(interval: -9_000_000)
        runOperation(operation)
        let after = DispatchTime.now() + Double(Int64(0.05 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        Queue.main.queue.after(when: after) {
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
        XCTAssertTrue(operation.isFinished)
    }

    func test__delay_operation_with_distant_past_finishes_immediately() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        let operation = DelayOperation(date: Date.distantPast)
        runOperation(operation)
        let after = DispatchTime.now() + Double(Int64(0.05 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        Queue.main.queue.after(when: after) {
            expectation.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
        XCTAssertTrue(operation.isFinished)
    }

    func test__delay_operation_completes_after_interval() {
        var started: Date!
        var ended: Date!
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        let interval: TimeInterval = 0.5
        let operation = DelayOperation(interval: interval)
        operation.addCompletionBlock {
            ended = Date()
            expectation.fulfill()
        }
        started = Date()
        runOperation(operation)
        waitForExpectations(withTimeout: 1, handler: nil)
        XCTAssertTrue(operation.isFinished)
        let timeTaken = ended.timeIntervalSince(started)
        XCTAssertGreaterThanOrEqual(timeTaken, interval)
        XCTAssertLessThanOrEqual(timeTaken - interval, 1.0)
    }
}

class CancellationOperationTests: OperationTests {

    func test__operation_with_dependency_cancelled_before_adding_still_executes() {

        let delay = DelayOperation(interval: 2)
        let operation = TestOperation()
        operation.addDependency(delay)

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))

        delay.cancel()

        runOperations(delay, operation)
        waitForExpectations(withTimeout: 5, handler: nil)

        XCTAssertTrue(operation.didExecute)
    }
    
    
    func test__operation_with_dependency_cancelled_after_adding_does_not_execute() {
        
        let delay = DelayOperation(interval: 2)
        let operation = TestOperation()
        operation.addDependency(delay)
        
        runOperations(delay, operation)
        delay.cancel()
        
        XCTAssertFalse(operation.didExecute)
    }
    
    func test__operation_with_dependency_whole_queue_cancelled() {
        let delay = DelayOperation(interval: 2)
        let operation = TestOperation()
        operation.addDependency(delay)
        
        runOperations(delay, operation)
        queue.cancelAllOperations()
        
        XCTAssertFalse(operation.didExecute)
    }
}
