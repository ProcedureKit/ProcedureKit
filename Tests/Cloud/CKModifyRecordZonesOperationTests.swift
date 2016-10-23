//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKModifyRecordZonesOperation: TestCKDatabaseOperation, CKModifyRecordZonesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = ModifyRecordZonesError<RecordZone, RecordZoneID>

    var saved: [RecordZone]? = nil
    var deleted: [RecordZoneID]? = nil
    var error: Error? = nil

    var recordZonesToSave: [RecordZone]? = nil
    var recordZoneIDsToDelete: [RecordZoneID]? = nil
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, Error?) -> Void)? = nil

    init(saved: [RecordZone]? = nil, deleted: [RecordZoneID]? = nil, error: Error? = nil) {
        self.saved = saved
        self.deleted = deleted
        self.error = error
        super.init()
    }

    override func main() {
        modifyRecordZonesCompletionBlock?(saved, deleted, error)
    }
}

