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
