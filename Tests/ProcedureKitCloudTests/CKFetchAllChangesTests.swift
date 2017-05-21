//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchAllChangesOperation: TestCKOperation, CKFetchAllChanges {
    var fetchAllChanges: Bool = true
}

class CKFetchAllChangesOperationTests: CKProcedureTestCase {

    var target: TestCKFetchAllChangesOperation!
    var operation: CKProcedure<TestCKFetchAllChangesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchAllChangesOperation()
        operation = CKProcedure(operation: target)
    }

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
    }

    func test__set_get__fetchAllChanges() {
        var fetchAllChanges = false
        operation.fetchAllChanges = fetchAllChanges
        XCTAssertEqual(operation.fetchAllChanges, fetchAllChanges)
        XCTAssertEqual(target.fetchAllChanges, fetchAllChanges)
        fetchAllChanges = true
        operation.fetchAllChanges = fetchAllChanges
        XCTAssertEqual(operation.fetchAllChanges, fetchAllChanges)
        XCTAssertEqual(target.fetchAllChanges, fetchAllChanges)
    }
}
