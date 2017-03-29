//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class RetryProcedureTests: RetryTestCase {

    func test__with_payload_iterator() {
        retry = Retry(iterator: createPayloadIterator(succeedsAfterFailureCount: 2), retry: { $1 })
        wait(for: retry)
        XCTAssertProcedureFinishedWithoutErrors(retry)
        XCTAssertEqual(retry.count, 3)
    }

    func test__with_max_count() {
        retry = Retry(max: 2, iterator: createPayloadIterator(succeedsAfterFailureCount: 4), retry: { $1 })
        wait(for: retry)
        XCTAssertProcedureFinishedWithErrors(retry, count: 1)
        XCTAssertEqual(retry.count, 2)
    }

    func test__with_delay_and_operation_iterator() {
        retry = Retry(delay: Delay.Iterator.fibonacci(withPeriod: 0.001), iterator: createOperationIterator(succeedsAfterFailureCount: 2), retry: { $1 })
        wait(for: retry)
        XCTAssertProcedureFinishedWithoutErrors(retry)
        XCTAssertEqual(retry.count, 3)
    }

    func test__with_wait_strategy_and_operation_iterator() {
        retry = Retry(wait: .incrementing(initial: 0, increment: 0.001), iterator: createOperationIterator(succeedsAfterFailureCount: 2), retry: { $1 })
        wait(for: retry)
        XCTAssertProcedureFinishedWithoutErrors(retry)
        XCTAssertEqual(retry.count, 3)
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
            queue.add(operation: retry)
            semaphore.wait()
        }

        waitForExpectations(timeout: 3) { (error) in
            if error != nil {
                XCTFail("RetryProcedure did not deinit - something still has a reference. (Possible cycle.)")
            }
        }
    }
}
