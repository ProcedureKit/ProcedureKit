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

class TestCKFetchRecordsOperation: TestCKDatabaseOperation, CKFetchRecordsOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = FetchRecordsError<Record, RecordID>

    var recordsByID: [RecordID: Record]? = nil
    var error: Error? = nil
    var recordIDs: [RecordID]? = nil
    var perRecordProgressBlock: ((RecordID, Double) -> Void)? = nil
    var perRecordCompletionBlock: ((Record?, RecordID?, Error?) -> Void)? = nil
    var fetchRecordsCompletionBlock: (([RecordID: Record]?, Error?) -> Void)? = nil

    init(recordsByID: [RecordID: Record]? = nil, error: Error? = nil) {
        self.recordsByID = recordsByID
        self.error = error
        super.init()
    }

    override func main() {
        fetchRecordsCompletionBlock?(recordsByID, error)
    }
}

class CKFetchRecordsOperationTests: CKProcedureTestCase {

    var target: TestCKFetchRecordsOperation!
    var operation: CKProcedure<TestCKFetchRecordsOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchRecordsOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__recordIDs() {
        let recordIDs: [String] = ["I'm a record ID"]
        operation.recordIDs = recordIDs
        XCTAssertNotNil(operation.recordIDs)
        XCTAssertEqual(operation.recordIDs!, recordIDs)
        XCTAssertNotNil(target.recordIDs)
        XCTAssertEqual(target.recordIDs!, recordIDs)
    }

    func test__set_get__perRecordProgressBlock() {
        var setByBlock = false
        let block: (String, Double) -> Void = { recordID, progress in
            setByBlock = true
        }
        operation.perRecordProgressBlock = block
        XCTAssertNotNil(operation.perRecordProgressBlock)
        target.perRecordProgressBlock?("I'm a record ID", 50.0)
        XCTAssertTrue(setByBlock)
    }

    func test__set_get__perRecordCompletionBlock() {
        var setByBlock = false
        let block: (String?, String?, Error?) -> Void = { record, recordID, error in
            setByBlock = true
        }
        operation.perRecordCompletionBlock = block
        XCTAssertNotNil(operation.perRecordCompletionBlock)
        target.perRecordCompletionBlock?("I'm a record", "I'm a record ID", nil)
        XCTAssertTrue(setByBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchRecordsCompletionBlock { _ in
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
        operation.setFetchRecordsCompletionBlock { _ in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureFetchRecordOperationTests: CKProcedureTestCase {

    var cloudkit: CloudKitProcedure<TestCKFetchRecordsOperation>!

    var setByPerRecordProgressBlock: (TestCKFetchRecordsOperation.RecordID, Double)!
    var setByPerRecordCompletionBlock: (TestCKFetchRecordsOperation.Record?, TestCKFetchRecordsOperation.RecordID?, Error?)!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchRecordsOperation() }
        cloudkit.container = container
        cloudkit.previousServerChangeToken = token
        cloudkit.resultsLimit = 10
        cloudkit.recordIDs = [ "record 1", "record 2" ]
        cloudkit.perRecordProgressBlock = { [unowned self] record, progress in
            self.setByPerRecordProgressBlock = (record, progress)
        }
        cloudkit.perRecordCompletionBlock = { [unowned self] record, recordID, error in
            self.setByPerRecordCompletionBlock = (record, recordID, error)
        }
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

    func test__set_get_previousServerChangeToken() {
        cloudkit.previousServerChangeToken = "I'm a different token!"
        XCTAssertEqual(cloudkit.previousServerChangeToken, "I'm a different token!")
    }

    func test__set_get_resultsLimit() {
        cloudkit.resultsLimit = 20
        XCTAssertEqual(cloudkit.resultsLimit, 20)
    }

    func test__set_get_recordIDs() {
        cloudkit.recordIDs = [ "record id 3", "record id 4" ]
        XCTAssertEqual(cloudkit.recordIDs ?? [], [ "record id 3", "record id 4" ])
    }

    func test__set_get_perRecordProgressBlock() {
        XCTAssertNotNil(cloudkit.perRecordProgressBlock)
        cloudkit.perRecordProgressBlock?("a record id", 0.1)
        XCTAssertEqual(setByPerRecordProgressBlock?.0, "a record id")
        XCTAssertEqual(setByPerRecordProgressBlock?.1, 0.1)
    }

    func test__set_get_perRecordCompletionBlock() {
        let error = TestError()
        XCTAssertNotNil(cloudkit.perRecordCompletionBlock)
        cloudkit.perRecordCompletionBlock?("a record", "a record id", error)
        XCTAssertEqual(setByPerRecordCompletionBlock?.0, "a record")
        XCTAssertEqual(setByPerRecordCompletionBlock?.1, "a record id")
        XCTAssertEqual(setByPerRecordCompletionBlock?.2 as? TestError ?? TestError(), error)
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
        cloudkit.setFetchRecordsCompletionBlock { _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchRecordsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchRecordsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setFetchRecordsCompletionBlock { _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchRecordsOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setFetchRecordsCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchRecordsOperation()
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
        cloudkit.setFetchRecordsCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

