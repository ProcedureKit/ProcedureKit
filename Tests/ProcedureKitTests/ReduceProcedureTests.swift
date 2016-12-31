//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class NumbersProcedure: ResultProcedure<Array<Int>> {

    init(error: Error? = nil) {
        super.init {
            if let error = error { throw error }
            return [0, 1, 2, 3, 4, 5 , 6 , 7, 8, 9]
        }
    }
}

class ReduceProcedureTests: ProcedureKitTestCase {

    func test__requirement_is_reduced_to_result() {
        let reduced = ReduceProcedure(source: [0, 1, 2, 3, 4, 5 , 6 , 7, 8, 9], initial: 0, nextPartialResult: +)
        wait(for: reduced)
        XCTAssertProcedureFinishedWithoutErrors(reduced)
        XCTAssertEqual(reduced.output.success ?? 0, 45)
    }

    func test__finishes_with_error_if_block_throws() {
        let reduced = ReduceProcedure(source: [0, 1, 2, 3, 4, 5 , 6 , 7, 8, 9], initial: 0) { _, _ in throw TestError() }
        wait(for: reduced)
        XCTAssertProcedureFinishedWithErrors(reduced, count: 1)
    }

    func test__reduce_dependency_which_finishes_without_errors() {
        let numbers = NumbersProcedure()
        let reduced = numbers.reduce(0, nextPartialResult: +)
        wait(for: numbers, reduced)
        XCTAssertProcedureFinishedWithoutErrors(numbers)
        XCTAssertProcedureFinishedWithoutErrors(reduced)
        XCTAssertEqual(reduced.output.success ?? 0, 45)
    }

    func test__reduce_dependency_which_finishes_with_error() {
        let numbers = NumbersProcedure(error: TestError())
        let reduced = numbers.reduce(0, nextPartialResult: +)
        wait(for: numbers, reduced)
        XCTAssertProcedureFinishedWithErrors(numbers, count: 1)
        XCTAssertProcedureCancelledWithErrors(reduced, count: 1)
    }
}
