//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class FilterProcedureTests: ProcedureKitTestCase {

    func test__requirement_is_filtered_to_result() {
        let functional = FilterProcedure(source: [0,1,2,3,4,5,6,7]) { $0 % 2 == 0 }
        wait(for: functional)
        PKAssertProcedureOutput(functional, [0,2,4,6])
    }

    func test__finishes_with_error_if_block_throws() {
        let error = TestError()
        let functional = FilterProcedure(source: [0,1,2,3,4,5,6,7]) { _ in throw error }
        wait(for: functional)
        PKAssertProcedureFinishedWithError(functional, error)
    }

    func test__filter_dependency_which_finishes_without_errors() {
        let numbers = NumbersProcedure()
        let functional = numbers.filter { $0 % 2 == 0 }
        wait(for: numbers, functional)
        PKAssertProcedureFinished(numbers)
        PKAssertProcedureOutput(functional, [0,2,4,6,8])
    }

    func test__filter_dependency_which_finishes_with_errors() {
        let error = TestError()
        let numbers = NumbersProcedure(error: error)
        let functional = numbers.filter { $0 % 2 == 0 }
        wait(for: numbers, functional)
        PKAssertProcedureFinishedWithError(numbers, error)
        PKAssertProcedureCancelledWithError(functional, ProcedureKitError.dependency(finishedWithError: error))
    }
}
