//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import CloudKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestSuiteRuns: XCTestCase {

    func test__suite_runs() {
        XCTAssertTrue(true)
    }
}

class CloudKitTestCase: ProcedureKitTestCase {

    var container: TestCKOperation.Container!

    override func setUp() {
        super.setUp()
        container = "I'm a test container!"
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }
}

class CKProcedureTestCase: CloudKitTestCase {

}

