//
//  NoFailedDependenciesConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class NoFailedDependenciesConditionTests: OperationTests {

    func createCancellingOperation(shouldCancel: Bool) -> TestOperation {

        let operation = TestOperation()
        operation.name = shouldCancel ? "Cancelled Dependency" : "Successful Dependency"

        if shouldCancel {
            operation.addObserver(WillExecuteObserver { op in
                op.cancel()
            })
        }
        return operation
    }

    func test__operation_with_no_dependencies_still_succeeds() {
        let operation = TestOperation()
        operation.addCondition(NoFailedDependenciesCondition())

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
    }

    func test__operation_with_sucessful_dependency_succeeds() {

        let operation = TestOperation()

        let dependency = createCancellingOperation(false)
        operation.addDependency(dependency)
        operation.addCondition(NoFailedDependenciesCondition())

        waitForOperations(operation, dependency)

        XCTAssertTrue(operation.finished)
    }

    func test__operation_with_single_cancelled_dependency_doesnt_execute() {

        let operation = TestOperation()
        let dependency = createCancellingOperation(true)
        operation.addDependency(dependency)
        operation.addCondition(NoFailedDependenciesCondition())

        waitForOperations(operation, dependency)

        XCTAssertFalse(operation.didExecute)
    }

    func test__operation_with_mixture_fails() {
        let operation = TestOperation()

        let dependency1 = createCancellingOperation(true)
        operation.addDependency(dependency1)

        let dependency2 = createCancellingOperation(false)
        operation.addDependency(dependency2)

        operation.addCondition(NoFailedDependenciesCondition())

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_ , errors) in
            receivedErrors = errors
        })

        waitForOperations(operation, dependency1, dependency2)

        XCTAssertFalse(operation.didExecute)
        XCTAssertEqual(receivedErrors.count, 1)
    }

    func test__operation_with_errored_dependency_fails() {

        let operation = TestOperation()

        let dependency = TestOperation(delay: 0, error: TestOperation.Error.SimulatedError)
        operation.addDependency(dependency)
        operation.addCondition(NoFailedDependenciesCondition())

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_ , errors) in
            receivedErrors = errors
        })

        waitForOperations(operation, dependency)

        XCTAssertFalse(operation.didExecute)
        XCTAssertEqual(receivedErrors.count, 1)
    }

    func test__operation_with_group_dependency_with_errored_child_fails() {

        let operation = TestOperation()
        operation.name = "Target Operation"

        let child = TestOperation(delay: 0, error: TestOperation.Error.SimulatedError)
        child.name = "Child Operation"

        let dependency = GroupOperation(operations: [child])
        dependency.name = "Dependency"

        operation.addDependency(dependency)
        operation.addCondition(NoFailedDependenciesCondition())

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_ , errors) in
            receivedErrors = errors
        })

        waitForOperations(operation, dependency)

        XCTAssertFalse(operation.didExecute)
        XCTAssertEqual(receivedErrors.count, 1)
    }

    func test__operation_with_ignore_cancellations() {

        let operation = TestOperation()

        let dependency = createCancellingOperation(true)
        operation.addDependency(dependency)

        operation.addCondition(NoFailedDependenciesCondition(ignoreCancellations: true))

        waitForOperations(operation, dependency)

        XCTAssertFalse(operation.didExecute)
        XCTAssertFalse(operation.failed)
    }

    func test__operation_with_failures_and_cancellations_with_ignore_cancellations() {

        let operation = TestOperation()

        let dependency1 = createCancellingOperation(true)
        operation.addDependency(dependency1)

        let dependency2 = TestOperation(error: TestOperation.Error.SimulatedError)
        operation.addDependency(dependency2)

        let dependency3 = TestOperation()
        operation.addDependency(dependency3)

        operation.addCondition(NoFailedDependenciesCondition(ignoreCancellations: true))

        waitForOperations(operation, dependency1, dependency2, dependency3)

        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.failed)
        XCTAssertEqual(operation.errors.count, 1)
    }


    func test__operation_with_failures_with_ignore_cancellations() {

        let operation = TestOperation()

        let dependency1 = TestOperation(error: TestOperation.Error.SimulatedError)
        operation.addDependency(dependency1)

        let dependency2 = TestOperation(error: TestOperation.Error.SimulatedError)
        operation.addDependency(dependency2)

        let dependency3 = TestOperation()
        operation.addDependency(dependency3)

        operation.addCondition(NoFailedDependenciesCondition(ignoreCancellations: true))

        waitForOperations(operation, dependency1, dependency2, dependency3)

        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.failed)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class NoFailedDependenciesConditionErrorTests: XCTestCase {

    var errorA: NoFailedDependenciesCondition.Error!
    var errorB: NoFailedDependenciesCondition.Error!

    func test__both_cancelled_equal() {
        errorA = .CancelledDependencies
        errorB = .CancelledDependencies
        XCTAssertEqual(errorA, errorB)
    }

    func test__both_failed_equal() {
        errorA = .FailedDependencies
        errorB = .FailedDependencies
        XCTAssertEqual(errorA, errorB)
    }

    func test__cancelled_and_failed_not_equal() {
        errorA = .CancelledDependencies
        errorB = .FailedDependencies
        XCTAssertNotEqual(errorA, errorB)
    }

    func test__failed_and_cancelled_not_equal() {
        errorA = .FailedDependencies
        errorB = .CancelledDependencies
        XCTAssertNotEqual(errorA, errorB)
    }
}
