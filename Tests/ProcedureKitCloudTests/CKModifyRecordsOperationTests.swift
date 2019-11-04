//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import CloudKit
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

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
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
        PKAssertProcedureFinished(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifyRecordsCompletionBlock { savedRecords, deletedRecordIDs in
            didExecuteBlock = true
        }
        wait(for: operation)
        PKAssertProcedureFinished(operation)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block() {
        target.error = TestError()
        wait(for: operation)
        PKAssertProcedureFinished(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifyRecordsCompletionBlock { savedRecords, deletedRecordIDs in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        PKAssertProcedureFinished(operation, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureModifyRecordsOperationTests: CKProcedureTestCase {
    typealias T = TestCKModifyRecordsOperation
    var cloudkit: CloudKitProcedure<T>!

    var setByPerRecordProgressBlock: CloudKitProcedure<T>.ModifyRecordsPerRecordProgress!
    var setByPerRecordCompletionBlock: CloudKitProcedure<T>.ModifyRecordsPerRecordCompletion!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKModifyRecordsOperation() }
        cloudkit.container = container
        cloudkit.recordsToSave = [ "record 1" ]
        cloudkit.recordIDsToDelete = [ "record 2 ID" ]
        cloudkit.savePolicy = 1
        cloudkit.clientChangeTokenData = "hello-world".data(using: .utf8)
        cloudkit.isAtomic = true
        cloudkit.perRecordProgressBlock = { self.setByPerRecordProgressBlock = ($0, $1) }
        cloudkit.perRecordCompletionBlock = { self.setByPerRecordCompletionBlock = ($0, $1) }
    }

    override func tearDown() {
        cloudkit = nil
        setByPerRecordProgressBlock = nil
        setByPerRecordCompletionBlock = nil
        super.tearDown()
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

    func test__set_get_recordsToSave() {
        cloudkit.recordsToSave = [ "record 3" ]
        XCTAssertEqual(cloudkit.recordsToSave ?? [], [ "record 3" ])
    }

    func test__set_get_recordIDsToDelete() {
        cloudkit.recordIDsToDelete = [ "record 4 ID" ]
        XCTAssertEqual(cloudkit.recordIDsToDelete ?? [], [ "record 4 ID" ])
    }

    func test__set_get_savePolicy() {
        cloudkit.savePolicy = 2
        XCTAssertEqual(cloudkit.savePolicy, 2)
    }

    func test__set_get__clientChangeTokenData() {
        let clientChangeTokenData = "this-is-some-data".data(using: .utf8)
        cloudkit.clientChangeTokenData = clientChangeTokenData
        XCTAssertEqual(cloudkit.clientChangeTokenData, clientChangeTokenData)
    }

    func test__set_get_isAtomic() {
        cloudkit.isAtomic = false
        XCTAssertEqual(cloudkit.isAtomic, false)
    }

    func test__set_get_perRecordProgressBlock() {
        XCTAssertNotNil(cloudkit.perRecordProgressBlock)
        cloudkit.perRecordProgressBlock?("record 1", 0.5)
        XCTAssertEqual(setByPerRecordProgressBlock?.0 ?? "not record 1", "record 1")
        XCTAssertEqual(setByPerRecordProgressBlock?.1 ?? 0.1, 0.5)
    }

    func test__set_get_perRecordCompletionBlock() {
        XCTAssertNotNil(cloudkit.perRecordCompletionBlock)
        let anError = TestError()
        cloudkit.perRecordCompletionBlock?("record 2", anError)
        XCTAssertEqual(setByPerRecordCompletionBlock?.0 ?? "not record 2", "record 2")
        XCTAssertEqual(setByPerRecordCompletionBlock?.1 as? TestError ?? TestError(), anError)
    }

    func test__cancellation() {
        cloudkit.cancel()
        wait(for: cloudkit)
        PKAssertProcedureCancelled(cloudkit)
    }

    func test__success_without_completion_block_set() {
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__success_with_completion_block_set() {
        var didExecuteBlock = false
        cloudkit.setModifyRecordsCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKModifyRecordsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKModifyRecordsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setModifyRecordsCompletionBlock { _, _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKModifyRecordsOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setModifyRecordsCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKModifyRecordsOperation()
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
        cloudkit.setModifyRecordsCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

