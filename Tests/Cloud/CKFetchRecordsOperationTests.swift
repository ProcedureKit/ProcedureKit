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

