//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKModifyRecordZonesOperation: TestCKDatabaseOperation, CKModifyRecordZonesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = ModifyRecordZonesError<RecordZone, RecordZoneID>

    var saved: [RecordZone]? = nil
    var deleted: [RecordZoneID]? = nil
    var error: Error? = nil

    var recordZonesToSave: [RecordZone]? = nil
    var recordZoneIDsToDelete: [RecordZoneID]? = nil
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, Error?) -> Void)? = nil

    init(saved: [RecordZone]? = nil, deleted: [RecordZoneID]? = nil, error: Error? = nil) {
        self.saved = saved
        self.deleted = deleted
        self.error = error
        super.init()
    }

    override func main() {
        modifyRecordZonesCompletionBlock?(saved, deleted, error)
    }
}

class CKModifyRecordZonesOperationTests: CKProcedureTestCase {

    var target: TestCKModifyRecordZonesOperation!
    var operation: CKProcedure<TestCKModifyRecordZonesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKModifyRecordZonesOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__recordZonesToSave() {
        let recordZonesToSave = [ "a-record-zone", "another-record-zone" ]
        operation.recordZonesToSave = recordZonesToSave
        XCTAssertNotNil(operation.recordZonesToSave)
        XCTAssertEqual(operation.recordZonesToSave ?? [], recordZonesToSave)
        XCTAssertNotNil(target.recordZonesToSave)
        XCTAssertEqual(target.recordZonesToSave ?? [], recordZonesToSave)
    }

    func test__set_get__recordZoneIDsToDelete() {
        let recordZoneIDsToDelete = [ "a-record-zone-id", "another-record-zone-id" ]
        operation.recordZoneIDsToDelete = recordZoneIDsToDelete
        XCTAssertNotNil(operation.recordZoneIDsToDelete)
        XCTAssertEqual(operation.recordZoneIDsToDelete ?? [], recordZoneIDsToDelete)
        XCTAssertNotNil(target.recordZoneIDsToDelete)
        XCTAssertEqual(target.recordZoneIDsToDelete ?? [], recordZoneIDsToDelete)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifyRecordZonesCompletionBlock { savedRecordZones, deletedRecordZoneIDs in
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
        operation.setModifyRecordZonesCompletionBlock { savedRecordZones, deletedRecordZoneIDs in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

