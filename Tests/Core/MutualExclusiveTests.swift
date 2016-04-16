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
        var text = "Star Wars"

        let operation1 = BlockOperation {
            XCTAssertEqual(text, "Star Wars")
            text = "\(text)\nA long time ago"
        }
        operation1.name = "Operation 1"
        let condition1A = MutuallyExclusive<BlockOperation>();
        let condition1B = MutuallyExclusive<TestOperation>();
        operation1.addCondition(condition1A)
        operation1.addCondition(condition1B)

        let operation2 = BlockOperation {
            XCTAssertEqual(text, "Star Wars\nA long time ago")
            text = "\(text), in a galaxy far, far away."
        }
        operation2.name = "Operation 2"
        let condition2A = MutuallyExclusive<BlockOperation>();
        let condition2B = MutuallyExclusive<TestOperation>();
        operation2.addCondition(condition2A)
        operation2.addCondition(condition2B)

        addCompletionBlockToTestOperation(operation1)
        addCompletionBlockToTestOperation(operation2)
        runOperations(operation1, operation2)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(text, "Star Wars\nA long time ago, in a galaxy far, far away.")
    }

    func test__condition_has_dependency_executed_first() {
        var text = "Star Wars"
        LogManager.severity = .Notice

        let conditionDependency1 = BlockOperation {
            XCTAssertEqual(text, "Star Wars")
            text = "\(text)\nA long time ago"
        }
        conditionDependency1.name = "Condition 1 Dependency"

        let condition1 = TestCondition(name: "Condition 1", isMutuallyExclusive: true, dependency: conditionDependency1) { true }

        let operation1 = TestOperation()
        operation1.name = "Operation 1"
        operation1.addCondition(condition1)

        let operation1Dependency = TestOperation()
        operation1Dependency.name = "Dependency 1"
        operation1.addDependency(operation1Dependency)

        let conditionDependency2 = BlockOperation {
            XCTAssertEqual(text, "Star Wars\nA long time ago")
            text = "\(text), in a galaxy far, far away."
        }
        conditionDependency2.name = "Condition 2 Dependency"

        let condition2 = TestCondition(name: "Condition 2", isMutuallyExclusive: true, dependency: conditionDependency2) { true }

        let operation2 = TestOperation()
        operation2.addCondition(condition2)

        let operation2Dependency = TestOperation()
        operation2Dependency.name = "Dependency 2"
        operation2.addDependency(operation2Dependency)

        addCompletionBlockToTestOperation(operation1)
        addCompletionBlockToTestOperation(operation2)
        addCompletionBlockToTestOperation(operation1Dependency)
        addCompletionBlockToTestOperation(operation2Dependency)
        runOperations(operation1, operation2Dependency, operation2, operation1Dependency)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(text, "Star Wars\nA long time ago, in a galaxy far, far away.")

        LogManager.severity = .Warning
    }

    func test__mutually_exclusive_operations_can_be_executed() {
        let operation1 = BlockOperation()
        operation1.name = "operation 1"
        operation1.addCondition(MutuallyExclusive<BlockOperation>())

        let operation2 = BlockOperation()
        operation1.name = "operation 2"
        operation2.addCondition(MutuallyExclusive<BlockOperation>())

        addCompletionBlockToTestOperation(operation1)
        addCompletionBlockToTestOperation(operation2)
        runOperations(operation1, operation2)
        waitForExpectationsWithTimeout(3, handler: nil)
    }
}
