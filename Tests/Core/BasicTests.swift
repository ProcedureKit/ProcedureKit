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

    func test__queue_delegate_is_notified_when_operation_starts() {
        let expectation = expectationWithDescription("Test: \(#function)")

        let operation = TestOperation()
        addCompletionBlockToTestOperation(operation, withExpectation: expectation)

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(delegate.did_willAddOperation)
        XCTAssertTrue(delegate.did_operationDidFinish)
    }

    func test__executing_basic_operation() {
        let expectation = expectationWithDescription("Test: \(#function)")

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
        let expectation = expectationWithDescription("Test: \(#function)")
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
        let expectation = expectationWithDescription("Test: \(#function)")

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

    func test__adding_array_of_operations() {
        let operations = (0..<3).map { _ in BlockOperation {  } }
        queue.addOperations(operations)
    }

    func test__adding_variable_argument_of_operations() {
        queue.addOperations(BlockOperation { }, BlockOperation { })
    }

    func test__operation_gets_finished_called() {
        let operation = TestOperation()
        waitForOperation(operation)
        XCTAssertTrue(operation.didFinish)
    }
}

class UserIntentOperationTests: OperationTests {

    func test__getting_user_intent_default_background() {
        let operation = TestOperation()
        XCTAssertEqual(operation.userIntent, Operation.UserIntent.None)
    }

    func test__set_user_intent__initiated() {
        let operation = TestOperation()
        operation.userIntent = .Initiated
        XCTAssertEqual(operation.qualityOfService, NSQualityOfService.UserInitiated)
    }

    func test__set_user_intent__side_effect() {
        let operation = TestOperation()
        operation.userIntent = .SideEffect
        XCTAssertEqual(operation.qualityOfService, NSQualityOfService.UserInitiated)
    }

    func test__set_user_intent__initiated_then_background() {
        let operation = TestOperation()
        operation.userIntent = .Initiated
        operation.userIntent = .None
        XCTAssertEqual(operation.qualityOfService, NSQualityOfService.Default)
    }

    func test__user_intent__equality() {
        XCTAssertNotEqual(Operation.UserIntent.Initiated, Operation.UserIntent.SideEffect)
    }
}

class CompletionBlockOperationTests: OperationTests {

    func test__block_operation_with_default_block_runs_completion_block_once() {
        let expectation = expectationWithDescription("Test: \(#function)")
        var numberOfTimesCompletionBlockIsRun = 0

        let operation = BlockOperation()

        operation.completionBlock = {
            numberOfTimesCompletionBlockIsRun += 1
            print("** This is a completion block on \(String.fromCString(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)))")
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
        let expectation = expectationWithDescription("Test: \(#function)")

        let operation = NSBlockOperation()
        operation.completionBlock = { expectation.fulfill() }

        _queue.addOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
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
            let op1Expectation = expectationWithDescription(op1name)
            let op1 = BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
                counter1 += 1
                op1Expectation.fulfill()
                continuation(error: nil)
            }

            let op2name = "Operation 2, iteration: \(i)"
            let op2Expectation = expectationWithDescription(op2name)
            let op2 = BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
                counter2 += 1
                op2Expectation.fulfill()
                continuation(error: nil)
            }

            let op3name = "Operation 3, iteration: \(i)"
            let op3Expectation = expectationWithDescription(op3name)
            let op3 = BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
                counter3 += 1
                op3Expectation.fulfill()
                continuation(error: nil)
            }

            op2.addDependency(op1)
            runOperations(op1, op2, op3)
        }

        waitForExpectationsWithTimeout(6, handler: nil)

        XCTAssertEqual(counter1, count)
        XCTAssertEqual(counter2, count)
        XCTAssertEqual(counter3, count)
    }

    func test__dependencies_execute_before_condition_dependencies() {

        let dependency1 = TestOperation(); dependency1.name = "Dependency 1"
        let dependency2 = TestOperation(); dependency2.name = "Dependency 2"

        let conditionDependency1 = BlockOperation {
            XCTAssertTrue(dependency1.finished)
            XCTAssertTrue(dependency2.finished)
        }
        conditionDependency1.name = "Condition 1 Dependency"
        let condition1 = TestCondition(name: "Condition 1", isMutuallyExclusive: false, dependency: conditionDependency1) { true }

        let conditionDependency2 = BlockOperation {
            XCTAssertTrue(dependency1.finished)
            XCTAssertTrue(dependency2.finished)
        }
        conditionDependency2.name = "Condition 2 Dependency"

        let condition2 = TestCondition(name: "Condition 2", isMutuallyExclusive: false, dependency: conditionDependency2) { true }

        let operation = TestOperation()
        operation.addDependency(dependency1)
        operation.addDependency(dependency2)
        operation.addCondition(condition1)
        operation.addCondition(condition2)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperations(dependency1, dependency2, operation)
        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssertTrue(dependency1.didExecute)
        XCTAssertTrue(dependency1.finished)
        XCTAssertTrue(dependency2.didExecute)
        XCTAssertTrue(dependency2.finished)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.finished)
    }

    func test__dependencies_contains_direct_dependencies_and_indirect_dependencies() {

        let dependency1 = TestOperation()
        let dependency2 = TestOperation()
        let condition1 = TestCondition(name: "Condition 1", isMutuallyExclusive: false, dependency: TestOperation()) { true }
        let condition2 = TestCondition(name: "Condition 2", isMutuallyExclusive: false, dependency: TestOperation()) { true }


        let operation = TestOperation()
        operation.addDependency(dependency1)
        operation.addDependency(dependency2)
        operation.addCondition(condition1)
        operation.addCondition(condition2)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperations(dependency1, dependency2, operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(operation.dependencies.count, 4)
    }

    func test__dependencies_execute_after_previous_mutually_exclusive_operation() {

    }
}

class DelayOperationTests: OperationTests {

    func test__delay_operation_with_interval_name() {
        let delay = DelayOperation(interval: 1)
        XCTAssertEqual(delay.name, "Delay for 1.0 seconds")
    }

    func test__delay_operation_with_date_name() {
        let date = NSDate()
        let delay = DelayOperation(date: date)
        XCTAssertEqual(delay.name, "Delay until \(NSDateFormatter().stringFromDate(date))")
    }

    func test__delay_operation_with_negative_time_interval_finishes_immediately() {
        let expectation = expectationWithDescription("Test: \(#function)")
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
        let expectation = expectationWithDescription("Test: \(#function)")
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
        let expectation = expectationWithDescription("Test: \(#function)")
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

class CancellationOperationTests: OperationTests {

    func test__operation_with_dependency_cancelled_before_adding_still_executes() {

        let delay = DelayOperation(interval: 2)
        let operation = TestOperation()
        operation.addDependency(delay)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))

        delay.cancel()

        runOperations(delay, operation)
        waitForExpectationsWithTimeout(5, handler: nil)

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
