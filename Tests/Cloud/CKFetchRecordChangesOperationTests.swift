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

class CloudKitProcedureFetchRecordChangesOperationTests: CKProcedureTestCase {

    var cloudkit: CloudKitProcedure<TestCKFetchRecordChangesOperation>!

    var setByRecordChangedBlock: TestCKFetchRecordChangesOperation.Record!
    var setByRecordWithIDWasDeletedBlock: TestCKFetchRecordChangesOperation.RecordID!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchRecordChangesOperation() }
        cloudkit.container = container
        cloudkit.previousServerChangeToken = token
        cloudkit.resultsLimit = 10
        cloudkit.recordZoneID = "a record zone id"
        cloudkit.recordChangedBlock = { [unowned self] record in
            self.setByRecordChangedBlock = record
        }
        cloudkit.recordWithIDWasDeletedBlock = { [unowned self] recordId in
            self.setByRecordWithIDWasDeletedBlock = recordId
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

    func test__set_get_recordZoneID() {
        cloudkit.recordZoneID = "a record zone id"
        XCTAssertEqual(cloudkit.recordZoneID, "a record zone id")
    }

    func test__set_get_recordChangedBlock() {
        XCTAssertNotNil(cloudkit.recordChangedBlock)
        cloudkit.recordChangedBlock?("a record")
        XCTAssertEqual(setByRecordChangedBlock, "a record")
    }

    func test__set_get_recordWithIDWasDeletedBlock() {
        XCTAssertNotNil(cloudkit.recordWithIDWasDeletedBlock)
        cloudkit.recordWithIDWasDeletedBlock?("a record id")
        XCTAssertEqual(setByRecordWithIDWasDeletedBlock, "a record id")
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
        cloudkit.setFetchRecordChangesCompletionBlock { _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchRecordChangesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchRecordChangesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setFetchRecordChangesCompletionBlock { _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchRecordChangesOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setFetchRecordChangesCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchRecordChangesOperation()
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
        cloudkit.setFetchRecordChangesCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

