//
//  MutualExclusiveTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class MutualExclusiveTests: OperationTests {

    func test__alert_presentation_name() {
        let condition = AlertPresentation()
        XCTAssertEqual(condition.name, "MutuallyExclusive<Alert>")
    }

    func test__alert_presentation_is_mutually_exclusive() {
        let condition = AlertPresentation()
        XCTAssertTrue(condition.isMutuallyExclusive)
    }

    func test__alert_presentation_evaluation_satisfied() {
        let condition = AlertPresentation()
        condition.evaluateForOperation(TestOperation()) { result in
            switch result {
            case .Satisfied:
                return XCTAssertTrue(true)
            default:
                return XCTFail("Alert presentation condition should evaluate true.")
            }
        }
    }

/*  - Disabling this as it's not a very good test.
    - Needs to be refactored.
    func test__mutually_exclusive() {
        let queue = OperationQueue()
        let op1 = TestOperation(delay: 1.0)
        op1.addCondition(MutuallyExclusive<TestOperation>())
        XCTAssertTrue(op1.dependencies.isEmpty)

        let op2 = TestOperation(delay: 1.0)
        op2.addCondition(MutuallyExclusive<TestOperation>())
        XCTAssertTrue(op2.dependencies.isEmpty)

        queue.addOperation(op1)
        queue.addOperation(op2)
        XCTAssertTrue(op1.dependencies.isEmpty)
        XCTAssertEqual(op2.dependencies.first, op1)
    }
*/

}

class MutuallyExclusiveConditionWithDependencyTests: OperationTests {

    func test__condition_has_dependency_executed_first() {
        var text = "Star Wars"
        let condition1 = TestCondition(isMutuallyExclusive: true, dependency: NSBlockOperation {
            text = "\(text)\nA long time ago"
        }) {
            return text ==  "Star Wars\nA long time ago"
        }


        let operation1 = TestOperation()
        operation1.addCondition(condition1)

        let condition2 = TestCondition(isMutuallyExclusive: true, dependency: BlockOperation {
            text = "\(text), in a galaxy far, far away."
        }) {
            return text == "Star Wars\nA long time ago, in a galaxy far, far away."
        }

        let operation2 = TestOperation()
        operation2.addCondition(condition2)

        addCompletionBlockToTestOperation(operation1, withExpectation: expectationWithDescription("Test 1: \(#function)"))
        addCompletionBlockToTestOperation(operation2, withExpectation: expectationWithDescription("Test 2: \(#function)"))

        runOperations(operation1, operation2)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation1.didExecute)
        XCTAssertTrue(operation2.didExecute)
    }

    func test__mutually_exclusive_operations_can_be_executed() {
        let operation1 = BlockOperation()
        operation1.name = "operation 1"
        operation1.addCondition(MutuallyExclusive<BlockOperation>())

        let operation2 = BlockOperation()
        operation1.name = "operation 2"
        operation2.addCondition(MutuallyExclusive<BlockOperation>())

        addCompletionBlockToTestOperation(operation1, withExpectation: expectationWithDescription("Test 1: \(#function)"))
        addCompletionBlockToTestOperation(operation2, withExpectation: expectationWithDescription("Test 2: \(#function)"))

        runOperations(operation1, operation2)
        waitForExpectationsWithTimeout(3, handler: nil)
    }
}
