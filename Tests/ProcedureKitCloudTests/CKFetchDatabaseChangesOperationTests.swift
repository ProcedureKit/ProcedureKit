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

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
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

class CloudKitProcedureFetchDatabaseChangesOperationTests: CKProcedureTestCase {

    var cloudkit: CloudKitProcedure<TestCKFetchDatabaseChangesOperation>!

    var setByRecordZoneWithIDChangedBlock: TestCKFetchDatabaseChangesOperation.RecordZoneID!
    var setByRecordZoneWithIDWasDeletedBlock: TestCKFetchDatabaseChangesOperation.RecordZoneID!
    var setByChangeTokenUpdatedBlock: TestCKFetchDatabaseChangesOperation.ServerChangeToken!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchDatabaseChangesOperation() }
        cloudkit.container = container
        cloudkit.database = database
        cloudkit.previousServerChangeToken = token
        cloudkit.resultsLimit = 10
        cloudkit.fetchAllChanges = true
        cloudkit.recordZoneWithIDChangedBlock = { [unowned self] recordZoneID in
            self.setByRecordZoneWithIDChangedBlock = recordZoneID
        }
        cloudkit.recordZoneWithIDWasDeletedBlock = { [unowned self] recordZoneID in
            self.setByRecordZoneWithIDWasDeletedBlock = recordZoneID
        }
        cloudkit.changeTokenUpdatedBlock = { [unowned self] token in
            self.setByChangeTokenUpdatedBlock = token
        }
    }

    override func tearDown() {
        cloudkit = nil
        setByRecordZoneWithIDChangedBlock = nil
        setByRecordZoneWithIDWasDeletedBlock = nil
        setByChangeTokenUpdatedBlock = nil
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

    func test__set_get_fetchAllChanges() {
        cloudkit.fetchAllChanges = false
        XCTAssertEqual(cloudkit.fetchAllChanges, false)
    }

    func test__set_get_recordZoneWithIDChangedBlock() {
        XCTAssertNotNil(cloudkit.recordZoneWithIDChangedBlock)
        cloudkit.recordZoneWithIDChangedBlock?("record zone ID")
        XCTAssertEqual(setByRecordZoneWithIDChangedBlock, "record zone ID")
    }

    func test__set_get_recordZoneWithIDWasDeletedBlock() {
        XCTAssertNotNil(cloudkit.recordZoneWithIDWasDeletedBlock)
        cloudkit.recordZoneWithIDWasDeletedBlock?("record zone ID")
        XCTAssertEqual(setByRecordZoneWithIDWasDeletedBlock, "record zone ID")
    }

    func test__set_get_changeTokenUpdatedBlock() {
        XCTAssertNotNil(cloudkit.changeTokenUpdatedBlock)
        cloudkit.changeTokenUpdatedBlock?("new change token")
        XCTAssertEqual(setByChangeTokenUpdatedBlock, "new change token")
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
        cloudkit.setFetchDatabaseChangesCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchDatabaseChangesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchDatabaseChangesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setFetchDatabaseChangesCompletionBlock { _, _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchDatabaseChangesOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setFetchDatabaseChangesCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchDatabaseChangesOperation()
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
        cloudkit.setFetchDatabaseChangesCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

