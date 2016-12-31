//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class MapProcedureTests: ProcedureKitTestCase {

    func test__requirement_is_mapped_to_result() {
        let functional = MapProcedure(source: [0,1,2,3,4,5,6,7]) { $0 * 2 }
        wait(for: functional)
        XCTAssertProcedureFinishedWithoutErrors(functional)
        XCTAssertEqual(functional.output.success ?? [0,1,2,3,4,5,6,7], [0,2,4,6,8,10,12,14])
    }

    func test__finishes_with_error_if_block_throws() {
        let functional = MapProcedure(source: [0,1,2,3,4,5,6,7]) { _ in throw TestError() }
        wait(for: functional)
        XCTAssertProcedureFinishedWithErrors(functional, count: 1)
    }

    func test__map_dependency_which_finishes_without_errors() {
        let numbers = NumbersProcedure()
        let functional = numbers.map { $0 * 2 }
        wait(for: numbers, functional)
        XCTAssertProcedureFinishedWithoutErrors(numbers)
        XCTAssertProcedureFinishedWithoutErrors(functional)
        XCTAssertEqual(functional.output.success ?? [0,1,2,3,4,5,6,7], [0,2,4,6,8,10,12,14,16,18])
    }

    func test__map_dependency_which_finishes_with_errors() {
        let numbers = NumbersProcedure(error: TestError())
        let functional = numbers.map { $0 * 2 }
        wait(for: numbers, functional)
        XCTAssertProcedureFinishedWithErrors(numbers, count: 1)
        XCTAssertProcedureCancelledWithErrors(functional, count: 1)
    }

}

class FlatMapProcedureTests: ProcedureKitTestCase {

    func test__requirement_is_flat_mapped_to_result() {
        let functional = FlatMapProcedure(source: [0,1,2,3,4,5,6,7,8,9]) { (value: Int) -> Int? in
            guard value % 2 == 0 else { return nil }
            return value * 2
        }
        wait(for: functional)
        XCTAssertProcedureFinishedWithoutErrors(functional)
        XCTAssertEqual(functional.output.success ?? [0,1,2,3,4,5,6,7,8,9], [0,4,8,12,16])
    }

    func test__finishes_with_error_if_block_throws() {
        let functional = MapProcedure(source: [0,1,2,3,4,5,6,7,8,9]) { _ in throw TestError() }
        wait(for: functional)
        XCTAssertProcedureFinishedWithErrors(functional, count: 1)
    }

    func test__flat_map_dependency_which_finishes_without_errors() {
        let numbers = NumbersProcedure()
        let functional = numbers.flatMap { (value: Int) -> Int? in
            guard value % 2 == 0 else { return nil }
            return value * 2
        }
        wait(for: numbers, functional)
        XCTAssertProcedureFinishedWithoutErrors(numbers)
        XCTAssertProcedureFinishedWithoutErrors(functional)
        XCTAssertEqual(functional.output.success ?? [0,1,2,3,4,5,6,7,8,9], [0,4,8,12,16])
    }

    func test__flat_map_dependency_which_finishes_with_errors() {
        let numbers = NumbersProcedure(error: TestError())
        let functional = numbers.map { $0 * 2 }
        wait(for: numbers, functional)
        XCTAssertProcedureFinishedWithErrors(numbers, count: 1)
        XCTAssertProcedureCancelledWithErrors(functional, count: 1)
    }
    
}
