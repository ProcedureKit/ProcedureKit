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

class TestCKFetchRecordZonesOperation: TestCKDatabaseOperation, CKFetchRecordZonesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = FetchRecordZonesError<RecordZone, RecordZoneID>

    var zonesByID: [RecordZoneID: RecordZone]? = nil
    var error: Error? = nil
    var recordZoneIDs: [RecordZoneID]? = nil
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, Error?) -> Void)? = nil

    init(zonesByID: [RecordZoneID: RecordZone]? = nil, error: Error? = nil) {
        self.zonesByID = zonesByID
        self.error = error
        super.init()
    }

    override func main() {
        fetchRecordZonesCompletionBlock?(zonesByID, error)
    }
}

class CKFetchRecordZonesOperationTests: CKProcedureTestCase {

    var target: TestCKFetchRecordZonesOperation!
    var operation: CKProcedure<TestCKFetchRecordZonesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchRecordZonesOperation()
        operation = CKProcedure(operation: target)
    }

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
    }

    func test__set_get__recordZoneIDs() {
        let recordZoneIDs = [ "a-zone-id", "another-zone-id" ]
        operation.recordZoneIDs = recordZoneIDs
        XCTAssertNotNil(operation.recordZoneIDs)
        XCTAssertEqual(operation.recordZoneIDs!, recordZoneIDs)
        XCTAssertNotNil(target.recordZoneIDs)
        XCTAssertEqual(target.recordZoneIDs!, recordZoneIDs)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        PKAssertProcedureFinished(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchRecordZonesCompletionBlock { _ in
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
        operation.setFetchRecordZonesCompletionBlock { _ in
            didExecuteBlock = true
        }
        let error = TestError()
        target.error = error
        wait(for: operation)
        PKAssertProcedureFinished(operation, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureFetchRecordZonesOperationTests: CKProcedureTestCase {
    typealias T = TestCKFetchRecordZonesOperation
    var cloudkit: CloudKitProcedure<T>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchRecordZonesOperation() }
        cloudkit.container = container
        cloudkit.previousServerChangeToken = token
        cloudkit.resultsLimit = 10
        cloudkit.recordZoneIDs = [ "record zone 1 id", "record zone 2 id" ]
    }

    override func tearDown() {
        cloudkit = nil
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

    func test__set_get_previousServerChangeToken() {
        cloudkit.previousServerChangeToken = "I'm a different token!"
        XCTAssertEqual(cloudkit.previousServerChangeToken, "I'm a different token!")
    }

    func test__set_get_resultsLimit() {
        cloudkit.resultsLimit = 20
        XCTAssertEqual(cloudkit.resultsLimit, 20)
    }

    func test__set_get_recordZoneIDs() {
        cloudkit.recordZoneIDs = [ "record zone 1 id", "record zone 2 id" ]
        XCTAssertEqual(cloudkit.recordZoneIDs ?? [], [ "record zone 1 id", "record zone 2 id" ])
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
        cloudkit.setFetchRecordZonesCompletionBlock { _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchRecordZonesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__error_with_completion_block_set() {
        let error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchRecordZonesOperation()
            operation.error = error
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setFetchRecordZonesCompletionBlock { _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchRecordZonesOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setFetchRecordZonesCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchRecordZonesOperation()
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
        cloudkit.setFetchRecordZonesCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

