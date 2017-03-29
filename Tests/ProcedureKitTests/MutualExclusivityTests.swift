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
        XCTAssertEqual(condition.mutuallyExclusiveCategories, ["testing"])
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

    func test__mutual_exclusivity_with_dependencies() {
        // The expected result is that procedure1 will run first and, once procedure1
        // has finished, procedure2 will run.
        //
        // Previously, this test resulted in neither procedure finishing (i.e. deadlock).

        // Two procedures that are mutually-exclusive
        let procedure1 = TestProcedure()
        procedure1.add(condition: MutuallyExclusive<TestProcedure>())
        let procedure2 = TestProcedure()
        procedure2.add(condition: MutuallyExclusive<TestProcedure>())

        addCompletionBlockTo(procedures: [procedure1, procedure2])

        // procedure2 will not run until procedure1 is complete
        procedure2.add(dependency: procedure1)

        // add procedure2 to the queue first
        queue.add(operation: procedure2).then(on: DispatchQueue.main) {
            // then add procedure1 to the queue
            self.queue.add(operation: procedure1)
        }

        waitForExpectations(timeout: 2)

        XCTAssertTrue(procedure1.isFinished)
        XCTAssertTrue(procedure2.isFinished)
    }
}



