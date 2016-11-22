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

class TestCKQueryOperation: TestCKDatabaseOperation, CKQueryOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = QueryError<QueryCursor>

    var error: Error? = nil
    var query: Query? = nil
    var cursor: QueryCursor? = nil
    var zoneID: RecordZoneID? = nil
    var recordFetchedBlock: ((Record) -> Void)? = nil
    var queryCompletionBlock: ((QueryCursor?, Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        queryCompletionBlock?(cursor, error)
    }
}

class CKQueryOperationTests: CKProcedureTestCase {

    var target: TestCKQueryOperation!
    var operation: CKProcedure<TestCKQueryOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKQueryOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__query() {
        let query = "a-query"
        operation.query = query
        XCTAssertNotNil(operation.query)
        XCTAssertEqual(operation.query, query)
        XCTAssertNotNil(target.query)
        XCTAssertEqual(target.query, query)
    }

    func test__set_get__cursor() {
        let cursor = "a-cursor"
        operation.cursor = cursor
        XCTAssertNotNil(operation.cursor)
        XCTAssertEqual(operation.cursor, cursor)
        XCTAssertNotNil(target.cursor)
        XCTAssertEqual(target.cursor, cursor)
    }

    func test__set_get__zoneID() {
        let zoneID = "a-zone-id"
        operation.zoneID = zoneID
        XCTAssertNotNil(operation.zoneID)
        XCTAssertEqual(operation.zoneID, zoneID)
        XCTAssertNotNil(target.zoneID)
        XCTAssertEqual(target.zoneID, zoneID)
    }

    func test__set_get__recordFetchedBlock() {
        var setByCompletionBlock = false
        let block: (String) -> Void = { record in
            setByCompletionBlock = true
        }
        operation.recordFetchedBlock = block
        XCTAssertNotNil(operation.recordFetchedBlock)
        target.recordFetchedBlock?("a-record")
        XCTAssertTrue(setByCompletionBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setQueryCompletionBlock { cursor in
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
        operation.setQueryCompletionBlock { cursor in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureQueryOperationTests: CKProcedureTestCase {
    typealias T = TestCKQueryOperation
    var cloudkit: CloudKitProcedure<T>!

    var setByQueryRecordFetchedBlock: T.Record!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKQueryOperation() }
        cloudkit.container = container
        cloudkit.query = "a query"
        cloudkit.cursor = "a cursor"
        cloudkit.zoneID = "a zone 1 ID"
        cloudkit.recordFetchedBlock = { self.setByQueryRecordFetchedBlock = $0 }
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

    func test__set_get_query() {
        cloudkit.query = "a query"
        XCTAssertEqual(cloudkit.query, "a query")
    }

    func test__set_get_cursor() {
        cloudkit.cursor = "a cursor"
        XCTAssertEqual(cloudkit.cursor, "a cursor")
    }

    func test__set_get_zoneID() {
        cloudkit.zoneID = "a zone 2 ID"
        XCTAssertEqual(cloudkit.zoneID, "a zone 2 ID")
    }

    func test__set_get_queryRecordFetchedBlock() {
        XCTAssertNotNil(cloudkit.recordFetchedBlock)
        cloudkit.recordFetchedBlock?("a record")
        XCTAssertEqual(setByQueryRecordFetchedBlock ?? "incorrect", "a record")
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
        cloudkit.setQueryCompletionBlock { _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKQueryOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKQueryOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setQueryCompletionBlock { _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKQueryOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setQueryCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKQueryOperation()
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
        cloudkit.setQueryCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}
