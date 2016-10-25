//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchRecordZonesCompletionBlock { _ in
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
        operation.setFetchRecordZonesCompletionBlock { _ in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}
