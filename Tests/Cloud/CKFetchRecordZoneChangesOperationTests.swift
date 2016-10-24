//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchRecordZoneChangesOperation: TestCKDatabaseOperation, CKFetchRecordZoneChangesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = PKCKError
    typealias FetchRecordZoneChangesOptions = String

    typealias ResponseSimulationBlock = ((TestCKFetchRecordZoneChangesOperation) -> Error?)
    var responseSimulationBlock: ResponseSimulationBlock? = nil
    func setSimulationOutputError(error: Error) {
        responseSimulationBlock = { operation in
            return error
        }
    }

    var fetchAllChanges: Bool = true
    var recordZoneIDs: [RecordZoneID] = ["zone-id"]
    var optionsByRecordZoneID: [RecordZoneID : FetchRecordZoneChangesOptions]? = nil

    var recordChangedBlock: ((Record) -> Void)? = nil
    var recordWithIDWasDeletedBlock: ((RecordID, String) -> Void)? = nil
    var recordZoneChangeTokensUpdatedBlock: ((RecordZoneID, ServerChangeToken?, Data?) -> Void)? = nil
    var recordZoneFetchCompletionBlock: ((RecordZoneID, ServerChangeToken?, Data?, Bool, Error?) -> Void)? = nil
    var fetchRecordZoneChangesCompletionBlock: ((Error?) -> Void)? = nil

    init(responseSimulationBlock: ResponseSimulationBlock? = nil) {
        self.responseSimulationBlock = responseSimulationBlock
        super.init()
    }

    override func main() {
        let outputError = responseSimulationBlock?(self)
        fetchRecordZoneChangesCompletionBlock?(outputError)
    }
}

class CKFetchRecordZoneChangesOperationTests: CKProcedureTestCase {

    var target: TestCKFetchRecordZoneChangesOperation!
    var operation: CKProcedure<TestCKFetchRecordZoneChangesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchRecordZoneChangesOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__recordZoneIDs() {
        let recordZoneIDs: [String] = ["I'm a record zone ID"]
        operation.recordZoneIDs = recordZoneIDs
        XCTAssertEqual(operation.recordZoneIDs, recordZoneIDs)
        XCTAssertEqual(target.recordZoneIDs, recordZoneIDs)
    }

    func test__set_get__optionsByRecordZoneID() {
        let optionsByRecordZoneID = ["zone-id": "testoption"]
        operation.optionsByRecordZoneID = optionsByRecordZoneID
        XCTAssertNotNil(operation.optionsByRecordZoneID)
        XCTAssertEqual(operation.optionsByRecordZoneID!, optionsByRecordZoneID)
        XCTAssertNotNil(target.optionsByRecordZoneID)
        XCTAssertEqual(target.optionsByRecordZoneID!, optionsByRecordZoneID)
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
        let block: (String, String) -> Void = { recordID, recordType in
            setByBlock = true
        }
        operation.recordWithIDWasDeletedBlock = block
        XCTAssertNotNil(operation.recordWithIDWasDeletedBlock)
        target.recordWithIDWasDeletedBlock?("I'm a record ID", "ExampleType")
        XCTAssertTrue(setByBlock)
    }

    func test__set_get__recordZoneChangeTokensUpdatedBlock() {
        var setByBlock = false
        let block: (String, String?, Data?) -> Void = { recordZoneID, serverChangeToken, clientChangeTokenData in
            setByBlock = true
        }
        operation.recordZoneChangeTokensUpdatedBlock = block
        XCTAssertNotNil(operation.recordZoneChangeTokensUpdatedBlock)
        target.recordZoneChangeTokensUpdatedBlock?("I'm a record ID", "I'm a server change token", nil)
        XCTAssertTrue(setByBlock)
    }

    func test__set_get__recordZoneFetchCompletionBlock() {
        var setByBlock = false
        let block: (String, String?, Data?, Bool, Error?) -> Void = { recordZoneID, serverChangeToken, clientChangeTokenData, moreComing, recordZoneError in
            setByBlock = true
        }
        operation.recordZoneFetchCompletionBlock = block
        XCTAssertNotNil(operation.recordZoneFetchCompletionBlock)
        target.recordZoneFetchCompletionBlock?("I'm a record ID", "I'm a server change token", nil, false, nil)
        XCTAssertTrue(setByBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchRecordZoneChangesCompletionBlock { didExecuteBlock = true }
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block() {
        target.setSimulationOutputError(error: TestError())
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchRecordZoneChangesCompletionBlock { didExecuteBlock = true }
        target.setSimulationOutputError(error: TestError())
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}
