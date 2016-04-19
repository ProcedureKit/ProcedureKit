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
    
    func test__single_condition_which_is_satisfied() {
        let operation = TestOperation()
        operation.addCondition(TrueCondition())
    }
    
    func test__single_condition_which_fails() {
        
    }

    func test__multiple_conditions_where_all_are_satisfied() {
        
    }

    func test__multiple_conditions_where_one_fails() {
        
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
        let condition1 = TrueCondition(name: "Condition 1")
        condition1.addDependency(TestOperation())
        let condition2 = TrueCondition(name: "Condition 2")
        condition2.addDependency(TestOperation())
        
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
