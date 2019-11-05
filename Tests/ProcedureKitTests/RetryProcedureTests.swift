//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class RetryProcedureTests: RetryTestCase {

    func test__with_payload_iterator() {
        retry = Retry(iterator: createPayloadIterator(succeedsAfterFailureCount: 2), retry: { $1 })
        wait(for: retry)
        PKAssertProcedureFinished(retry)
        XCTAssertEqual(retry.count, 3)
    }

    func test__with_max_count() {
        retry = Retry(max: 2, iterator: createPayloadIterator(succeedsAfterFailureCount: 4), retry: { $1 })
        wait(for: retry)
        XCTAssertEqual(retry.count, 2)
        PKAssertProcedureFinishedWithError(retry, ProcedureKitError.conditionFailed())
    }

    func test__with_delay_and_operation_iterator() {
        retry = Retry(delay: Delay.Iterator.fibonacci(withPeriod: 0.001), iterator: createOperationIterator(succeedsAfterFailureCount: 2), retry: { $1 })
        wait(for: retry)
        PKAssertProcedureFinished(retry)
        XCTAssertEqual(retry.count, 3)
    }

    func test__with_wait_strategy_and_operation_iterator() {
        retry = Retry(wait: .incrementing(initial: 0, increment: 0.001), iterator: createOperationIterator(succeedsAfterFailureCount: 2), retry: { $1 })
        wait(for: retry)
        PKAssertProcedureFinished(retry)
        XCTAssertEqual(retry.count, 3)
    }

    func test__with_block_fails_after_max() {
        retry = Retry(upto: 3) { TestProcedure(error: ProcedureKitError.unknown) }
        wait(for: retry)
        PKAssertProcedureFinishedWithError(retry, ProcedureKitError.unknown)
        XCTAssertEqual(retry.count, 3)
    }

    func test__with_input_procedure_payload() {

        let outputProcedure = TestProcedure()
        outputProcedure.output = .ready(.success("ProcedureKit"))
        retry = Retry(iterator: createPayloadIterator(succeedsAfterFailureCount: 2), retry: { $1 })

        var textOutput: [String] = []
        retry.addWillAddOperationBlockObserver { (_, operation) in
            if let procedure = operation as? TestProcedure {
                procedure.addDidFinishBlockObserver { (testProcedure, error) in
                    guard error == nil else { return }
                    if let output = testProcedure.output.value?.value {
                        textOutput.append(output)
                    }
                }
            }
        }

        retry.injectResult(from: outputProcedure)

        wait(for: retry, outputProcedure)
        PKAssertProcedureFinished(retry)

        // TODO: - Fix Swift access race in implicit closure
        XCTAssertEqual(textOutput, ["Hello ProcedureKit"])
    }

    func test__retry_deinits_after_finished() {
        // Catches reference cycles.

        class RetryDeinitMonitor<T: Procedure>: RetryProcedure<T> {
            var deinitBlock: (() -> Void)?
            override public init<OperationIterator>(dispatchQueue: DispatchQueue? = nil, max: Int? = nil, wait: WaitStrategy, iterator base: OperationIterator, retry block: @escaping Handler) where OperationIterator: IteratorProtocol, OperationIterator.Element == T {
                super.init(dispatchQueue: dispatchQueue, max: max, wait: wait, iterator: base, retry: block)
            }
            deinit {
                deinitBlock?()
            }
        }

        weak var didDeinitExpectation = expectation(description: "RetryProcedure Did DeInit")
        DispatchQueue.default.async {
            let queue = ProcedureQueue()
            let retry = RetryDeinitMonitor<TestProcedure>(wait: .incrementing(initial: 0, increment: 0.001), iterator: self.createOperationIterator(succeedsAfterFailureCount: 2), retry: { $1 })
            retry.deinitBlock = {
                DispatchQueue.main.async {
                    guard let didDeinitExpectation = didDeinitExpectation else { return }
                    didDeinitExpectation.fulfill()
                }
            }
            let semaphore = DispatchSemaphore(value: 0)
            retry.addDidFinishBlockObserver { _, _ in
                semaphore.signal()
            }
            queue.addOperation(retry)
            semaphore.wait()
        }

        waitForExpectations(timeout: 3) { (error) in
            if error != nil {
                XCTFail("RetryProcedure did not deinit - something still has a reference. (Possible cycle.)")
            }
        }
    }
}
