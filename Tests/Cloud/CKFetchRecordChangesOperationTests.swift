//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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
