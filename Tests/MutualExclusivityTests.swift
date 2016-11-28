//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class MutualExclusiveTests: ProcedureKitTestCase {

    func test__mutual_exclusive_name() {
        let condition = MutuallyExclusive<Procedure>()
        XCTAssertEqual(condition.name, "MutuallyExclusive<Procedure>")
    }

    func test__mutual_exclusive_category() {
        let condition = MutuallyExclusive<Procedure>(category: "testing")
        XCTAssertEqual(condition.category, "testing")
    }

    func test__alert_presentation_is_mutually_exclusive() {
        let condition = MutuallyExclusive<Procedure>()
        XCTAssertTrue(condition.isMutuallyExclusive)
    }

    func test__alert_presentation_evaluation_satisfied() {
        let condition = MutuallyExclusive<Procedure>()
        condition.evaluate(procedure: TestProcedure()) { result in
            switch result {
            case .success(true):
                return XCTAssertTrue(true)
            default:
                return XCTFail("Condition should evaluate true.")
            }
        }
    }

    func test__mutually_exclusive_operation_are_run_exclusively() {
        var text = "Star Wars"

        let procedure1 = BlockProcedure {
            XCTAssertEqual(text, "Star Wars")
            text = "\(text)\nA long time ago"
        }
        procedure1.name = "Procedure 1"
        let condition1A = MutuallyExclusive<BlockProcedure>()
        let condition1B = MutuallyExclusive<TestProcedure>()
        procedure1.add(condition: condition1A)
        procedure1.add(condition: condition1B)

        let procedure2 = BlockProcedure {
            XCTAssertEqual(text, "Star Wars\nA long time ago")
            text = "\(text), in a galaxy far, far away."
        }
        procedure2.name = "Procedure 2"
        let condition2A = MutuallyExclusive<BlockProcedure>()
        let condition2B = MutuallyExclusive<TestProcedure>()
        procedure2.add(condition: condition2A)
        procedure2.add(condition: condition2B)

        wait(for: procedure1, procedure2)

        XCTAssertEqual(text, "Star Wars\nA long time ago, in a galaxy far, far away.")
    }

    func test__condition_has_dependency_executed_first() {
        LogManager.severity = .notice
        var text = "Star Wars"

        let conditionDependency1 = BlockProcedure {
            XCTAssertEqual(text, "Star Wars")
            text = "\(text)\nA long time ago"
        }
        conditionDependency1.name = "Condition 1 Dependency"

        let condition1 = TrueCondition(name: "Condition 1", mutuallyExclusiveCategory: "Testing")
        condition1.add(dependency: conditionDependency1)

        let procedure1 = TestProcedure(name: "Procedure 1")
        procedure1.add(condition: condition1)

        let procedure1Dependency = TestProcedure(name: "Dependency 1")
        procedure1.add(dependency: procedure1Dependency)


        let conditionDependency2 = BlockProcedure {
            XCTAssertEqual(text, "Star Wars\nA long time ago")
            text = "\(text), in a galaxy far, far away."
        }
        conditionDependency2.name = "Condition 2 Dependency"

        let condition2 = TrueCondition(name: "Condition 2", mutuallyExclusiveCategory: "Testing")
        condition2.add(dependency: conditionDependency2)

        let procedure2 = TestProcedure(name: "Dependency 2")
        procedure2.add(condition: condition2)

        let procedure2Dependency = TestProcedure(name: "Dependency 2")
        procedure2.add(dependency: procedure2Dependency)

        wait(for: procedure1, procedure2, procedure1Dependency, procedure2Dependency)

        XCTAssertEqual(text, "Star Wars\nA long time ago, in a galaxy far, far away.")
        LogManager.severity = .warning
    }

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

class MutualExclusiveConcurrencyTests: ConcurrencyTestCase {

    func test__mutually_exclusive_operation_are_run_exclusively() {

        let numOperations = 3
        let delayMicroseconds: useconds_t = 500_000 // 0.5 seconds

        queue.maxConcurrentOperationCount = numOperations

        concurrencyTest(operations: numOperations, withDelayMicroseconds: delayMicroseconds, withTimeout: 3,
            withConfigureBlock: { (testOp) in
                let condition = MutuallyExclusive<TrackingProcedure>()
                testOp.add(condition: condition)
                return testOp
            },
            withExpectations: Expectations(
                checkMinimumDetected: 1,
                checkMaximumDetected: 1,
                checkAllProceduresFinished: true,
                checkMinimumDuration: TimeInterval(useconds_t(numOperations) * delayMicroseconds) / 1000000.0
            )
        )
    }

    func test__mutually_exclusive_operations_added_concurrently_are_run_exclusively() {
        // Attempt to add mutually exclusive operations to a queue simultaneously.
        // This should not affect their mutual exclusivity.
        // Covers Issue: https://github.com/ProcedureKit/ProcedureKit/issues/543

        let numOperations = 3
        let delayMicroseconds: useconds_t = 500000 // 0.5 seconds

        queue.maxConcurrentOperationCount = numOperations

        let procedures: [TrackingProcedure] = create(procedures: numOperations, delayMicroseconds: delayMicroseconds, withRegistrar: registrar).map {
            let condition = MutuallyExclusive<TrackingProcedure>()
            $0.add(condition: condition)
            addCompletionBlockTo(procedure: $0, withExpectationDescription: "\($0.name), didFinish")
            return $0
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // add procedures to the queue simultaneously
        let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        for procedure in procedures {
            dispatchQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.queue.addOperation(procedure)
            }
        }

        waitForExpectations(timeout: TimeInterval(numOperations), handler: nil)

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = Double(endTime) - Double(startTime)

        XCTAssertResults(TestResult(procedures: procedures, duration: duration, registrar: registrar),
            matchExpectations: Expectations(
                checkMinimumDetected: 1,
                checkMaximumDetected: 1,
                checkAllProceduresFinished: true,
                checkMinimumDuration: TimeInterval(useconds_t(numOperations) * delayMicroseconds) / 1000000.0
            )
        )
    }
}



