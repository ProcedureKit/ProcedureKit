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

    func test__mutually_exclusive_operation_are_run_exclusively() {
        LogManager.severity = .Verbose
        var text = "Star Wars"

        let operation1 = BlockOperation {
            XCTAssertEqual(text, "Star Wars")
            text = "\(text)\nA long time ago"
        }
        operation1.name = "Operation 1"
        var condition1A = MutuallyExclusive<BlockOperation>(); condition1A.name = "condition 1 A"
        var condition1B = MutuallyExclusive<BlockOperation>(); condition1B.name = "condition 1 B"
        operation1.addCondition(condition1A)
        operation1.addCondition(condition1B)

        let operation2 = BlockOperation {
            XCTAssertEqual(text, "Star Wars\nA long time ago")
            text = "\(text), in a galaxy far, far away."
        }
        operation2.name = "Operation 2"
        var condition2A = MutuallyExclusive<BlockOperation>(); condition2A.name = "condition 2 A"
        var condition2B = MutuallyExclusive<BlockOperation>(); condition2B.name = "condition 2 B"
        operation2.addCondition(condition2A)
        operation2.addCondition(condition2B)

        addCompletionBlockToTestOperation(operation1)
        addCompletionBlockToTestOperation(operation2)
        runOperations(operation1, operation2)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(text, "Star Wars\nA long time ago, in a galaxy far, far away.")
        LogManager.severity = .Verbose
    }
}

class MutuallyExclusiveConditionWithDependencyTests: OperationTests {

    func test__condition_has_dependency_executed_first() {
        var text = "Star Wars"
        let condition1 = TestCondition(name: "Condition 1", isMutuallyExclusive: true, dependency: NSBlockOperation {
            text = "\(text)\nA long time ago"
        }) {
            return text == "Star Wars\nA long time ago"
        }


        let operation1 = TestOperation()
        operation1.addCondition(condition1)

        let condition2 = TestCondition(name: "Condition 1", isMutuallyExclusive: true, dependency: BlockOperation {
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
