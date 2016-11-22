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

class CloudKitProcedureModifyRecordZonesOperationTests: CKProcedureTestCase {
    typealias T = TestCKModifyRecordZonesOperation
    var cloudkit: CloudKitProcedure<T>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKModifyRecordZonesOperation() }
        cloudkit.container = container
        cloudkit.recordZonesToSave = [ "record zone 1" ]
        cloudkit.recordZoneIDsToDelete = [ "record zone 2 ID" ]
    }

    func test__set_get__errorHandlers() {
        cloudkit.set(errorHandlers: [.internalError: cloudkit.passthroughSuggestedErrorHandler])
        XCTAssertEqual(cloudkit.errorHandlers.count, 1)
        XCTAssertNotNil(cloudkit.errorHandlers[.internalError])
    }

    func test__set_get_container() {
        cloudkit.container = "I'm a different container!"
        XCTAssertEqual(cloudkit.container, "I'm a different container!")
    }

    func test__set_get_database() {
        cloudkit.database = "I'm a different database!"
        XCTAssertEqual(cloudkit.database, "I'm a different database!")
    }

    func test__set_get_previousServerChangeToken() {
        cloudkit.previousServerChangeToken = "I'm a different token!"
        XCTAssertEqual(cloudkit.previousServerChangeToken, "I'm a different token!")
    }

    func test__set_get_resultsLimit() {
        cloudkit.resultsLimit = 20
        XCTAssertEqual(cloudkit.resultsLimit, 20)
    }

    func test__set_get_recordZonesToSave() {
        cloudkit.recordZonesToSave = [ "record zone 3" ]
        XCTAssertEqual(cloudkit.recordZonesToSave ?? [], [ "record zone 3" ])
    }

    func test__set_get_recordZoneIDsToDelete() {
        cloudkit.recordZoneIDsToDelete = [ "record zone 4 ID" ]
        XCTAssertEqual(cloudkit.recordZoneIDsToDelete ?? [], [ "record zone 4 ID" ])
    }

    func test__cancellation() {
        cloudkit.cancel()
        wait(for: cloudkit)
        XCTAssertProcedureCancelledWithoutErrors(cloudkit)
    }

    func test__success_without_completion_block_set() {
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__success_with_completion_block_set() {
        var didExecuteBlock = false
        cloudkit.setModifyRecordZonesCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKModifyRecordZonesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKModifyRecordZonesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setModifyRecordZonesCompletionBlock { _, _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKModifyRecordZonesOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setModifyRecordZonesCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKModifyRecordZonesOperation()
            if shouldError {
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.limitExceeded.rawValue, userInfo: nil)
                shouldError = false
            }
            return op
        }
        var didRunCustomHandler = false
        cloudkit.set(errorHandlerForCode: .limitExceeded) { _, _, _, suggestion in
            didRunCustomHandler = true
            return suggestion
        }

        var didExecuteBlock = false
        cloudkit.setModifyRecordZonesCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

