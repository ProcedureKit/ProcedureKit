//
//  RetryOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 30/12/2015.
//
//

import XCTest
@testable import Operations

class OperationWhichFailsThenSucceeds: OldOperation {

    let shouldFail: () -> Bool

    init(shouldFail: () -> Bool) {
        self.shouldFail = shouldFail
        super.init()
        name = "OldOperation Which Fails But Then Succeeds"
    }

    override func execute() {
        if shouldFail() {
            finish(TestOperation.Error.simulatedError)
        }
        else {
            finish()
        }
    }
}

class RetryOperationTests: OperationTests {

    typealias Test = OperationWhichFailsThenSucceeds
    typealias Retry = RetryOperation<Test>
    typealias Handler = Retry.Handler

    var operation: Retry!
    var numberOfExecutions: Int = 0
    var numberOfFailures: Int = 0

    override func setUp() {
        super.setUp()
        numberOfFailures = 0
    }

    func producer(_ threshold: Int) -> () -> Test? {
        return { [unowned self] in
            guard self.numberOfExecutions < 10 else {
                return nil
            }
            let op = Test { return self.numberOfFailures < threshold }
            op.addObserver(WillExecuteObserver { _ in
                self.numberOfFailures += 1
                self.numberOfExecutions += 1
            })
            return op
        }
    }

    func producerWithDelay(_ threshold: Int) -> () -> RepeatedPayload<Test>? {
        return { [unowned self] in
            guard self.numberOfExecutions < 10 else { return nil }

            let op = Test { return self.numberOfFailures < threshold }

            op.addObserver(WillExecuteObserver { _ in
                self.numberOfFailures += 1
                self.numberOfExecutions += 1
            })

            return RepeatedPayload(delay: Delay.by(0.0001), operation: op, configure: .none)
        }
    }

    func test__retry_operation_with_payload_generator() {
        operation = RetryOperation(generator: AnyIterator(producerWithDelay(2)), retry: { $1 })
        operation.log.severity = .verbose

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(operation.count, 2)
    }

    func test__retry_operation_with_default_delay() {
        operation = RetryOperation(AnyIterator(producer(2)))

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(operation.count, 2)
    }

    func test__retry_operation_where_generator_returns_nil() {
        operation = RetryOperation(maxCount: 12, strategy: .fixed(0.01), AnyIterator(producer(11))) { $1 } // Includes the retry block

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(description: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(operation.count, 10)
    }

    func test__retry_operation_where_max_count_is_reached() {
        operation = RetryOperation(AnyIterator(producer(9)))

        waitForOperation(operation)

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(operation.count, 5)
    }

    func test__retry_using_should_retry_block() {

        var retryErrors: [ErrorProtocol]? = .none
        var retryHistoricalErrors: [ErrorProtocol]? = .none
        var retryCount: Int = 0
        var didRunBlockCount: Int = 0

        let retry: Handler = { info, recommended in
            retryErrors = info.errors
            retryHistoricalErrors = info.historicalErrors
            retryCount = info.count
            didRunBlockCount += 1
            return recommended
        }

        operation = RetryOperation(AnyIterator(producer(3)), retry: retry)

        waitForOperation(operation)

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(operation.count, 3)
        XCTAssertEqual(didRunBlockCount, 2)
        XCTAssertNotNil(retryErrors)
        XCTAssertEqual(retryErrors?.count ?? 0, 1)
        XCTAssertNotNil(retryHistoricalErrors)
        XCTAssertEqual(retryHistoricalErrors?.count ?? 0, 1)
        XCTAssertEqual(retryCount, 2)
    }

    func test__retry_using_should_retry_block_with_configure() {

        var retryErrors: [ErrorProtocol]? = .none
        var retryHistoricalErrors: [ErrorProtocol]? = .none
        var retryCount: Int = 0
        var didRunBlockCount: Int = 0
        var didRunResetConfigurationBlock = false

        let retry: Handler = { info, recommended in
            retryErrors = info.errors
            retryHistoricalErrors = info.historicalErrors
            retryCount = info.count
            didRunBlockCount += 1
            return RepeatedPayload(delay: recommended.delay, operation: recommended.operation) { _ in
                didRunResetConfigurationBlock = true
            }
        }

        operation = RetryOperation(AnyIterator(producer(3)), retry: retry)

        waitForOperation(operation)

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(operation.count, 3)
        XCTAssertTrue(didRunResetConfigurationBlock)
        XCTAssertEqual(didRunBlockCount, 2)
        XCTAssertNotNil(retryErrors)
        XCTAssertEqual(retryErrors?.count ?? 0, 1)
        XCTAssertNotNil(retryHistoricalErrors)
        XCTAssertEqual(retryHistoricalErrors?.count ?? 0, 1)
        XCTAssertEqual(retryCount, 2)
    }

    func test__retry_using_retry_block_returning_nil() {
        var retryErrors: [ErrorProtocol]? = .none
        var retryHistoricalErrors: [ErrorProtocol]? = .none
        var retryCount: Int = 0
        var didRunBlockCount: Int = 0
        let retry: Handler = { info, recommended in
            retryErrors = info.errors
            retryHistoricalErrors = info.historicalErrors
            retryCount = info.count
            didRunBlockCount += 1
            return .none
        }

        operation = RetryOperation(AnyIterator(producer(3)), retry: retry)

        waitForOperation(operation)

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(operation.count, 1)
        XCTAssertEqual(didRunBlockCount, 1)
        XCTAssertNotNil(retryErrors)
        XCTAssertEqual(retryErrors?.count ?? 0, 1)
        XCTAssertNotNil(retryHistoricalErrors)
        XCTAssertEqual(retryHistoricalErrors?.count ?? 100, 0)
        XCTAssertEqual(retryCount, 1)
        XCTAssertEqual(operation.errors.count ?? 0, 1)
    }
}
