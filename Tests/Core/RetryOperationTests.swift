//
//  RetryOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 30/12/2015.
//
//

import XCTest
@testable import Operations

class OperationWhichFailsThenSucceeds: Operation {

    let shouldFail: () -> Bool

    init(shouldFail: () -> Bool) {
        self.shouldFail = shouldFail
        super.init()
        name = "Operation Which Fails But Then Succeeds"
    }

    override func execute() {
        if shouldFail() {
            finish(TestOperation.Error.SimulatedError)
        }
        else {
            finish()
        }
    }
}

class RetryOperationTests: OperationTests {

    typealias RetryOp = RetryOperation<OperationWhichFailsThenSucceeds>

    var operation: RetryOp!
    var numberOfFailures: Int = 0

    override func setUp() {
        super.setUp()
        numberOfFailures = 0
    }

    func producer(threshold: Int) -> () -> OperationWhichFailsThenSucceeds {
        return { [unowned self] in
            let op = OperationWhichFailsThenSucceeds { return self.numberOfFailures < threshold }
            op.addObserver(StartedObserver { _ in
                self.numberOfFailures += 1
            })
            return op
        }
    }

    func test__retry_operation() {

        operation = RetryOperation(producer(2))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.count, 2)
    }

    func test__retry_operation_where_max_count_is_reached() {

        operation = RetryOperation(producer(9))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.count, 5)
    }

    func test__retry_using_should_retry_block() {

        var retryErrors: [ErrorType]? = .None
        var retryAggregateErrors: [ErrorType]? = .None
        var retryCount: Int = 0
        var didRunBlockCount: Int = 0
        let retry = { (info: RetryFailureInfo<OperationWhichFailsThenSucceeds>) -> Bool in
            retryErrors = info.errors
            retryAggregateErrors = info.aggregateErrors
            retryCount = info.count
            didRunBlockCount += 1
            return true
        }

        operation = RetryOperation(shouldRetry: retry, producer(3))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.count, 3)
        XCTAssertEqual(didRunBlockCount, 2)
        XCTAssertNotNil(retryErrors)
        XCTAssertEqual(retryErrors!.count, 1)
        XCTAssertNotNil(retryAggregateErrors)
        XCTAssertEqual(retryAggregateErrors!.count, 2)
        XCTAssertEqual(retryCount, 2)
    }

    func test__retry_using_retry_block_returning_false() {
        var retryErrors: [ErrorType]? = .None
        var retryAggregateErrors: [ErrorType]? = .None
        var retryCount: Int = 0
        var didRunBlockCount: Int = 0
        let retry = { (info: RetryFailureInfo<OperationWhichFailsThenSucceeds>) -> Bool in
            retryErrors = info.errors
            retryAggregateErrors = info.aggregateErrors
            retryCount = info.count
            didRunBlockCount += 1
            return false
        }

        operation = RetryOperation(shouldRetry: retry, producer(3))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.count, 1)
        XCTAssertEqual(didRunBlockCount, 1)
        XCTAssertNotNil(retryErrors)
        XCTAssertEqual(retryErrors!.count, 1)
        XCTAssertNotNil(retryAggregateErrors)
        XCTAssertEqual(retryAggregateErrors!.count, 1)
        XCTAssertEqual(retryCount, 1)
    }
}
