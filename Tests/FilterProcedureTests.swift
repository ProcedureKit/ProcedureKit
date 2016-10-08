//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class FilterProcedureTests: ProcedureKitTestCase {

    func test__requirement_is_filtered_to_result() {
        let evenOnly = FilterProcedure(source: [0,1,2,3,4,5,6,7]) { $0 % 2 == 0 }
        wait(for: evenOnly)
        XCTAssertProcedureFinishedWithoutErrors(evenOnly)
        XCTAssertEqual(evenOnly.result, [0,2,4,6])
    }

    func test__finishes_with_error_if_block_throws() {
        let evenOnly = FilterProcedure(source: [0,1,2,3,4,5,6,7]) { _ in throw TestError() }
        wait(for: evenOnly)
        XCTAssertProcedureFinishedWithErrors(evenOnly, count: 1)
    }

    func test__filter_dependency_which_finishes_without_errors() {
        let numbers = NumbersProcedure()
        let filtered = numbers.filter { $0 % 2 == 0 }
        wait(for: numbers, filtered)
        XCTAssertProcedureFinishedWithoutErrors(numbers)
        XCTAssertProcedureFinishedWithoutErrors(filtered)
        XCTAssertEqual(filtered.result, [0,2,4,6,8])
    }

    func test__filter_dependency_which_finishes_with_errors() {
        let numbers = NumbersProcedure(error: TestError())
        let filtered = numbers.filter { $0 % 2 == 0 }
        wait(for: numbers, filtered)
        XCTAssertProcedureFinishedWithErrors(numbers, count: 1)
        XCTAssertProcedureCancelledWithErrors(filtered, count: 1)
    }
}
