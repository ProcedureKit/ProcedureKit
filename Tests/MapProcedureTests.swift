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
        let timesTwo = MapProcedure<Int, Int> { return $0 * 2 }
        timesTwo.requirement = 2
        wait(for: timesTwo)
        XCTAssertEqual(timesTwo.result, 4)
    }
}
