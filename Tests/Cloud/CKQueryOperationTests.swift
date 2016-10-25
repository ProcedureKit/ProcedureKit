//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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
