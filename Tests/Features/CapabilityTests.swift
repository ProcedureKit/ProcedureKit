//
//  CapabilityTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation
import XCTest
@testable import Operations

class CapabilityTests: XCTestCase {

    func test__void_status_always_meets_requirements() {
        let status = Capability.VoidStatus()
        XCTAssertTrue(status.isRequirementMet(Void()))
    }
}
