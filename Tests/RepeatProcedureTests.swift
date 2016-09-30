//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class RepeatProcedureTests: RepeatTestCase {

    func test__init_with_custom_iterator() {
        repeatProcedure = RepeatProcedure(max: 2, iterator: createIterator())
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__init_with_delay_iterator() {
        repeatProcedure = RepeatProcedure(max: 2, delay: Delay.Iterator.immediate, iterator: AnyIterator { TestProcedure() })
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__init_with_wait_strategy() {
        repeatProcedure = RepeatProcedure(max: 2, wait: .constant(0.001), iterator: AnyIterator { TestProcedure() })
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__init_with_body() {
        repeatProcedure = RepeatProcedure(max: 2) { TestProcedure() }
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 2)
    }
}
