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
        LogManager.severity = .Verbose
        operation = TestOperation()
        let condition = TrueCondition(name: "Condition 1")
        condition.addCondition(FalseCondition(name: "Nested Condition 1"))
        operation.addCondition(condition)
        waitForOperation(operation)
        print("*** \(operation.errors)")
        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.errors.count, 2)
        LogManager.severity = .Warning
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
}
