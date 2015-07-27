//
//  NoCancelledConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations

class NoCancelledConditionTests: OperationTests {

    func createCancellingOperation(shouldCancel: Bool) -> TestOperation {

        let expectation = expectationWithDescription("Dependency for Test: \(__FUNCTION__)")
        let operation = TestOperation()
        operation.name = shouldCancel ? "Cancelled Dependency" : "Successful Dependency"
        operation.addObserver(LoggingObserver())

        if !shouldCancel {
            addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        }
        else {
            operation.addObserver(BlockObserver(startHandler: { op in
                op.cancel()
                expectation.fulfill()
            }))
        }
        return operation
    }

    func test__operation_with_no_dependencies_still_succeeds() {
        let operation = TestOperation()
        operation.addCondition(NoCancelledCondition())

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
    }

    func test__operation_with_sucessful_dependency_succeeds() {

        let operation = TestOperation()
        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        let dependency = createCancellingOperation(false)
        operation.addDependency(dependency)
        operation.addCondition(NoCancelledCondition())

        runOperations(operation, dependency)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
    }

    func test__operation_with_single_cancelled_dependency_doesnt_execute() {

        let operation = TestOperation()
        let dependency = createCancellingOperation(true)
        operation.addDependency(dependency)
        operation.addCondition(NoCancelledCondition())
        operation.addObserver(LoggingObserver())

        runOperations(operation, dependency)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
    }

    func test__operation_with_mixture_fails() {
        let operation = TestOperation()
        let dependency1 = createCancellingOperation(true)
        operation.addDependency(dependency1)
        let dependency2 = createCancellingOperation(false)
        operation.addDependency(dependency2)
        operation.addCondition(NoCancelledCondition())
        operation.addObserver(LoggingObserver())

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_ , errors) in
            receivedErrors = errors
        })

        runOperations(operation, dependency1, dependency2)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
        XCTAssertEqual(receivedErrors.count, 1)
    }


}
