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

    func test__procedure_mutual_exclusivity_internal_API_contract() {
        class CustomProcedureQueue: ProcedureQueue {
            typealias RequestLockObserver = (Set<String>) -> Void
            typealias ProcedureClaimLockObserver = (ExclusivityLockTicket) -> Void
            typealias UnlockObservers = (Set<String>) -> Void

            private let requestLockCallback: RequestLockObserver
            private let procedureClaimLockCallback: ProcedureClaimLockObserver
            private let unlockCallback: UnlockObservers

            init(requestLock: @escaping RequestLockObserver, procedureClaimLock: @escaping ProcedureClaimLockObserver, unlock: @escaping UnlockObservers) {
                requestLockCallback = requestLock
                procedureClaimLockCallback = procedureClaimLock
                unlockCallback = unlock
            }

            internal override func requestLock(for mutuallyExclusiveCategories: Set<String>, completion: @escaping (ExclusivityLockTicket) -> Void) {
                DispatchQueue.main.async {
                    self.requestLockCallback(mutuallyExclusiveCategories)
                    super.requestLock(for: mutuallyExclusiveCategories, completion: completion)
                }
            }

            internal override func procedureClaimLock(withTicket ticket: ExclusivityLockTicket, completion: @escaping () -> Void) {
                DispatchQueue.main.async {
                    self.procedureClaimLockCallback(ticket)
                    super.procedureClaimLock(withTicket: ticket, completion: completion)
                }
            }

            internal override func unlock(mutuallyExclusiveCategories categories: Set<String>) {
                DispatchQueue.main.async {
                    self.unlockCallback(categories)
                    super.unlock(mutuallyExclusiveCategories: categories)
                }
            }
        }

        struct DummyExclusivity { }

        let calledRequestLock = Protector(false)
        let calledProcedureClaimLock = Protector(false)
        let calledUnlock = Protector(false)

        let procedure = TestProcedure()
        let mutuallyExclusiveConditions = [MutuallyExclusive<TestProcedure>(), MutuallyExclusive<DummyExclusivity>()]
        let expectedMutuallyExclusiveCategories = Set(mutuallyExclusiveConditions.map { $0.mutuallyExclusiveCategories }.joined())
        print("\(expectedMutuallyExclusiveCategories)")
        mutuallyExclusiveConditions.forEach { procedure.add(condition: $0) }

        procedure.addWillExecuteBlockObserver(synchronizedWith: DispatchQueue.main) { procedure, _ in
            // The Procedure should have called procedureClaimLock prior
            // to dispatching willExecute observers
            XCTAssertTrue(calledProcedureClaimLock.access)
        }

        let queue = CustomProcedureQueue(
            requestLock: { mutuallyExclusiveCategories in
                // Requesting the lock should occur *prior* to the Procedure being ready
                XCTAssertFalse(procedure.isReady)

                // And only once
                let previouslyCalledRequestLock = calledRequestLock.write({ (value) -> Bool in
                    let previousValue = value
                    value = true
                    return previousValue
                })
                XCTAssertFalse(previouslyCalledRequestLock)

                // And should contain the expected set of categories
                XCTAssertEqual(mutuallyExclusiveCategories, expectedMutuallyExclusiveCategories)
        },
            procedureClaimLock: { ticket in
                // Should be called *after* requestLock was called
                XCTAssertTrue(calledRequestLock.access)

                // Should only be called once for the Procedure
                let previouslyCalledProcedureClaimLock = calledProcedureClaimLock.write({ (value) -> Bool in
                    let previousValue = value
                    value = true
                    return previousValue
                })
                XCTAssertFalse(previouslyCalledProcedureClaimLock)

                // At the point the procedure claims the lock, it should no longer be pending
                // (i.e. it should have been started by the queue) but it also should not yet
                // be executing
                XCTAssertFalse(procedure.isPending)
                XCTAssertFalse(procedure.isExecuting)
                XCTAssertFalse(procedure.isFinished)

                // The ticket should contain the original categories
                XCTAssertEqual(ticket.mutuallyExclusiveCategories, expectedMutuallyExclusiveCategories)
        },
            unlock: { categories in
                // Should be called after the Procedure has finished
                XCTAssertTrue(procedure.isFinished)

                // And after the required prior calls to requestLock, procedureClaimLock
                XCTAssertTrue(calledRequestLock.access)
                XCTAssertTrue(calledProcedureClaimLock.access)

                // And only once
                let previouslyCalledUnlock = calledUnlock.write({ (value) -> Bool in
                    let previousValue = value
                    value = true
                    return previousValue
                })
                XCTAssertFalse(previouslyCalledUnlock)

                // Providing the original categories
                XCTAssertEqual(categories, expectedMutuallyExclusiveCategories)
        }
        )

        addCompletionBlockTo(procedure: procedure)
        queue.add(operation: procedure)
        waitForExpectations(timeout: 3)

        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertTrue(calledRequestLock.access)
        XCTAssertTrue(calledProcedureClaimLock.access)
        XCTAssertTrue(calledUnlock.access)
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
            addCompletionBlockTo(procedure: $0, withExpectationDescription: "\(String(describing: $0.name)), didFinish")
            return $0
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // add procedures to the queue simultaneously
        let dispatchQueue = DispatchQueue.global(qos: .userInitiated)
        for procedure in procedures {
            dispatchQueue.async { [weak weakQueue = self.queue] in
                guard let queue = weakQueue else { return }
                queue.addOperation(procedure)
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
        queue.add(operation: procedure2).then(on: DispatchQueue.main) { [weak weakQueue = self.queue] in
            guard let queue = weakQueue else { return }
            // then add procedure1 to the queue
            queue.add(operation: procedure1)
        }

        waitForExpectations(timeout: 2)

        XCTAssertTrue(procedure1.isFinished)
        XCTAssertTrue(procedure2.isFinished)
    }

    func test__mutual_exclusivity_when_initial_reference_to_queue_goes_away() {

        class DoesNotFinishByItselfProcedure: Procedure {
            override func execute() {
                // does not finish by itself - the test must call finish()
            }
        }

        weak var weakQueue: ProcedureQueue?
        let procedure1 = DoesNotFinishByItselfProcedure()

        let procedureFinishedGroup = DispatchGroup()
        procedureFinishedGroup.enter()
        procedure1.addDidFinishBlockObserver { _, _ in
            procedureFinishedGroup.leave()
        }

        procedure1.addWillFinishBlockObserver(synchronizedWith: DispatchQueue.main) { _, _, _ in
            guard let _ = weakQueue else {
                // Neither NSOperationInternal (nor Procedure) appears to be holding a strong
                // reference to the OperationQueue while the Operation is executing (i.e. prior to finish)
                //
                // The current mutual exclusivity implementation requires this,
                // so Procedure must hold onto its own strong reference.
                //
                XCTFail("ERROR: The Procedure is about to finish, but nothing has a strong reference to the ProcedureQueue it's executing \"on\". This needs to be resolved by modifying Procedure to maintain a strong reference to its queue through finish.")
                return
            }
        }

        autoreleasepool {

            var queue: ProcedureQueue? = ProcedureQueue()

            procedure1.add(condition: MutuallyExclusive<TestProcedure>())

            let expProcedureWasStarted = expectation(description: "Procedure was started - execute was called")
            procedure1.addDidExecuteBlockObserver(synchronizedWith: DispatchQueue.main) { _ in
                // the Procedure has been started
                expProcedureWasStarted.fulfill()
            }

            queue!.add(operation: procedure1)
            waitForExpectations(timeout: 3) // wait for the Procedure to be started by the queue

            // store a weak reference to the ProcedureQueue
            weakQueue = queue

            // get rid of our strong reference to the ProcedureQueue
            queue = nil

        }

        // verify that the weak reference to the ProcedureQueue still exists
        guard let _ = weakQueue else {
            // Neither NSOperationInternal (nor Procedure) appears to be holding a strong
            // reference to the OperationQueue while the Operation is executing (i.e. prior to finish)
            //
            // The current mutual exclusivity implementation requires this,
            // so Procedure must hold onto its own strong reference.
            //
            XCTFail("ERROR: The Procedure is still executing, but nothing has a strong reference to the ProcedureQueue it's executing \"on\". This needs to be resolved by modifying Procedure to maintain a strong reference to its queue through finish.")
            return
        }

        // then finish the testing procedure
        procedure1.finish()

        // and wait for it to finish
        let expProcedureDidFinish = expectation(description: "Procedure did finish")
        procedureFinishedGroup.notify(queue: DispatchQueue.main) {
            expProcedureDidFinish.fulfill()
        }
        waitForExpectations(timeout: 3)

        XCTAssertProcedureFinishedWithoutErrors(procedure1)
    }
}



