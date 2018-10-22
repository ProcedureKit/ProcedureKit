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

class TestCKFetchRecordZoneChangesOperation: TestCKDatabaseOperation, CKFetchRecordZoneChangesOperationProtocol, AssociatedErrorProtocol {

    typealias AssociatedError = PKCKError
    typealias FetchRecordZoneChangesOptions = String
    typealias FetchRecordZoneChangesConfiguration = String
    typealias ResponseSimulationBlock = ((TestCKFetchRecordZoneChangesOperation) -> Error?)
    typealias RecordZoneIDsPropertyType = Array<RecordZoneID>

    var responseSimulationBlock: ResponseSimulationBlock? = nil
    var fetchAllChanges: Bool = true
    var recordZoneIDs: [RecordZoneID] = ["zone-id"]
    var optionsByRecordZoneID: [RecordZoneID: String]? = nil
    var configurationsByRecordZoneID: [String : String]?
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

    func setSimulationOutputError(error: Error) {
        responseSimulationBlock = { operation in
            return error
        }
    }
}

class CKFetchRecordZoneChangesOperationTests: CKProcedureTestCase {

    typealias RecordZoneID = TestCKFetchRecordZoneChangesOperation.RecordZoneID

    var target: TestCKFetchRecordZoneChangesOperation!
    var operation: CKProcedure<TestCKFetchRecordZoneChangesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchRecordZoneChangesOperation()
        operation = CKProcedure(operation: target)
    }

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
    }

    func test__set_get__recordZoneIDs() {
        let recordZoneIDs: [RecordZoneID] = ["I'm a record zone ID"]
        operation.recordZoneIDs = recordZoneIDs
        XCTAssertEqual(operation.recordZoneIDs, recordZoneIDs)
        XCTAssertEqual(target.recordZoneIDs, recordZoneIDs)
    }

    @available(iOS, introduced: 10.0, deprecated: 12.0)
    @available(OSX, introduced: 10.12, deprecated: 10.14)
    @available(tvOS, introduced: 10.0, deprecated: 12.0)
    @available(watchOS, introduced: 3.0, deprecated: 5.0)
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
        PKAssertProcedureFinished(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchRecordZoneChangesCompletionBlock { didExecuteBlock = true }
        wait(for: operation)
        PKAssertProcedureFinished(operation)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block() {
        target.setSimulationOutputError(error: TestError())
        wait(for: operation)
        PKAssertProcedureFinished(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchRecordZoneChangesCompletionBlock { didExecuteBlock = true }
        target.setSimulationOutputError(error: TestError())
        wait(for: operation)
        PKAssertProcedureFinished(operation, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureFetchRecordZoneChangesOperationTests: CKProcedureTestCase {
    typealias T = TestCKFetchRecordZoneChangesOperation
    var cloudkit: CloudKitProcedure<T>!

    var setByRecordChangedBlock: T.Record!
    var setByRecordWithIDWasDeletedBlock: (T.RecordID, String)!
    var setByRecordZoneChangeTokensUpdatedBlock: (T.RecordZoneID, T.ServerChangeToken?, Data?)!
    var setByRecordZoneFetchCompletionBlock: (T.RecordZoneID, T.ServerChangeToken?, Data?, Bool, Error?)!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchRecordZoneChangesOperation() }
        cloudkit.container = container
        cloudkit.previousServerChangeToken = token
        cloudkit.resultsLimit = 10
        cloudkit.recordZoneIDs = [ "record zone 1 id", "record zone 2 id" ]
        if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
            cloudkit.configurationsByRecordZoneID = [ "record zone 1 id": "configuration 1", "record zone 2 id": "configuration 2" ]
        }
        else if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            cloudkit.optionsByRecordZoneID = [ "record zone 1 id": "option 1", "record zone 2 id": "option 2" ]
        }
        cloudkit.fetchAllChanges = false
        cloudkit.recordChangedBlock = { [unowned self] record in
            self.setByRecordChangedBlock = record
        }
        cloudkit.recordWithIDWasDeletedBlock = { [unowned self] recordId, type in
            self.setByRecordWithIDWasDeletedBlock = (recordId, type)
        }
        cloudkit.recordZoneChangeTokensUpdatedBlock = { [unowned self] zoneId, token, data in
            self.setByRecordZoneChangeTokensUpdatedBlock = (zoneId, token, data)
        }
        cloudkit.recordZoneFetchCompletionBlock = { [unowned self] zoneId, token, data, isComplete, error in
            self.setByRecordZoneFetchCompletionBlock = (zoneId, token, data, isComplete, error)
        }
    }

    override func tearDown() {
        cloudkit = nil
        setByRecordChangedBlock = nil
        setByRecordWithIDWasDeletedBlock = nil
        setByRecordZoneChangeTokensUpdatedBlock = nil
        setByRecordZoneFetchCompletionBlock = nil
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

    func test__set_get_fetchAllChanges() {
        cloudkit.fetchAllChanges = true
        XCTAssertEqual(cloudkit.fetchAllChanges, true)
    }

    func test__set_get_recordZoneIDs() {
        cloudkit.recordZoneIDs = [ "record zone 1 id", "record zone 2 id" ]
        XCTAssertEqual(cloudkit.recordZoneIDs, [ "record zone 1 id", "record zone 2 id" ])
    }

    @available(iOS, introduced: 10.0, deprecated: 12.0)
    @available(OSX, introduced: 10.12, deprecated: 10.14)
    @available(tvOS, introduced: 10.0, deprecated: 12.0)
    @available(watchOS, introduced: 3.0, deprecated: 5.0)
    func test__set_get_optionsByRecordZoneID() {
        cloudkit.optionsByRecordZoneID = [ "record zone 1 id": "option 1", "record zone 2 id": "option 2" ]
        XCTAssertEqual(cloudkit.optionsByRecordZoneID ?? [:], [ "record zone 1 id": "option 1", "record zone 2 id": "option 2" ])
    }

    @available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *)
    func test__set_get_configurationsByRecordZoneID() {
        cloudkit.configurationsByRecordZoneID = [ "record zone 1 id": "configuration 1", "record zone 2 id": "configuration 2" ]
        XCTAssertEqual(cloudkit.configurationsByRecordZoneID ?? [:], [ "record zone 1 id": "configuration 1", "record zone 2 id": "configuration 2" ])
    }

    func test__set_get_recordChangedBlock() {
        XCTAssertNotNil(cloudkit.recordChangedBlock)
        cloudkit.recordChangedBlock?("a record")
        XCTAssertEqual(setByRecordChangedBlock, "a record")
    }

    func test__set_get_recordWithIDWasDeletedBlock() {
        XCTAssertNotNil(cloudkit.recordWithIDWasDeletedBlock)
        cloudkit.recordWithIDWasDeletedBlock?("a record id", "record type")
        XCTAssertEqual(setByRecordWithIDWasDeletedBlock?.0, "a record id")
        XCTAssertEqual(setByRecordWithIDWasDeletedBlock?.1, "record type")
    }

    func test__set_get_recordZoneChangeTokensUpdatedBlock() {
        XCTAssertNotNil(cloudkit.recordZoneChangeTokensUpdatedBlock)
        cloudkit.recordZoneChangeTokensUpdatedBlock?("zone id", "token", nil)
        XCTAssertEqual(setByRecordZoneChangeTokensUpdatedBlock?.0, "zone id")
        XCTAssertEqual(setByRecordZoneChangeTokensUpdatedBlock?.1, "token")
        XCTAssertNil(setByRecordZoneChangeTokensUpdatedBlock?.2)
    }

    func test__set_get_recordZoneFetchCompletionBlock() {
        XCTAssertNotNil(cloudkit.recordZoneFetchCompletionBlock)
        let error = TestError()
        cloudkit.recordZoneFetchCompletionBlock?("zone id", "token", nil, false, error)
        XCTAssertEqual(setByRecordZoneFetchCompletionBlock?.0, "zone id")
        XCTAssertEqual(setByRecordZoneFetchCompletionBlock?.1, "token")
        XCTAssertNil(setByRecordZoneFetchCompletionBlock?.2)
        XCTAssertFalse(setByRecordZoneFetchCompletionBlock?.3 ?? true)
        XCTAssertEqual(setByRecordZoneFetchCompletionBlock?.4 as? TestError ?? TestError(), error)
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
        cloudkit.setFetchRecordZoneChangesCompletionBlock {
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            return TestCKFetchRecordZoneChangesOperation { _ in
                NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            }
        }
        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            return TestCKFetchRecordZoneChangesOperation { _ in
                NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            }
        }

        var didExecuteBlock = false
        cloudkit.setFetchRecordZoneChangesCompletionBlock { 
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        PKAssertProcedureFinished(cloudkit, withErrors: true)
        XCTAssertFalse(didExecuteBlock)
    }
}

