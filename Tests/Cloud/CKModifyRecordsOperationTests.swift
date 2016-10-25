//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKModifyRecordsOperation: TestCKDatabaseOperation, CKModifyRecordsOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = ModifyRecordsError<Record, RecordID>

    var saved: [Record]?
    var deleted: [RecordID]?
    var error: Error?

    var recordsToSave: [Record]? = nil
    var recordIDsToDelete: [RecordID]? = nil
    var savePolicy: RecordSavePolicy = 0
    var clientChangeTokenData: Data? = nil
    var isAtomic: Bool = true

    var perRecordProgressBlock: ((Record, Double) -> Void)? = nil
    var perRecordCompletionBlock: ((Record?, Error?) -> Void)? = nil
    var modifyRecordsCompletionBlock: (([Record]?, [RecordID]?, Error?) -> Void)? = nil

    init(saved: [Record]? = nil, deleted: [RecordID]? = nil, error: Error? = nil) {
        self.saved = saved
        self.deleted = deleted
        self.error = error
        super.init()
    }

    override func main() {
        modifyRecordsCompletionBlock?(saved, deleted, error)
    }
}

class CKModifyRecordsOperationTests: CKProcedureTestCase {

    var target: TestCKModifyRecordsOperation!
    var operation: CKProcedure<TestCKModifyRecordsOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKModifyRecordsOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__recordsToSave() {
        let recordsToSave = [ "a-record", "another-record" ]
        operation.recordsToSave = recordsToSave
        XCTAssertNotNil(operation.recordsToSave)
        XCTAssertEqual(operation.recordsToSave ?? [], recordsToSave)
        XCTAssertNotNil(target.recordsToSave)
        XCTAssertEqual(target.recordsToSave ?? [], recordsToSave)
    }

    func test__set_get__recordIDsToDelete() {
        let recordIDsToDelete = [ "a-record-id", "another-record-id" ]
        operation.recordIDsToDelete = recordIDsToDelete
        XCTAssertNotNil(operation.recordIDsToDelete)
        XCTAssertEqual(operation.recordIDsToDelete ?? [], recordIDsToDelete)
        XCTAssertNotNil(target.recordIDsToDelete)
        XCTAssertEqual(target.recordIDsToDelete ?? [], recordIDsToDelete)
    }

    func test__set_get__savePolicy() {
        let savePolicy = 100
        operation.savePolicy = savePolicy
        XCTAssertEqual(operation.savePolicy, savePolicy)
        XCTAssertEqual(target.savePolicy, savePolicy)
    }

    func test__set_get__clientChangeTokenData() {
        let clientChangeTokenData = "this-is-some-data".data(using: .utf8)
        operation.clientChangeTokenData = clientChangeTokenData
        XCTAssertEqual(operation.clientChangeTokenData, clientChangeTokenData)
        XCTAssertEqual(target.clientChangeTokenData, clientChangeTokenData)
    }

    func test__set_get__isAtomic() {
        var isAtomic = true
        operation.isAtomic = isAtomic
        XCTAssertEqual(operation.isAtomic, isAtomic)
        XCTAssertEqual(target.isAtomic, isAtomic)
        isAtomic = false
        operation.isAtomic = isAtomic
        XCTAssertEqual(operation.isAtomic, isAtomic)
        XCTAssertEqual(target.isAtomic, isAtomic)
    }

    func test__set_get__perRecordProgressBlock() {
        var setByCompletionBlock = false
        let block: (String, Double) -> Void = { record, progress in
            setByCompletionBlock = true
        }
        operation.perRecordProgressBlock = block
        XCTAssertNotNil(operation.perRecordProgressBlock)
        target.perRecordProgressBlock?("a-record", 50.0)
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__set_get__perRecordCompletionBlock() {
        var setByCompletionBlock = false
        let block: (String?, Error?) -> Void = { record, error in
            setByCompletionBlock = true
        }
        operation.perRecordCompletionBlock = block
        XCTAssertNotNil(operation.perRecordCompletionBlock)
        target.perRecordCompletionBlock?("a-record", nil)
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifyRecordsCompletionBlock { savedRecords, deletedRecordIDs in
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
        operation.setModifyRecordsCompletionBlock { savedRecords, deletedRecordIDs in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}
