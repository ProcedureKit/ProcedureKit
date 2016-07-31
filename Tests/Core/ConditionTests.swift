//
//  ConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/04/2016.
//
//

import XCTest
@testable import Operations

class ConditionTests: OperationTests {
    
    var operation: TestOperation!
    
    override func setUp() {
        super.setUp()
        operation = TestOperation()
    }
    
    func test__single_condition_which_is_satisfied() {
        operation.addCondition(TrueCondition())
        waitForOperation(operation)
        XCTAssertTrue(operation.didExecute)
    }
    
    func test__single_condition_which_fails() {
        operation.addCondition(FalseCondition())
        waitForOperation(operation)
        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.errors.count, 1)
    }

    func test__multiple_conditions_where_all_are_satisfied() {
        operation.addCondition(TrueCondition())
        operation.addCondition(TrueCondition())
        operation.addCondition(TrueCondition())
        waitForOperation(operation)
        XCTAssertTrue(operation.didExecute)
    }

    func test__multiple_conditions_where_all_fail() {
        operation.addCondition(FalseCondition())
        operation.addCondition(FalseCondition())
        operation.addCondition(FalseCondition())
        waitForOperation(operation)
        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.errors.count, 3)
    }
    
    func test__multiple_conditions_where_one_succeeds() {
        operation.addCondition(TrueCondition())
        operation.addCondition(FalseCondition())
        operation.addCondition(FalseCondition())
        waitForOperation(operation)
        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.errors.count, 2)
    }

    func test__multiple_conditions_where_one_fails() {
        operation.addCondition(TrueCondition())
        operation.addCondition(TrueCondition())
        operation.addCondition(FalseCondition())
        waitForOperation(operation)
        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.errors.count, 1)
    }
    
    func test__single_condition_with_single_condition_which_both_succeed__executes() {
        let condition = TrueCondition()
        condition.addCondition(TrueCondition())
        operation.addCondition(condition)
        waitForOperation(operation)
        XCTAssertTrue(operation.didExecute)
    }

    func test__single_condition_which_succeeds_with_single_condition_which_fails__cancelled() {
        operation = TestOperation(); operation.name = "Operation 1"
        operation.log.severity = .Verbose
        let condition = TrueCondition(name: "Condition 1")
        condition.addCondition(FalseCondition(name: "Nested Condition 1"))
        operation.addCondition(condition)
        waitForOperation(operation)
        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.errors.count, 2)
    }
    
    func test__dependencies_execute_before_condition_dependencies() {
        
        let dependency1 = TestOperation(); dependency1.name = "Dependency 1"
        let dependency2 = TestOperation(); dependency2.name = "Dependency 2"
        
        let conditionDependency1 = BlockOperation {
            XCTAssertTrue(dependency1.finished)
            XCTAssertTrue(dependency2.finished)
        }
        conditionDependency1.name = "Condition 1 Dependency"
        let condition1 = TrueCondition(name: "Condition 1")
        condition1.addDependency(conditionDependency1)


        let conditionDependency2 = BlockOperation {
            XCTAssertTrue(dependency1.finished)
            XCTAssertTrue(dependency2.finished)
        }
        conditionDependency2.name = "Condition 2 Dependency"
        
        let condition2 = TrueCondition(name: "Condition 2")
        condition2.addDependency(conditionDependency2)

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
        let condition1 = TrueCondition(name: "Condition 1")
        condition1.addDependency(TestOperation())
        let condition2 = TrueCondition(name: "Condition 2")
        condition2.addDependency(TestOperation())
        
        operation.addDependency(dependency1)
        operation.addDependency(dependency2)
        operation.addCondition(condition1)
        operation.addCondition(condition2)
        
        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperations(dependency1, dependency2, operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        
        XCTAssertEqual(operation.dependencies.count, 4)
    }

    func test__target_and_condition_have_same_dependency() {
        let dependency = TestOperation()
        let condition = TrueCondition(name: "Condition")
        condition.addDependency(dependency)

        let operation = TestOperation()
        operation.addCondition(condition)
        operation.addDependency(dependency)

        waitForOperations(operation, dependency)

        XCTAssertTrue(dependency.didExecute)
        XCTAssertTrue(operation.didExecute)
    }

    func test__given_operation_is_direct_dependency_and_indirect_of_different_operations() {
        // See OPR-386
        let dependency = TestOperation(); dependency.name = "Dependency"

        let condition1 = TrueCondition(); condition1.name = "Condition 1"
        condition1.addDependency(dependency)

        let operation1 = TestOperation(); operation1.name = "Operation 1"
        operation1.addCondition(condition1)
        operation1.addDependency(dependency)

        let condition2 = TrueCondition(); condition2.name = "Condition 2"
        condition2.addDependency(dependency)

        let operation2 = TestOperation(); operation2.name = "Operation 2"
        operation2.addCondition(condition2)
        operation2.addDependency(operation1)

        waitForOperations(operation1, dependency, operation2)

        XCTAssertTrue(dependency.didExecute)
        XCTAssertTrue(operation1.didExecute)
        XCTAssertTrue(operation2.didExecute)
    }

    func test__ignored_failing_condition_does_not_result_in_operation_failure() {
        let operation1 = TestOperation(); operation1.name = "Operation 1"
        let operation2 = TestOperation(); operation2.name = "Operation 2"
        operation1.addCondition(IgnoredCondition(FalseCondition()))
        operation2.addCondition(FalseCondition())
        waitForOperations(operation1, operation2)
        XCTAssertFalse(operation1.didExecute)
        XCTAssertFalse(operation2.didExecute)

        XCTAssertFalse(operation1.failed)
        XCTAssertTrue(operation2.failed)
    }

    func test__ignored_satisfied_condition_does_not_result_in_operation_failure() {
        let operation1 = TestOperation()
        let operation2 = TestOperation()
        operation1.addCondition(IgnoredCondition(TrueCondition()))
        operation2.addCondition(TrueCondition())
        waitForOperations(operation1, operation2)
        XCTAssertTrue(operation1.didExecute)
        XCTAssertTrue(operation2.didExecute)

        XCTAssertFalse(operation1.failed)
        XCTAssertFalse(operation2.failed)
    }

    func test__ignored_ignored_condition_does_not_result_in_operation_failure() {
        let operation = TestOperation()
        operation.addCondition(IgnoredCondition(IgnoredCondition(FalseCondition())))
        waitForOperation(operation)
        XCTAssertFalse(operation.didExecute)
        XCTAssertFalse(operation.failed)
    }
}

