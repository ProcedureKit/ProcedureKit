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
}
