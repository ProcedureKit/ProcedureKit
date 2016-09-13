//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class MutualExclusiveTests: ProcedureKitTestCase {

    func test__mutual_eclusive_name() {
        let condition = MutuallyExclusive<Procedure>()
        XCTAssertEqual(condition.name, "MutuallyExclusive<Procedure>")
    }

    func test__alert_presentation_is_mutually_exclusive() {
        let condition = MutuallyExclusive<Procedure>()
        XCTAssertTrue(condition.mutuallyExclusive)
    }

    func test__alert_presentation_evaluation_satisfied() {
        let condition = MutuallyExclusive<Procedure>()
        condition.evaluate(procedure: TestProcedure()) { result in
            switch result {
            case .satisfied:
                return XCTAssertTrue(true)
            default:
                return XCTFail("Condition should evaluate true.")
            }
        }
    }

/*
    func test__mutually_exclusive_operation_are_run_exclusively() {
        var text = "Star Wars"

        let operation1 = BlockOperation {
            XCTAssertEqual(text, "Star Wars")
            text = "\(text)\nA long time ago"
        }
        operation1.name = "Operation 1"
        let condition1A = MutuallyExclusive<BlockOperation>()
        let condition1B = MutuallyExclusive<TestOperation>()
        operation1.addCondition(condition1A)
        operation1.addCondition(condition1B)

        let operation2 = BlockOperation {
            XCTAssertEqual(text, "Star Wars\nA long time ago")
            text = "\(text), in a galaxy far, far away."
        }
        operation2.name = "Operation 2"
        let condition2A = MutuallyExclusive<BlockOperation>()
        let condition2B = MutuallyExclusive<TestOperation>()
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

        let conditionDependency1 = BlockOperation {
            XCTAssertEqual(text, "Star Wars")
            text = "\(text)\nA long time ago"
        }
        conditionDependency1.name = "Condition 1 Dependency"

        let condition1 = TrueCondition(name: "Condition 1", mutuallyExclusive: true)
        condition1.addDependency(conditionDependency1)

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

        let condition2 = TrueCondition(name: "Condition 2", mutuallyExclusive: true)
        condition2.addDependency(conditionDependency2)

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
    }
*/

    func test__mutually_exclusive_operations_can_be_executed() {
        let procedure1 = TestProcedure()
        procedure1.name = "Procedure 1"
        procedure1.add(condition: MutuallyExclusive<TestProcedure>())

        let procedure2 = TestProcedure()
        procedure2.name = "Procedure 2"
        procedure2.add(condition: MutuallyExclusive<TestProcedure>())

        wait(for: procedure1, procedure2)
    }
}




