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
    var database: TestCKDatabaseOperation.Database!
    var token: TestCKOperation.ServerChangeToken!

    override func setUp() {
        super.setUp()
        container = "I'm a test container!"
        database = "I'm a test database!"
        token = "I'm a server change token!"
    }

    override func tearDown() {
        container = nil
        database = nil
        token = nil
        super.tearDown()
    }
}

class CKProcedureTestCase: CloudKitTestCase { }

extension CloudKitProcedure {

    var passthroughSuggestedErrorHandler: ErrorHandler {
        return { $3 }
    }
}
