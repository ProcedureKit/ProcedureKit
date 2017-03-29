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
        let functional = FilterProcedure(source: [0,1,2,3,4,5,6,7]) { $0 % 2 == 0 }
        wait(for: functional)
        XCTAssertProcedureFinishedWithoutErrors(functional)
        XCTAssertEqual(functional.output.success ?? [0,1,2,3,4,5,6,7], [0,2,4,6])
    }

    func test__finishes_with_error_if_block_throws() {
        let functional = FilterProcedure(source: [0,1,2,3,4,5,6,7]) { _ in throw TestError() }
        wait(for: functional)
        XCTAssertProcedureFinishedWithErrors(functional, count: 1)
    }

    func test__filter_dependency_which_finishes_without_errors() {
        let numbers = NumbersProcedure()
        let functional = numbers.filter { $0 % 2 == 0 }
        wait(for: numbers, functional)
        XCTAssertProcedureFinishedWithoutErrors(numbers)
        XCTAssertProcedureFinishedWithoutErrors(functional)
        XCTAssertEqual(functional.output.success ?? [0,1,2,3,4,5,6,7], [0,2,4,6,8])
    }

    func test__filter_dependency_which_finishes_with_errors() {
        let numbers = NumbersProcedure(error: TestError())
        let functional = numbers.filter { $0 % 2 == 0 }
        wait(for: numbers, functional)
        XCTAssertProcedureFinishedWithErrors(numbers, count: 1)
        XCTAssertProcedureCancelledWithErrors(functional, count: 1)
    }
}
