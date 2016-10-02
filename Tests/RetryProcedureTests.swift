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
}
