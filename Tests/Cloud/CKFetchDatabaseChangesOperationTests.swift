//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchDatabaseChangesOperation: TestCKDatabaseOperation, CKFetchDatabaseChangesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = FetchDatabaseChangesError<ServerChangeToken>

    var token: String?
    var error: Error?
    var fetchAllChanges: Bool = true
    var recordZoneWithIDChangedBlock: ((RecordZoneID) -> Void)? = nil
    var recordZoneWithIDWasDeletedBlock: ((RecordZoneID) -> Void)? = nil
    var changeTokenUpdatedBlock: ((ServerChangeToken) -> Void)? = nil
    var fetchDatabaseChangesCompletionBlock: ((ServerChangeToken?, Bool, Error?) -> Void)? = nil

    init(token: String? = "new-token", moreComing: Bool = false, error: Error? = nil) {
        self.token = token
        self.error = error
        super.init()
        self.moreComing = moreComing
    }

    override func main() {
        fetchDatabaseChangesCompletionBlock?(token, moreComing, error)
    }
}

class CKFetchDatabaseChangesOperationTests: CKProcedureTestCase {

    var target: TestCKFetchDatabaseChangesOperation!
    var operation: CKProcedure<TestCKFetchDatabaseChangesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchDatabaseChangesOperation()
        operation = CKProcedure(operation: target)
    }

    // fetchAllChanges is tested by CKFetchAllChangesTests

    func test__set_get__recordZoneWithIDChangedBlock() {
        var setByBlock = false
        let block: (String) -> Void = { zoneID in
            setByBlock = true
        }
        operation.recordZoneWithIDChangedBlock = block
        XCTAssertNotNil(operation.recordZoneWithIDChangedBlock)
        target.recordZoneWithIDChangedBlock?("zoneID")
        XCTAssertTrue(setByBlock)
    }

    func test__set_get__recordZoneWithIDWasDeletedBlock() {
        var setByBlock = false
        let block: (String) -> Void = { zoneID in
            setByBlock = true
        }
        operation.recordZoneWithIDWasDeletedBlock = block
        XCTAssertNotNil(operation.recordZoneWithIDWasDeletedBlock)
        target.recordZoneWithIDWasDeletedBlock?("zoneID")
        XCTAssertTrue(setByBlock)
    }

    func test__set_get__changeTokenUpdatedBlock() {
        var setByBlock = false
        let block: (String) -> Void = { serverChangeToken in
            setByBlock = true
        }
        operation.changeTokenUpdatedBlock = block
        XCTAssertNotNil(operation.changeTokenUpdatedBlock)
        target.changeTokenUpdatedBlock?("I'm a server change token")
        XCTAssertTrue(setByBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchDatabaseChangesCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block() {
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchDatabaseChangesCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

