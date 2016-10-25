//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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
