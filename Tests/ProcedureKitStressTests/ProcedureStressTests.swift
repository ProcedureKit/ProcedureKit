//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit
import Dispatch

class ProcedureCompletionBlockStressTest: StressTestCase {

    func test__completion_blocks() {

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure(name: "Batch \(batch.number), Iteration \(iteration)")
            procedure.addCompletionBlock { batch.dispatchGroup.leave() }
            batch.queue.add(operation: procedure)
        }
    }
}

class CancelProcedureWithErrorsStressTest: StressTestCase {

    func test__cancel_or_finish_with_errors() {

        // NOTE: It is possible for a TestProcedure below to finish prior to being cancelled

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure(name: "Batch \(batch.number), Iteration \(iteration)")
            procedure.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: procedure)
            procedure.cancel(with: TestError())
        }
    }

    func test__cancel_with_errors_prior_to_execute() {

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure(name: "Batch \(batch.number), Iteration \(iteration)")
            procedure.addDidFinishBlockObserver { _, error in
                if error == nil {
                    DispatchQueue.main.async {
                        XCTAssertNil(error, "error is nil - cancel errors were not propagated")
                        batch.dispatchGroup.leave()
                    }
                }
                else {
                    batch.dispatchGroup.leave()
                }
            }
            procedure.cancel(with: TestError())
            batch.queue.add(operation: procedure)
        }
    }

    func test__cancel_with_errors_from_will_execute_observer() {

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure(name: "Batch \(batch.number), Iteration \(iteration)")
            procedure.addDidFinishBlockObserver { _, error in
                if error == nil {
                    DispatchQueue.main.async {
                        XCTAssertNil(error, "error is nil - cancel errors were not propagated")
                        batch.dispatchGroup.leave()
                    }
                }
                else {
                    batch.dispatchGroup.leave()
                }
            }
            procedure.addWillExecuteBlockObserver { (procedure, _) in
                procedure.cancel(with: TestError())
            }
            batch.queue.add(operation: procedure)
        }
    }
}

class ProcedureConditionStressTest: StressTestCase {

    func test__adding_many_conditions() {

        StressLevel.custom(1, 10_000).forEach { _, _ in
            procedure.add(condition: TrueCondition())
        }
        wait(for: procedure, withTimeout: 10)
        PKAssertProcedureFinished(procedure)
    }

    func test__adding_many_conditions_each_with_single_dependency() {

        StressLevel.custom(1, 10_000).forEach { _, _ in
            procedure.add(condition: TestCondition(producedDependencies: [TestProcedure()]) { .success(true) })
        }
        wait(for: procedure, withTimeout: 10)
        PKAssertProcedureFinished(procedure)
    }

    func test__dependencies_execute_before_condition_dependencies() {

        var failures = Protector<[Int: [String]]>([:])
        func appendFailure(batch: Int, _ failure: String) {
            failures.write { (dict) in
                if var existingFailures = dict[batch] {
                    existingFailures.append(failure)
                    dict[batch] = existingFailures
                }
                else {
                    dict[batch] = [failure]
                }
            }
        }

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure(name: "TestProcedure (\(batch.number): \(iteration))")
            procedure.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }

            let dependency1 = TestProcedure(name: "Dependency 1 (\(batch.number): \(iteration))")
            let dependency2 = TestProcedure(name: "Dependency 2 (\(batch.number): \(iteration))")
            procedure.add(dependencies: dependency1, dependency2)

            let conditionDependency1 = BlockOperation {
                // dependency1 and dependency2 should be finished
                let dep1Finished = dependency1.isFinished
                let dep2Finished = dependency2.isFinished
                if !dep1Finished { appendFailure(batch: batch.number, "\(dependency1.operationName) did not finish prior to condition-produced dependency") }
                if !dep2Finished { appendFailure(batch: batch.number, "\(dependency2.operationName) did not finish prior to condition-produced dependency") }
            }
            conditionDependency1.name = "Condition 1 Dependency"

            let condition1 = TrueCondition(name: "Condition 1")
            condition1.produce(dependency: conditionDependency1)

            procedure.add(condition: condition1)

            batch.queue.add(operations: dependency1, dependency2)
            batch.queue.add(operation: procedure)
        }

        let finalFailures = failures.access
        for (batch, failures) in finalFailures {
            guard failures.isEmpty else {
                XCTFail("Batch \(batch) encountered \(failures.count) failures:\n\t\(failures.joined(separator: "\n\t"))")
                continue
            }
        }
    }
}

class ProcedureConditionsWillFinishObserverCancelThreadSafety: StressTestCase {

    func test__conditions_do_not_fail_when_will_finish_observer_cancels_and_deallocates_procedure() {
        // NOTES:
        //      Previously, this test would fail in Condition.execute(),
        //      where if `Condition.operation` was nil the following assertion would trigger:
        //          assertionFailure("Condition executed before operation set.")
        //      However, this was not an accurate assert in all cases.
        //
        //      In this test case, all conditions have their .procedure properly set as a result of
        //      `queue.addOperation(operation)`.
        //
        //      Calling `procedure.cancel()` results in the procedure deiniting prior to the access of the weak
        //      `Condition.procedure` var, which was then nil (when accessed).
        //
        //      After removing this assert, the following additional race condition was triggered:
        //      "attempted to retain deallocated object" (EXC_BREAKPOINT)
        //      in the Procedure.EvaluateConditions's WillFinishObserver
        //      Associated Report: https://github.com/ProcedureKit/ProcedureKit/issues/416
        //
        //      This was caused by a race condition between the procedure deiniting and the
        //      EvaluateConditions's WillFinishObserver accessing `unowned self`,
        //      which is easily triggerable by the following test case.
        //
        //      This test should now pass without error.

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure()
            procedure.add(condition: FalseCondition())
            procedure.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: procedure)
            procedure.cancel()
        }
    }

    func test__conditions_queue_suspension_safety() {
        let numberOfQueueIsSuspendedCycles = Protector<Int>(0)
        var lastBatchStopQueueSuspensionLoop = Protector<Bool>(false)
        let procedures = Protector<[Procedure]>([])

        stress { batch, iteration in
            if (iteration == 0) {
                // On the first iteration in a batch
                // Stop the prior batch's loop
                lastBatchStopQueueSuspensionLoop.overwrite(with: true)

                // Dispatch an asynchronous loop to toggle isSuspended on the batch's queue
                lastBatchStopQueueSuspensionLoop = Protector<Bool>(false)
                DispatchQueue.global(qos: .userInteractive).async { [stopLoop = lastBatchStopQueueSuspensionLoop, queue = batch.queue] in
                    // constantly suspend/resume the queue
                    repeat {
                        queue.isSuspended = true
                        queue.isSuspended = false
                        numberOfQueueIsSuspendedCycles.write({ (number) in
                            if number < Int.max { // ensure we don't overflow
                                number += 1
                            }
                        })
                    } while (!stopLoop.access)
                }
            }
            batch.dispatchGroup.enter()
            let procedure = TestProcedure()
            procedure.add(condition: FalseCondition())
            procedure.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            procedures.append(procedure)
            batch.queue.add(operation: procedure)
        }

        lastBatchStopQueueSuspensionLoop.overwrite(with: true)

        for procedure in procedures.access {
            PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.FalseCondition())
        }
        print ("Queue isSuspended cycles (total, all batches): \(numberOfQueueIsSuspendedCycles.access)")
    }
}

class ProcedureFinishStressTest: StressTestCase {

    class TestAttemptsMultipleFinishesProcedure: Procedure {
        public init(name: String = "Test Procedure") {
            super.init()
            self.name = name
        }
        override func execute() {
            DispatchQueue.global().async() {
                self.finish()
            }
            DispatchQueue.global().async() {
                self.finish()
            }
            DispatchQueue.global().async() {
                self.finish()
            }
        }
    }

    func test__concurrent_calls_to_finish_only_first_succeeds() {
        // NOTES:
        //      This test should pass without any "cyclic state transition: finishing -> finishing" errors.

        stress { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestAttemptsMultipleFinishesProcedure()
            var didFinish = false
            let lock = NSLock()
            procedure.addDidFinishBlockObserver { _, _ in
                let finishedMoreThanOnce = lock.withCriticalScope(block: { () -> Bool in
                    guard !didFinish else {
                        // procedure finishing more than once
                        return true
                    }
                    didFinish = true
                    return false
                })
                guard !finishedMoreThanOnce else {
                    batch.incrementCounter(named: "finishedProcedureMoreThanOnce")
                    return
                }
                // add small delay before leaving to increase the odds that concurrent finishes are caught
                let deadline = DispatchTime(uptimeNanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
                DispatchQueue.global().asyncAfter(deadline: deadline) {
                    batch.dispatchGroup.leave()
                }
            }
            batch.queue.add(operation: procedure)
        }
    }

    override func ended(batch: BatchProtocol) {
        XCTAssertEqual(batch.counter(named: "finishedProcedureMoreThanOnce"), 0)
        super.ended(batch: batch)
    }
}

class ProcedureCancellationHandlerConcurrencyTest: StressTestCase {

    func test__cancelled_procedure_no_concurrent_events() {

        stress(level: StressLevel.custom(2, 1000)) { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = EventConcurrencyTrackingProcedure(execute: { procedure in
                usleep(50000)
                procedure.finish()
            })
            procedure.addDidFinishBlockObserver(block: { (procedure, error) in
                DispatchQueue.main.async {
                    self.PKAssertProcedureNoConcurrentEvents(procedure)
                    batch.dispatchGroup.leave()
                }
            })
            batch.queue.add(operation: procedure)
            procedure.cancel()
        }
    }
}

class ProcedureFinishHandlerConcurrencyTest: StressTestCase {

    func test__finish_from_asynchronous_callback_while_execute_is_still_running() {
        // NOTE: Do not use this test as an example of what to do.

        stress(level: StressLevel.custom(2, 1000)) { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = EventConcurrencyTrackingProcedure(execute: { procedure in
                assert(!DispatchQueue.isMainDispatchQueue)
                let semaphore = DispatchSemaphore(value: 0)
                // dispatch finish on another thread...
                DispatchQueue.global().async { [unowned procedure] in
                    procedure.finish()
                    semaphore.signal()
                }
                // and block this thread until the call to finish() returns
                semaphore.wait()
            })
            procedure.addDidFinishBlockObserver(block: { (procedure, error) in
                DispatchQueue.main.async {
                    self.PKAssertProcedureNoConcurrentEvents(procedure)
                    batch.dispatchGroup.leave()
                }
            })
            batch.queue.add(operation: procedure)
            procedure.cancel()
        }
    }
}
