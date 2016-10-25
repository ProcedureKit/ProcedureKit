//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchRecordChangesOperation: TestCKDatabaseOperation, CKFetchRecordChangesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = FetchRecordChangesError<ServerChangeToken>

    var token: String?
    var data: Data?
    var error: Error?
    var recordZoneID: RecordZoneID = "zone-id"
    var recordChangedBlock: ((Record) -> Void)? = nil
    var recordWithIDWasDeletedBlock: ((RecordID) -> Void)? = nil
    var fetchRecordChangesCompletionBlock: ((ServerChangeToken?, Data?, Error?) -> Void)? = nil

    init(token: String? = "new-token", data: Data? = nil, error: Error? = nil) {
        self.token = token
        self.data = data
        self.error = error
        super.init()
    }

    override func main() {
        fetchRecordChangesCompletionBlock?(token, data, error)
    }
}

class CKFetchRecordChangesOperationTests: CKProcedureTestCase {

    var target: TestCKFetchRecordChangesOperation!
    var operation: CKProcedure<TestCKFetchRecordChangesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchRecordChangesOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__recordZoneID() {
        let recordZoneID: String = "I'm a record zone ID"
        operation.recordZoneID = recordZoneID
        XCTAssertEqual(operation.recordZoneID, recordZoneID)
        XCTAssertEqual(target.recordZoneID, recordZoneID)
    }

    func test__set_get__recordChangedBlock() {
        var setByBlock = false
        let block: (String) -> Void = { record in
            setByBlock = true
        }
        operation.recordChangedBlock = block
        XCTAssertNotNil(operation.recordChangedBlock)
        target.recordChangedBlock?("I'm a record")
        XCTAssertTrue(setByBlock)
    }

    func test__set_get__recordWithIDWasDeletedBlock() {
        var setByBlock = false
        let block: (String) -> Void = { recordID in
            setByBlock = true
        }
        operation.recordWithIDWasDeletedBlock = block
        XCTAssertNotNil(operation.recordWithIDWasDeletedBlock)
        target.recordWithIDWasDeletedBlock?("I'm a record ID")
        XCTAssertTrue(setByBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchRecordChangesCompletionBlock { _, _ in
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
        operation.setFetchRecordChangesCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

