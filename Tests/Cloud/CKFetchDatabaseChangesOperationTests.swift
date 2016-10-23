//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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


