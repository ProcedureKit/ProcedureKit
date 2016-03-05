//
//  SilentConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 30/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class SilentConditionTests: XCTestCase {

    func test__silent_condition_composes_name_correctly() {
        let condition = BlockCondition { false }
        let silent = SilentCondition(condition)
        XCTAssertEqual(silent.name, "Silent<Block Condition>")
    }
}
