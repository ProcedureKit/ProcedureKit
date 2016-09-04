//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class ConditionTests: ProcedureKitTestCase {

    // MARK: - Condition Unit Tests

    func test__true_condition_is_satisfied() {
        let condition = TrueCondition()
        condition.evaluate(procedure: procedure) { result in
            guard case .satisfied = result else {
                XCTFail("TrueCondition did not evaluate as satisfied."); return
            }
        }
    }

    func test__false_condition_is_failed() {
        let condition = FalseCondition()
        condition.evaluate(procedure: procedure) { result in
            guard case let .failed(error) = result else {
                XCTFail("FalseCondition did not evaluate as failed."); return
            }
            XCTAssertTrue(error is Errors.FalseCondition)
        }
    }

    func test__condition_which_is_executed_without_a_procedure() {
        let condition = TrueCondition()
        wait(for: condition)
        XCTAssertProcedureFinishedWithoutErrors(condition)
    }

    // MARK: - Single Attachment

    func test__single_condition_which_is_satisfied() {
        procedure.add(condition: TrueCondition())
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__single_condition_which_is_failed() {
        procedure.add(condition: FalseCondition())
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors()
    }

    // MARK: - Multiple Attachment

    func test__multiple_conditions_where_all_are_satisfied() {
        procedure.add(condition: TrueCondition())
        procedure.add(condition: TrueCondition())
        procedure.add(condition: TrueCondition())
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__multiple_conditions_where_all_fail() {
        procedure.add(condition: FalseCondition())
        procedure.add(condition: FalseCondition())
        procedure.add(condition: FalseCondition())
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 3)
    }

    func test__multiple_conditions_where_one_succeeds() {
        procedure.add(condition: TrueCondition())
        procedure.add(condition: FalseCondition())
        procedure.add(condition: FalseCondition())
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 2)
    }

    func test__multiple_conditions_where_one_fails() {
        procedure.add(condition: TrueCondition())
        procedure.add(condition: TrueCondition())
        procedure.add(condition: FalseCondition())
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 1)
    }

    // MARK: - Nested Conditions

    func test__single_condition_with_single_condition_which_both_succeed__executes() {
        let condition = TrueCondition()
        condition.add(condition: TrueCondition())
        procedure.add(condition: condition)
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__single_condition_which_succeeds_with_single_condition_which_fails__cancelled() {
        let condition = TrueCondition(name: "Condition 1")
        condition.add(condition: FalseCondition(name: "Nested Condition 1"))
        procedure.add(condition: condition)
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 2)
    }

    // MARK: - Conditions with Dependencies

    func test__dependencies_execute_before_condition_dependencies() {

        let dependency1 = TestProcedure(); dependency1.name = "Dependency 1"
        let dependency2 = TestProcedure(); dependency2.name = "Dependency 2"
        procedure.add(dependencies: dependency1, dependency2)

        let conditionDependency1 = BlockOperation {
            XCTAssertTrue(dependency1.isFinished)
            XCTAssertTrue(dependency2.isFinished)
        }
        conditionDependency1.name = "Condition 1 Dependency"

        let condition1 = TrueCondition(name: "Condition 1")
        condition1.add(dependency: conditionDependency1)


        let conditionDependency2 = BlockOperation {
            XCTAssertTrue(dependency1.isFinished)
            XCTAssertTrue(dependency2.isFinished)
        }
        conditionDependency2.name = "Condition 2 Dependency"

        let condition2 = TrueCondition(name: "Condition 2")
        condition2.add(dependency: conditionDependency2)

        procedure.add(condition: condition1)
        procedure.add(condition: condition2)

        run(operations: dependency1, dependency2)
        wait(for: procedure)

        XCTAssertProcedureFinishedWithoutErrors(dependency1)
        XCTAssertProcedureFinishedWithoutErrors(dependency2)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__dependencies_contains_direct_dependencies_and_indirect_dependencies() {

        let dependency1 = TestProcedure()
        let dependency2 = TestProcedure()
        let condition1 = TrueCondition(name: "Condition 1")
        condition1.add(dependency: TestProcedure())
        let condition2 = TrueCondition(name: "Condition 2")
        condition2.add(dependency: TestProcedure())

        procedure.add(dependency: dependency1)
        procedure.add(dependency: dependency2)
        procedure.add(condition: condition1)
        procedure.add(condition: condition2)

        run(operations: dependency1, dependency2)
        wait(for: procedure)

        XCTAssertEqual(procedure.dependencies.count, 4)
    }

}

