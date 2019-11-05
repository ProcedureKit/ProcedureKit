//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class SilentConditionTests: ProcedureKitTestCase {

    func test__silent_condition_composes_name_correctly() {
        let silent = SilentCondition(FalseCondition())
        XCTAssertEqual(silent.name, "Silent<FalseCondition>")
    }

    func test__silent_condition_removes_produced_dependencies_from_composed_condition() {
        let dependency = TestProcedure()
        let condition = TrueCondition()
        condition.produceDependency(dependency)
        let _ = SilentCondition(condition)
        XCTAssertEqual(condition.producedDependencies.count, 0)
    }
}
