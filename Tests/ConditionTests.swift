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
            guard case .success(true) = result else {
                XCTFail("TrueCondition did not evaluate as satisfied."); return
            }
        }
    }

    func test__false_condition_is_failed() {
        let condition = FalseCondition()
        condition.evaluate(procedure: procedure) { result in
            guard case let .failure(error) = result else {
                XCTFail("FalseCondition did not evaluate as failed."); return
            }
            XCTAssertTrue(error is ProcedureKitError.FalseCondition)
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
        XCTAssertProcedureCancelledWithErrors(count: 1)
    }

    // MARK: - Conditions with Dependencies

    func test__dependencies_execute_before_condition_dependencies() {

        let dependency1 = TestProcedure(name: "Dependency 1")
        let dependency2 = TestProcedure(name: "Dependency 2")
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

    func test__target_and_condition_have_same_dependency() {
        let dependency = TestProcedure()
        let condition = TrueCondition(name: "Condition")
        condition.add(dependency: dependency)

        procedure.add(condition: condition)
        procedure.add(dependency: dependency)

        wait(for: dependency, procedure)

        XCTAssertProcedureFinishedWithoutErrors(dependency)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__procedure_is_direct_dependency_and_indirect_of_different_procedures() {
        // See OPR-386
        let dependency = TestProcedure(name: "Dependency")

        let condition1 = TrueCondition(name: "Condition 1")
        condition1.add(dependency: dependency)

        let procedure1 = TestProcedure(name: "Procedure 1")
        procedure1.add(condition: condition1)
        procedure1.add(dependency: dependency)

        let condition2 = TrueCondition(name: "Condition 2")
        condition2.add(dependency: dependency)

        let procedure2 = TestProcedure(name: "Procedure 2")
        procedure2.add(condition: condition2)
        procedure2.add(dependency: procedure1)

        wait(for: procedure1, dependency, procedure2)

        XCTAssertProcedureFinishedWithoutErrors(dependency)
        XCTAssertProcedureFinishedWithoutErrors(procedure1)
        XCTAssertProcedureFinishedWithoutErrors(procedure2)
    }

    // MARK: - Ignored Conditions

    func test__ignored_failing_condition_does_not_result_in_failure() {
        let procedure1 = TestProcedure(name: "Procedure 1")
        procedure1.add(condition: IgnoredCondition(FalseCondition()))

        let procedure2 = TestProcedure(name: "Procedure 2")
        procedure2.add(condition: FalseCondition())

        wait(for: procedure1, procedure2)

        XCTAssertProcedureCancelledWithoutErrors(procedure1)
        XCTAssertProcedureCancelledWithErrors(procedure2, count: 1)
    }

    func test__ignored_satisfied_condition_does_not_result_in_failure() {
        let procedure1 = TestProcedure(name: "Procedure 1")
        procedure1.add(condition: IgnoredCondition(TrueCondition()))

        let procedure2 = TestProcedure(name: "Procedure 2")
        procedure2.add(condition: TrueCondition())

        wait(for: procedure1, procedure2)

        XCTAssertProcedureFinishedWithoutErrors(procedure1)
        XCTAssertProcedureFinishedWithoutErrors(procedure2)

    }

    func test__ignored_ignored_condition_does_not_result_in_failure() {
        procedure.add(condition: IgnoredCondition(IgnoredCondition(FalseCondition())))
        wait(for: procedure)
        XCTAssertProcedureCancelledWithoutErrors()
    }

    // MARK: - Condition Cancellation

    func test__condition_cancelled_before_evaluation_skips_evaluation() {
        var didEvaluateCondition = false
        let condition = TestCondition() {
            didEvaluateCondition = true
            return ConditionResult.success(true)
        }
        procedure.add(condition: condition)
        condition.cancel()
        wait(for: procedure)
        XCTAssertFalse(didEvaluateCondition)
        XCTAssertProcedureCancelledWithoutErrors(procedure)
    }

    func test_condition_cancelled_before_evaluation_but_after_procedure_is_added_to_queue_is_immediately_finished() {
        let dependencySemaphore = DispatchSemaphore(value: 0)
        let dependency = BlockProcedure {
            // prevent the dependency procedure from finishing before signaled
            dependencySemaphore.wait()
        }
        var didEvaluateCondition = false
        let condition = TestCondition() {
            didEvaluateCondition = true
            return ConditionResult.success(true)
        }
        let procedureSemaphore = DispatchSemaphore(value: 0)
        let procedure = BlockProcedure {
            // prevent the main procedure from finishing before signaled (unless cancelled)
            procedureSemaphore.wait()
        }
        procedure.add(condition: condition)
        procedure.add(dependency: dependency)
        check(procedure: procedure, withAdditionalProcedures: dependency) { _ in
            let conditionFinishedSemaphore = DispatchSemaphore(value: 0)
            condition.addDidFinishBlockObserver(block: { (_, _) in
                conditionFinishedSemaphore.signal()
            })
            condition.cancel()
            dependencySemaphore.signal()
            // the condition is now cancelled and should be unblocked from running
            // as its dependency is able to finish
            // wait 1 second to see if the condition finishes
            guard conditionFinishedSemaphore.wait(timeout: .now() + 1.0) == .success else {
                XCTFail("Condition did not finish immediately after it was cancelled.")
                return
            }
        }
        XCTAssertFalse(didEvaluateCondition)
        XCTAssertProcedureCancelledWithoutErrors(procedure)
    }
}

