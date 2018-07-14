//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
@testable import TestingProcedureKit
@testable import ProcedureKit

class ConditionTests: ProcedureKitTestCase {

    // MARK: - Condition Properties

    func test__condition__produce_dependency() {
        let condition = TrueCondition()
        let dependency = TestProcedure()
        condition.produceDependency(dependency)
        XCTAssertEqual(condition.producedDependencies.count, 1)
        XCTAssertEqual(condition.producedDependencies.first, dependency)
        XCTAssertEqual(condition.dependencies.count, 0)
    }

    func test__condition__add_dependency() {
        let condition = TrueCondition()
        let dependency = TestProcedure()
        condition.addDependency(dependency)
        XCTAssertEqual(condition.dependencies.count, 1)
        XCTAssertEqual(condition.dependencies.first, dependency)
        XCTAssertEqual(condition.producedDependencies.count, 0)
    }

    func test__condition__remove_dependency() {
        let condition = TrueCondition()
        let dependency = TestProcedure()
        let producedDependency = TestProcedure()
        condition.addDependency(dependency)
        condition.produceDependency(producedDependency)
        XCTAssertEqual(condition.dependencies.count, 1)
        XCTAssertEqual(condition.dependencies.first, dependency)
        XCTAssertEqual(condition.producedDependencies.count, 1)
        XCTAssertEqual(condition.producedDependencies.first, producedDependency)

        condition.removeDependency(producedDependency)
        XCTAssertEqual(condition.producedDependencies.count, 0, "Produced dependency not removed.")

        condition.removeDependency(dependency)
        XCTAssertEqual(condition.producedDependencies.count, 0, "Dependency not removed.")
    }

    func test__condition__name() {
        let condition = TrueCondition()
        let testName = "Test Name"
        condition.name = testName
        XCTAssertEqual(condition.name, testName)
    }

    func test__condition__mutually_exclusive_categories() {
        let condition = TrueCondition()
        XCTAssertTrue(condition.mutuallyExclusiveCategories.isEmpty)
        let category1 = "Test Category"
        let category2 = "Test Category B"

        condition.addToAttachedProcedure(mutuallyExclusiveCategory: category1)
        XCTAssertEqual(condition.mutuallyExclusiveCategories, Set([category1]))

        condition.addToAttachedProcedure(mutuallyExclusiveCategory: category2)
        XCTAssertEqual(condition.mutuallyExclusiveCategories, Set([category1, category2]))
    }

    func test__condition__equality() {
        let condition1 = TrueCondition()
        let condition1alias = condition1
        let condition2 = TrueCondition()

        XCTAssertEqual(condition1, condition1)
        XCTAssertEqual(condition1, condition1alias)
        XCTAssertNotEqual(condition1, condition2)
        XCTAssertNotEqual(condition1alias, condition2)
    }

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

    // MARK: - Single Attachment

    func test__single_condition_which_is_satisfied() {
        procedure.addCondition(TrueCondition())
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__single_condition_which_is_failed() {
        procedure.addCondition(FalseCondition())
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    // MARK: - Multiple Attachment

    func test__multiple_conditions_where_all_are_satisfied() {
        procedure.addCondition(TrueCondition())
        procedure.addCondition(TrueCondition())
        procedure.addCondition(TrueCondition())
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__multiple_conditions_where_all_fail() {
        procedure.addCondition(FalseCondition())
        procedure.addCondition(FalseCondition())
        procedure.addCondition(FalseCondition())
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__multiple_conditions_where_one_succeeds() {
        procedure.addCondition(TrueCondition())
        procedure.addCondition(FalseCondition())
        procedure.addCondition(FalseCondition())
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__multiple_conditions_where_one_fails() {
        procedure.addCondition(TrueCondition())
        procedure.addCondition(TrueCondition())
        procedure.addCondition(FalseCondition())
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    // MARK: - Shortcut Processing

    func test__long_running_condition_with_dependency_is_cancelled_if_a_result_is_determined_by_another_condition() {
        // Two conditions:
        //  - One that is dependent on a long-running produced operation
        //  - And a second that immediately returns false
        //
        // The Procedure should fail with the immediate failure of the second
        // Condition, and not wait for the first Condition (and its
        // long-running produced dependency) to also complete.
        //
        // Additionally, the long-running dependency should be cancelled
        // once the overall condition evaluation result is known.

        let longRunningCondition = TestCondition() {
            return .success(true)
        }
        let didStartLongRunningDependencyGroup = DispatchGroup()
        didStartLongRunningDependencyGroup.enter()
        let longRunningDependency = AsyncBlockProcedure { completion in
            didStartLongRunningDependencyGroup.leave()
            // never finishes by itself
        }
        longRunningDependency.addDidCancelBlockObserver { _, _ in
            // finishes when cancelled
            longRunningDependency.finish()
        }
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        longRunningDependency.addDidFinishBlockObserver { _, _ in
            dispatchGroup.leave()
        }
        longRunningCondition.produceDependency(longRunningDependency)

        let failSecondCondition = AsyncTestCondition { completion in
            // To ensure order of operations, finish this condition async once the
            // longRunningCondition's long-running dependency has started.
            //
            // Otherwise, there is no guarantee that the `longRunningCondition` will
            // be processed (and produce its dependencies) prior to being shortcut
            // by the result of this condition.
            didStartLongRunningDependencyGroup.notify(queue: DispatchQueue.global()) {
                completion(.failure(ProcedureKitError.FalseCondition()))
            }
        }

        procedure.addCondition(longRunningCondition)
        procedure.addCondition(failSecondCondition)

        wait(for: procedure, withTimeout: 2)

        // ensure that the longRunningDependency is fairly quickly cancelled and finished
        guard longRunningDependency.isEnqueued else {
            XCTFail("The long-running dependency was not enqueued. This is unexpected, since the evaluation order should be guaranteed by the test.")
            return
        }
        // wait for the long-running dependency to be cancelled and finish
        weak var expLongRunningProducedDependencyCancelled = expectation(description: "did cancel and finish long-running produced dependency")
        dispatchGroup.notify(queue: DispatchQueue.main) {
            expLongRunningProducedDependencyCancelled?.fulfill()
        }
        waitForExpectations(timeout: 2)
        PKAssertProcedureCancelled(longRunningDependency)
    }

    // MARK: - Condition Dependency Requirement

    func test__condition_dependency_requirement_none_still_evaluates_when_dependency_fails() {
        XCTAssertEqual(Condition.DependencyRequirements.none, [])

        let failingDependency = TestProcedure(error: TestError())
        conditionDependencyRequirementTest(
            requirements: .none,
            conditionProducedDependency: failingDependency) { result in
                XCTAssertTrue(result.didEvaluateCondition, "Condition was not evaluated.")
                PKAssertProcedureFinished(result.procedure)
        }
    }

    func test__condition_dependency_requirement_noFailed_skips_evaluate_when_dependency_fails() {
        let failingDependency = TestProcedure(error: TestError())
        conditionDependencyRequirementTest(
            requirements: .noFailed,
            conditionProducedDependency: failingDependency) { result in
                XCTAssertFalse(result.didEvaluateCondition, "Condition evaluate was called, despite dependency requirement and failed dependency.")
                PKAssertProcedureCancelledWithError(result.procedure, ProcedureKitError.ConditionDependenciesFailed(condition: result.condition))
        }
    }

    func test__condition_dependency_requirement_noFailed_ignores_dependency_cancelled_without_errors() {
        let cancelledDependency = TestProcedure()
        cancelledDependency.cancel()
        conditionDependencyRequirementTest(
            requirements: .noFailed,
            conditionProducedDependency: cancelledDependency) { result in
                XCTAssertTrue(result.didEvaluateCondition)
                PKAssertProcedureFinished(result.procedure)
        }
    }

    func test__condition_dependency_requirement_noFailed_skips_evaluate_when_dependency_iscancelled_with_errors() {
        let cancelledDependency = TestProcedure()
        cancelledDependency.cancel(with: TestError())
        conditionDependencyRequirementTest(
            requirements: .noFailed,
            conditionProducedDependency: cancelledDependency) { result in
                XCTAssertFalse(result.didEvaluateCondition)
                PKAssertProcedureCancelledWithError(result.procedure, ProcedureKitError.ConditionDependenciesFailed(condition: result.condition))
        }
    }

    func test__condition_dependency_requirement_noCancelled_skips_evaluate_when_dependency_is_cancelled() {
        let cancelledDependency = TestProcedure(error: TestError())
        cancelledDependency.cancel()
        conditionDependencyRequirementTest(
            requirements: .noCancelled,
            conditionProducedDependency: cancelledDependency) { result in
                XCTAssertFalse(result.didEvaluateCondition, "Condition evaluate was called, despite dependency requirement and cancelled dependency.")
                PKAssertProcedureCancelledWithError(result.procedure, ProcedureKitError.ConditionDependenciesCancelled(condition: result.condition))
        }
    }

    func test__condition_dependency_requirement_noCancelled_ignores_non_cancelled_failures() {
        let failedDependency = TestProcedure(error: TestError()) // failed, not cancelled
        conditionDependencyRequirementTest(
            requirements: .noCancelled,
            conditionProducedDependency: failedDependency) { result in
                XCTAssertTrue(result.didEvaluateCondition)
                PKAssertProcedureFinished(result.procedure)
        }
    }

    func test__condition_dependency_requirement_noFailed_with_ignoreCancellations() {
        // cancelled failing dependency should be ignored - and evaluate should be called
        let cancelledDependency = TestProcedure()
        cancelledDependency.cancel(with: TestError())
        conditionDependencyRequirementTest(
            requirements: [.noFailed, .ignoreFailedIfCancelled],
            conditionProducedDependency: cancelledDependency) { result in
                XCTAssertTrue(result.didEvaluateCondition)
                PKAssertProcedureFinished(result.procedure)
        }

        // whereas a non-cancelled failing dependency should still cause an immediate failure
        let failingDependency = TestProcedure(error: TestError())
        conditionDependencyRequirementTest(
            requirements: [.noFailed, .ignoreFailedIfCancelled],
            conditionProducedDependency: failingDependency) { result in
                XCTAssertFalse(result.didEvaluateCondition)
                PKAssertProcedureCancelledWithError(result.procedure, ProcedureKitError.ConditionDependenciesFailed(condition: result.condition))
        }
    }

    private struct ConditionDependencyRequirementTestResult {
        let procedure: Procedure
        let didEvaluateCondition: Bool
        let condition: Condition
    }

    private func conditionDependencyRequirementTest(
        requirements: Condition.DependencyRequirements,
        conditionProducedDependency dependency: Procedure,
        withAdditionalConditions additionalConditions: [Condition] = [],
        completion: (ConditionDependencyRequirementTestResult) -> Void) {
        conditionDependencyRequirementTest(requirements: requirements,
                                           conditionProducedDependencies: [dependency],
                                           withAdditionalConditions: additionalConditions,
                                           completion: completion)
    }

    private func conditionDependencyRequirementTest(
        requirements: Condition.DependencyRequirements,
        conditionProducedDependencies dependencies: [Procedure],
        withAdditionalConditions additionalConditions: [Condition] = [],
        completion: (ConditionDependencyRequirementTestResult) -> Void)
    {
        let procedure = TestProcedure()

        let didEvaluateConditionGroup = DispatchGroup()
        didEvaluateConditionGroup.enter()
        let condition = TestCondition {
            didEvaluateConditionGroup.leave()
            return .success(true)
        }
        dependencies.forEach(condition.produceDependency)
        condition.dependencyRequirements = requirements

        procedure.addCondition(condition)
        additionalConditions.forEach(procedure.addCondition)
        wait(for: procedure)

        let didEvaluateCondition = didEvaluateConditionGroup.wait(timeout: .now()) == .success

        // clean-up
        if !didEvaluateCondition {
            didEvaluateConditionGroup.leave()
        }

        completion(ConditionDependencyRequirementTestResult(procedure: procedure, didEvaluateCondition: didEvaluateCondition, condition: condition))
    }

    // MARK: - Conditions with Dependencies

    func test__dependencies_execute_before_condition_dependencies() {

        let dependency1 = TestProcedure(name: "Dependency 1")
        let dependency2 = TestProcedure(name: "Dependency 2")
        procedure.addDependencies(dependency1, dependency2)

        let conditionDependency1 = BlockOperation {
            XCTAssertTrue(dependency1.isFinished)
            XCTAssertTrue(dependency2.isFinished)
        }
        conditionDependency1.name = "Condition 1 Dependency"

        let condition1 = TrueCondition(name: "Condition 1")
        condition1.produceDependency(conditionDependency1)


        let conditionDependency2 = BlockOperation {
            XCTAssertTrue(dependency1.isFinished)
            XCTAssertTrue(dependency2.isFinished)
        }
        conditionDependency2.name = "Condition 2 Dependency"

        let condition2 = TrueCondition(name: "Condition 2")
        condition2.produceDependency(conditionDependency2)

        procedure.addCondition(condition1)
        procedure.addCondition(condition2)

        run(operations: dependency1, dependency2)
        wait(for: procedure)

        PKAssertProcedureFinished(dependency1)
        PKAssertProcedureFinished(dependency2)
        PKAssertProcedureFinished(procedure)
    }

    func test__procedure_dependencies_only_contain_direct_dependencies() {

        let dependency1 = TestProcedure()
        let dependency2 = TestProcedure()
        let condition1 = TrueCondition(name: "Condition 1")
        condition1.produceDependency(TestProcedure())
        let condition2 = TrueCondition(name: "Condition 2")
        condition2.produceDependency(TestProcedure())

        procedure.addDependency(dependency1)
        procedure.addDependency(dependency2)
        procedure.addCondition(condition1)
        procedure.addCondition(condition2)

        run(operations: dependency1, dependency2)
        wait(for: procedure)

        XCTAssertEqual(procedure.dependencies.count, 2)
    }

    func test__target_and_condition_have_same_dependency() {
        let dependency = TestProcedure()
        let condition = TrueCondition(name: "Condition")
        condition.addDependency(dependency)

        procedure.addCondition(condition)
        procedure.addDependency(dependency)

        wait(for: dependency, procedure)

        PKAssertProcedureFinished(dependency)
        PKAssertProcedureFinished(procedure)
    }

    func test__procedure_is_direct_dependency_and_indirect_of_different_procedures() {
        // See OPR-386
        let dependency = TestProcedure(name: "Dependency")

        let condition1 = TrueCondition(name: "Condition 1")
        condition1.addDependency(dependency)

        let procedure1 = TestProcedure(name: "Procedure 1")
        procedure1.addCondition(condition1)
        procedure1.addDependency(dependency)

        let condition2 = TrueCondition(name: "Condition 2")
        condition2.addDependency(dependency)

        let procedure2 = TestProcedure(name: "Procedure 2")
        procedure2.addCondition(condition2)
        procedure2.addDependency(procedure1)

        wait(for: procedure1, dependency, procedure2)

        PKAssertProcedureFinished(dependency)
        PKAssertProcedureFinished(procedure1)
        PKAssertProcedureFinished(procedure2)
    }

    func test__dependency_added_by_queue_delegate_will_add_also_affects_evaluating_conditions() {
        // A dependency that is added in a ProcedureQueue delegate's willAddProcedure method
        // should also properly delay the evaluation of Conditions.

        class CustomQueueDelegate: ProcedureQueueDelegate {
            typealias DidAddProcedureBlock = (Procedure) -> Void
            private let dependenciesToAddInWillAdd: [Operation]
            private let didAddProcedureBlock: DidAddProcedureBlock
            init(dependenciesToAddInWillAdd: [Operation], didAddProcedureBlock: @escaping DidAddProcedureBlock) {
                self.dependenciesToAddInWillAdd = dependenciesToAddInWillAdd
                self.didAddProcedureBlock = didAddProcedureBlock
            }
            func procedureQueue(_ queue: ProcedureQueue, willAddProcedure procedure: Procedure, context: Any?) -> ProcedureFuture? {
                let promise = ProcedurePromise()
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { [dependenciesToAddInWillAdd] in
                    defer { promise.complete() }
                    guard !dependenciesToAddInWillAdd.contains(procedure) else { return }
                    procedure.addDependencies(dependenciesToAddInWillAdd)
                }
                return promise.future
            }
            func procedureQueue(_ queue: ProcedureQueue, didAddProcedure procedure: Procedure, context: Any?) {
                didAddProcedureBlock(procedure)
            }
        }

        let procedureDidFinishGroup = DispatchGroup()
        let conditionEvaluatedGroup = DispatchGroup()
        weak var expDependencyDidStart = expectation(description: "Did Start Dependency")
        let dependency = AsyncBlockProcedure { completion in
            DispatchQueue.main.async {
                expDependencyDidStart?.fulfill()
            }
            // does not finish - the test handles that later for timing reasons
        }
        let procedure = TestProcedure()
        procedureDidFinishGroup.enter()
        procedure.addDidFinishBlockObserver { _, _ in
            procedureDidFinishGroup.leave()
        }
        conditionEvaluatedGroup.enter()
        procedure.addCondition(TestCondition(evaluate: {
            // signal when evaluated
            conditionEvaluatedGroup.leave()
            return .success(true)
        }))

        weak var expDidAddProcedure = expectation(description: "Did Add Procedure to queue")
        let customDelegate = CustomQueueDelegate(dependenciesToAddInWillAdd: [dependency]) { addedProcedure in
            // did add Procedure to queue
            guard addedProcedure === procedure else { return }
            DispatchQueue.main.async {
                expDidAddProcedure?.fulfill()
            }
        }
        queue.delegate = customDelegate
        queue.addOperations(procedure, dependency)

        // wait until the procedure has been added to the queue
        // and the dependency has been started
        waitForExpectations(timeout: 2)

        // sleep for 0.05 seconds to give a chance for the Condition to be improperly evaluated
        usleep(50000)

        // verify that the procedure *and the Condition* are not ready to execute,
        // nor executing, nor finished
        // (they should both be waiting on the dependency added in the ProcedureQueue
        // delegate's willAddProcedure handler, which won't finish until it's triggered)

        XCTAssertProcedureIsWaiting(procedure, withDependency: dependency)
        XCTAssertEqual(conditionEvaluatedGroup.wait(timeout: .now()), .timedOut, "The Condition has already evaluated, and did not wait on the dependency.")

        // finish the dependency
        dependency.finish()

        // wait for the procedure to finish
        weak var expProcedureDidFinish = expectation(description: "test procedure Did Finish")
        procedureDidFinishGroup.notify(queue: DispatchQueue.main) {
            expProcedureDidFinish?.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(conditionEvaluatedGroup.wait(timeout: .now()), .success, "The Condition was never evaluated.")
    }

    func test__dependency_added_before_another_dependency_finishes_also_affects_conditions() {
        // A dependency that is added in (for example) an existing dependency's willFinish
        // observer should also properly delay the evaluation of Conditions.

        let procedure = TestProcedure()
        let procedureDidFinishGroup = DispatchGroup()
        let conditionEvaluatedGroup = DispatchGroup()

        weak var expDependencyDidStart = expectation(description: "Did Start additionalDependency")
        let dependency = TestProcedure()
        let additionalDependency = AsyncBlockProcedure { completion in
            DispatchQueue.main.async {
                expDependencyDidStart?.fulfill()
            }
            // does not finish
        }
        dependency.addWillFinishBlockObserver { _, _, _ in
            // add another dependency, before the first dependency finishes
            procedure.addDependency(additionalDependency)
        }

        weak var expDependencyDidFinish = expectation(description: "First dependency did finish")
        dependency.addDidFinishBlockObserver { _, _ in
            DispatchQueue.main.async {
                expDependencyDidFinish?.fulfill()
            }
        }

        procedureDidFinishGroup.enter()
        procedure.addDidFinishBlockObserver { _, _ in
            procedureDidFinishGroup.leave()
        }
        conditionEvaluatedGroup.enter()
        procedure.addCondition(TestCondition(evaluate: {
            // signal when evaluated
            conditionEvaluatedGroup.leave()
            return .success(true)
        }))
        procedure.addDependency(dependency)

        queue.addOperations(procedure, dependency, additionalDependency)

        // wait until the first dependency has finished,
        // and the additionalDependency has started
        waitForExpectations(timeout: 2)

        // sleep for 0.05 seconds to give a chance for the Condition to be improperly evaluated
        usleep(50000)

        // verify that the procedure *and the Condition* are not ready to execute,
        // nor executing, nor finished
        // (they should both be waiting on the dependency added in the ProcedureQueue
        // delegate's willAddProcedure handler, which won't finish until it's triggered)

        XCTAssertProcedureIsWaiting(procedure, withDependency: dependency)
        XCTAssertEqual(conditionEvaluatedGroup.wait(timeout: .now()), .timedOut, "The Condition has already evaluated, and did not wait on the dependency.")

        // finish the additional dependency
        additionalDependency.finish()

        // wait for the procedure to finish
        weak var expProcedureDidFinish = expectation(description: "test procedure Did Finish")
        procedureDidFinishGroup.notify(queue: DispatchQueue.main) {
            expProcedureDidFinish?.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(conditionEvaluatedGroup.wait(timeout: .now()), .success, "The Condition was never evaluated.")
    }

    // Verifies that a Procedure (and its condition evaluator) have a dependency and are waiting
    private func XCTAssertProcedureIsWaiting<T: Procedure>(_ exp: @autoclosure () throws -> T, withDependency dependency: Operation, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {
            let procedure = try exp()

            guard procedure.isEnqueued else {
                return .expectedFailure("\(procedure.procedureName) has not been added to a queue yet.")
            }
            guard procedure.dependencies.contains(dependency) else {
                return .expectedFailure("\(procedure.procedureName) does not have dependency: \(dependency)")
            }
            guard !procedure.isReady else {
                return .expectedFailure("\(procedure.procedureName) is ready")
            }
            guard !procedure.isExecuting else {
                return .expectedFailure("\(procedure.procedureName) is executing")
            }
            guard !procedure.isFinished else {
                return .expectedFailure("\(procedure.procedureName) is finished")
            }
            if !procedure.conditions.isEmpty {
                guard let conditionEvaluator = procedure.evaluateConditionsProcedure else {
                    return .expectedFailure("Unable to obtain condition evaluator from the Procedure.")
                }
                guard conditionEvaluator.dependencies.contains(dependency) else {
                    return .expectedFailure("\(procedure.procedureName)'s condition evaluator does not have dependency: \(dependency)")
                }
                guard !conditionEvaluator.isReady else {
                    return .expectedFailure("\(procedure.procedureName)'s condition evaluator is ready")
                }
                guard !conditionEvaluator.isExecuting else {
                    return .expectedFailure("\(procedure.procedureName)'s condition evaluator is executing")
                }
                guard !conditionEvaluator.isFinished else {
                    return .expectedFailure("\(procedure.procedureName)'s condition evaluator is finished")
                }
            }

            return .success
        }
    }

    // MARK: - Ignored Conditions

    func test__ignored_failing_condition_does_not_result_in_failure() {

        let procedure1 = TestProcedure(name: "Procedure 1")
        procedure1.addCondition(IgnoredCondition(FalseCondition()))

        let procedure2 = TestProcedure(name: "Procedure 2")
        procedure2.addCondition(FalseCondition())

        wait(for: procedure1, procedure2)

        PKAssertProcedureCancelled(procedure1)
        PKAssertProcedureCancelledWithError(procedure2, ProcedureKitError.FalseCondition())
    }

    func test__ignored_satisfied_condition_does_not_result_in_failure() {
        let procedure1 = TestProcedure(name: "Procedure 1")
        procedure1.addCondition(IgnoredCondition(TrueCondition()))

        let procedure2 = TestProcedure(name: "Procedure 2")
        procedure2.addCondition(TrueCondition())

        wait(for: procedure1, procedure2)

        PKAssertProcedureFinished(procedure1)
        PKAssertProcedureFinished(procedure2)
    }

    func test__ignored_ignored_condition_does_not_result_in_failure() {
        procedure.addCondition(IgnoredCondition(IgnoredCondition(FalseCondition())))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    func test__ignored_failing_condition_plus_successful_condition_succeeds() {
        // A Procedure with one or more ignored conditions and at least one
        // successful condition should be allowed to proceed with execution.
        let procedure1 = TestProcedure(name: "Procedure 1")
        procedure1.addCondition(IgnoredCondition(FalseCondition()))
        procedure1.addCondition(TrueCondition())

        wait(for: procedure1)

        PKAssertProcedureFinished(procedure1)
    }
    
    // MARK: - Compound Conditions

    func test__compound_condition_produced_dependencies() {
        let conditions: [Condition] = (0..<3).map {
            let condition = TrueCondition(name: "Condition \($0)")
            condition.produceDependency(TestProcedure())
            return condition
        }
        let compoundCondition = CompoundCondition(andPredicateWith: conditions)
        let nestedProducedDependencies = conditions.producedDependencies
        XCTAssertEqual(nestedProducedDependencies.count, 3)
        XCTAssertEqual(compoundCondition.producedDependencies.count, 0)

        let producedDependency = TestProcedure()
        compoundCondition.produceDependency(producedDependency)
        XCTAssertTrue(Array(compoundCondition.producedDependencies) == [producedDependency])
    }

    func test__compound_condition_added_dependencies() {
        let conditions: [Condition] = (0..<3).map {
            let condition = TrueCondition(name: "Condition \($0)")
            condition.addDependency(TestProcedure())
            return condition
        }
        let compoundCondition = CompoundCondition(andPredicateWith: conditions)
        let nestedDependencies = conditions.dependencies
        XCTAssertEqual(nestedDependencies.count, 3)
        XCTAssertEqual(compoundCondition.dependencies.count, 0)

        let dependency = TestProcedure()
        compoundCondition.addDependency(dependency)
        XCTAssertTrue(Array(compoundCondition.dependencies) == [dependency])
    }

    func test__compound_condition_mutually_exclusive_categories() {
        // give all the conditions the same category
        let conditions: [Condition] = (0..<3).map {
            let condition = TrueCondition(name: "Condition \($0)")
            condition.addToAttachedProcedure(mutuallyExclusiveCategory: "test")
            return condition
        }
        let compoundCondition = CompoundCondition(andPredicateWith: conditions)
        XCTAssertEqual(compoundCondition.mutuallyExclusiveCategories, ["test"])

        // give all the conditions different categories
        let conditions2: [Condition] = (0..<3).map {
            let condition = TrueCondition(name: "Condition \($0)")
            condition.addToAttachedProcedure(mutuallyExclusiveCategory: "test\($0)")
            return condition
        }
        let compoundCondition2 = CompoundCondition(andPredicateWith: conditions2)
        XCTAssertEqual(compoundCondition2.mutuallyExclusiveCategories, ["test0", "test1", "test2"])
    }

    func test__compound_condition_and_predicate_filters_duplicates() {
        let evaluationCount = Protector<Int>(0)
        let condition1 = TestCondition() { evaluationCount.advance(by: 1); return .success(true) }
        let compoundCondition = CompoundCondition(andPredicateWith: condition1, condition1, condition1)
        procedure.addCondition(compoundCondition)
        wait(for: procedure)
        XCTAssertEqual(evaluationCount.access, 1)
    }

    func test__compound_condition_or_predicate_filters_duplicates() {
        let evaluationCount = Protector<Int>(0)
        let condition1 = TestCondition() { evaluationCount.advance(by: 1); return .success(false) }
        let compoundCondition = CompoundCondition(orPredicateWith: condition1, condition1, condition1)
        procedure.addCondition(compoundCondition)
        wait(for: procedure)
        XCTAssertEqual(evaluationCount.access, 1)
    }

    // MARK: - Compound Conditions - &&

    func test__and_condition__with_no_conditions_cancels_without_errors() {
        procedure.addCondition(AndCondition([]))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    func test__and_condition__with_single_successful_condition__succeeds() {
        procedure.addCondition(AndCondition([TrueCondition()]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__and_condition__with_single_failing_condition__fails() {
        procedure.addCondition(AndCondition([FalseCondition()]))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__and_condition__with_single_ignored_condition__does_not_fail() {
        procedure.addCondition(AndCondition([IgnoredCondition(FalseCondition())]))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    func test__and_condition__with_two_successful_conditions__succeeds() {
        procedure.addCondition(AndCondition([TrueCondition(), TrueCondition()]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__and_condition__with_successful_and_failing_conditions__fails() {
        procedure.addCondition(AndCondition([TrueCondition(), FalseCondition()]))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__and_condition__with_failing_and_successful_conditions__fails() {
        procedure.addCondition(AndCondition([FalseCondition(), TrueCondition()]))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__and_condition__with_successful_and_ignored_condition__does_not_fail() {
        procedure.addCondition(AndCondition([IgnoredCondition(FalseCondition()), TrueCondition()]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__and_condition__with_failing_and_ignored_condition__fails() {
        procedure.addCondition(AndCondition([IgnoredCondition(FalseCondition()), FalseCondition()]))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__and_condition__with_two_ignored_conditions__does_not_fail() {
        procedure.addCondition(AndCondition([IgnoredCondition(FalseCondition()), IgnoredCondition(FalseCondition())]))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    func test__nested_successful_and_conditions() {
        procedure.addCondition(AndCondition([AndCondition([TrueCondition(), TrueCondition()]), AndCondition([TrueCondition(), TrueCondition()])]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__nested_failing_and_conditions() {
        procedure.addCondition(AndCondition([AndCondition([FalseCondition(), FalseCondition()]), AndCondition([FalseCondition(), FalseCondition()])]))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__ignored_and_condition_does_not_fail() {
        procedure.addCondition(IgnoredCondition(AndCondition([TrueCondition(), FalseCondition()])))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    // MARK: - Compound Conditions - ||

    func test__or_condition__with_no_conditions_cancels_without_errors() {
        procedure.addCondition(OrCondition([]))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    func test__or_condition__with_single_successful_condition__succeeds() {
        procedure.addCondition(OrCondition([TrueCondition()]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__or_condition__with_single_failing_condition__fails() {
        procedure.addCondition(OrCondition([FalseCondition()]))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__or_condition__with_single_ignored_condition__does_not_fail() {
        procedure.addCondition(OrCondition([IgnoredCondition(FalseCondition())]))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    func test__or_condition__with_two_successful_conditions__succeeds() {
        procedure.addCondition(OrCondition([TrueCondition(), TrueCondition()]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__or_condition__with_successful_and_failing_conditions__succeeds() {
        procedure.addCondition(OrCondition([TrueCondition(), FalseCondition()]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__or_condition__with_failing_and_successful_conditions__succeeds() {
        procedure.addCondition(OrCondition([FalseCondition(), TrueCondition()]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__or_condition__with_successful_and_ignored_condition__succeeds() {
        procedure.addCondition(OrCondition([IgnoredCondition(FalseCondition()), TrueCondition()]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__or_condition__with_failing_and_ignored_condition__fails() {
        procedure.addCondition(OrCondition([IgnoredCondition(FalseCondition()), FalseCondition()]))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
    }

    func test__or_condition__with_two_ignored_conditions__does_not_fail() {
        procedure.addCondition(OrCondition([IgnoredCondition(FalseCondition()), IgnoredCondition(FalseCondition())]))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    func test__nested_successful_or_conditions() {
        procedure.addCondition(OrCondition([OrCondition([TrueCondition(), TrueCondition()]), OrCondition([TrueCondition(), TrueCondition()])]))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__nested_failing_or_conditions() {
        procedure.addCondition(OrCondition([OrCondition([FalseCondition(), FalseCondition()]), OrCondition([FalseCondition(), FalseCondition()])]))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure, withErrors: true)
    }

    func test__ignored_or_condition_does_not_fail() {
        procedure.addCondition(IgnoredCondition(OrCondition([FalseCondition()])))
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    // MARK: - Concurrency

    func test__procedure_cancelled_while_conditions_are_being_evaluated_finishes_before_blocked_condition() {

        class CustomTestCondition: AsyncTestCondition {
            typealias DeinitBlockType = () -> Void
            var deinitBlock: DeinitBlockType? = nil
            deinit {
                deinitBlock?()
            }
        }

        // to allow the Procedures to deallocate as soon as they are done
        // the QueueTestDelegate must be removed (as it holds references)
        queue.delegate = nil

        [true, false].forEach { waitOnEvaluatorReference in

            var procedure: TestProcedure? = TestProcedure()
            let procedureDidFinishGroup = DispatchGroup()
            let customQueue = DispatchQueue(label: "test")
            let conditionGroup = DispatchGroup()
            conditionGroup.enter()
            var condition: CustomTestCondition? = CustomTestCondition { completion in
                // only succeed once the group has been completed
                conditionGroup.notify(queue: customQueue) {
                    completion(.success(true))
                }
            }
            let conditionWillDeinitGroup = DispatchGroup()
            conditionWillDeinitGroup.enter()
            condition!.deinitBlock = {
                conditionWillDeinitGroup.leave()
            }
            procedureDidFinishGroup.enter()
            procedure!.addDidFinishBlockObserver { _, _ in
                procedureDidFinishGroup.leave()
            }
            procedure!.addCondition(condition!)

            // remove local reference to the Condition
            condition = nil

            // then start the procedure
            run(operation: procedure!)

            var evaluateConditionsOperation: Procedure.EvaluateConditions? = nil
            // obtain a reference to the EvaluateConditions operation
            if waitOnEvaluatorReference {
                guard let evaluator = procedure!.evaluateConditionsProcedure else {
                    XCTFail("Unexpectedly no EvaluateConditions procedure")
                    return
                }
                evaluateConditionsOperation = evaluator
            }

            // the Procedure should not finish, as it should be waiting on the Condition to evaluate
            XCTAssertEqual(procedureDidFinishGroup.wait(timeout: .now() + 0.2), .timedOut)

            // cancel the Procedure, which should allow it to rapidly finish
            // (despite the Condition *still* not being completed)
            procedure!.cancel()

            weak var expProcedureDidFinish = expectation(description: "procedure did finish")
            procedureDidFinishGroup.notify(queue: DispatchQueue.main) {
                expProcedureDidFinish?.fulfill()
            }
            waitForExpectations(timeout: 2)

            PKAssertProcedureCancelled(procedure!)

            // remove local reference to the Procedure
            procedure = nil

            // signal for the condition to finally complete
            conditionGroup.leave()

            if waitOnEvaluatorReference {
                // wait for the Condition evaluation to complete
                evaluateConditionsOperation!.waitUntilFinished()

                // verify that the Condition Evaluator was cancelled
                XCTAssertTrue(evaluateConditionsOperation!.isCancelled)
            }
            else {
                // wait for the Condition to begin to deinit
                weak var expConditionWillDeinit = expectation(description: "condition will deinit")
                conditionWillDeinitGroup.notify(queue: DispatchQueue.main) {
                    expConditionWillDeinit?.fulfill()
                }
                waitForExpectations(timeout: 1)

                // then wait for an additional short delay to give the condition
                // evaluator operation a chance to deinit
                weak var expDelayPassed = expectation(description: "delay passed")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    expDelayPassed?.fulfill()
                }
                waitForExpectations(timeout: 1)

                // nothing should have caused a crash
                XCTAssertTrue(true)
            }
        }
    }

    func test__procedure_cancelled_while_conditions_are_being_evaluated_cancels_condition_produced_dependencies() {
        let procedure = TestProcedure()

        // The following order of operations is enforced below:
        //  1. dependentCondition's `conditionProducedDependency` is produced by the dependentCondition,
        //     and is executed (but does not finish)
        //      AND
        //     `normalDependency` is executed (but does not finish)
        //  2. then, `cancelsProcedureCondition` cancels the procedure (while conditions are
        //     being evaluated, and while the condition-produced `conditionProducedDependency` and
        //     the (non-condition-produced) `normalDependency` are executing)

        // The expected result is:
        //  - `conditionProducedDependency` is cancelled (by the Procedure's cancellation propagating
        //    through the active Condition Evaluation to cancel any active condition-produced
        //    dependencies)
        //  - `normalDependency` is not cancelled

        let testDependencyExecutedGroup = DispatchGroup() // signaled once testDependency has executed
        testDependencyExecutedGroup.enter()
        let conditionProducedDependency = AsyncResultProcedure<Bool> { _ in
            testDependencyExecutedGroup.leave()
            // do not finish
        }
        conditionProducedDependency.addDidCancelBlockObserver { conditionProducedDependency, _ in
            // only finish once cancelled
            conditionProducedDependency.finish(withResult: .success(true))
        }

        testDependencyExecutedGroup.enter()
        let normalDependency = AsyncBlockProcedure { _ in
            testDependencyExecutedGroup.leave()
            // do not finish
        }
        let normalDependencyDidFinishGroup = DispatchGroup()
        normalDependencyDidFinishGroup.enter()
        normalDependency.addDidFinishBlockObserver { _, _ in
            normalDependencyDidFinishGroup.leave()
        }

        let cancelsProcedureCondition = AsyncTestCondition { completion in
            // do not do this - this is just to ensure that the procedure cancels in the middle of
            // condition evaluation for this test
            //
            // wait for the dependencies of the other condition to be executed before
            // cancelling the procedure and completing this condition
            testDependencyExecutedGroup.notify(queue: DispatchQueue.global()) {
                procedure.cancel()
                completion(.success(true))
            }
        }

        let dependentCondition = TrueCondition()
        dependentCondition.produceDependency(conditionProducedDependency)
        dependentCondition.addDependency(normalDependency)
        procedure.addCondition(AndCondition(TrueCondition(), dependentCondition, cancelsProcedureCondition))

        // wait on the conditionProducedDependency to finish - but since it is scheduled
        // (and produced) by the dependentCondition, simply add a completion block
        addCompletionBlockTo(procedure: conditionProducedDependency)

        // normalDependency is not expected to finish (nor cancel), so run it and check
        // finish status later (do not wait on it)
        run(operation: normalDependency)

        wait(for: procedure)

        PKAssertProcedureCancelled(procedure)

        // the condition-produced dependency should have been cancelled
        PKAssertProcedureCancelled(conditionProducedDependency)
        XCTAssertTrue(conditionProducedDependency.output.value?.value ?? false)

        // whereas the non-condition-produced dependency should *not* be cancelled, nor finished
        XCTAssertEqual(normalDependencyDidFinishGroup.wait(timeout: .now() + 0.1), .timedOut, "The normal condition dependency finished. It should not be cancelled, nor finished.")
        XCTAssertFalse(normalDependency.isCancelled)

        // clean-up: finish the normalDependency
        normalDependency.finish()
    }

    // MARK: - Execution Timing

    func test__conditions_are_not_evaluated_while_associated_procedurequeue_is_suspended() {

        queue.isSuspended = true

        let conditionWasEvaluatedGroup = DispatchGroup()
        conditionWasEvaluatedGroup.enter()
        let testCondition = TestCondition {
            conditionWasEvaluatedGroup.leave()
            return .success(true)
        }

        procedure.addCondition(testCondition)
        addCompletionBlockTo(procedure: procedure)
        queue.addOperation(procedure)

        XCTAssertTrue(conditionWasEvaluatedGroup.wait(timeout: .now() + 1.0) == .timedOut, "The condition was evaluated, despite the ProcedureQueue being suspended.")

        queue.isSuspended = false
        waitForExpectations(timeout: 3) // wait for the Procedure to finish
        
        PKAssertProcedureFinished(procedure)
        XCTAssertTrue(conditionWasEvaluatedGroup.wait(timeout: .now()) == .success, "The condition was never evaluated.")
    }

    func test__conditions_on_added_children_are_not_evaluated_before_parent_group_executes() {

        let conditionWasEvaluatedGroup = DispatchGroup()
        conditionWasEvaluatedGroup.enter()
        let testCondition = TestCondition {
            conditionWasEvaluatedGroup.leave()
            return .success(true)
        }

        procedure.addCondition(testCondition)
        let group = GroupProcedure(operations: [])
        group.addChild(procedure) // deliberately use add(child:) to test the non-initializer path

        XCTAssertTrue(conditionWasEvaluatedGroup.wait(timeout: .now() + 1.0) == .timedOut, "The condition was evaluated, despite the ProcedureQueue being suspended.")

        wait(for: group)

        PKAssertProcedureFinished(group)
        PKAssertProcedureFinished(procedure)
        XCTAssertTrue(conditionWasEvaluatedGroup.wait(timeout: .now()) == .success, "The condition was never evaluated.")
    }
}

