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
