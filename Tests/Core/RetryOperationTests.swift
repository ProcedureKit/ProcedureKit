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

    var operation: RetryOperation<OperationWhichFailsThenSucceeds>!

    func test__retry_operation() {

        var numberOfFailures = 0
        operation = RetryOperation {
            let op = OperationWhichFailsThenSucceeds { return numberOfFailures < 2 }
            op.addObserver(StartedObserver { _ in
                numberOfFailures += 1
            })
            return op
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.count, 2)
    }

    func test__retry_operation_where_max_count_is_reached() {
        var numberOfFailures = 0
        operation = RetryOperation(maxCount: 5) {
            let op = OperationWhichFailsThenSucceeds { return numberOfFailures < 9 }
            op.addObserver(StartedObserver { _ in
                numberOfFailures += 1
            })
            return op
        }


        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.count, 5)

    }
}
