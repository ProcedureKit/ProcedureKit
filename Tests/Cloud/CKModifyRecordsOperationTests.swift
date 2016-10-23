//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKModifyRecordsOperation: TestCKDatabaseOperation, CKModifyRecordsOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = ModifyRecordsError<Record, RecordID>

    var saved: [Record]?
    var deleted: [RecordID]?
    var error: Error?

    var recordsToSave: [Record]? = nil
    var recordIDsToDelete: [RecordID]? = nil
    var savePolicy: RecordSavePolicy = 0
    var clientChangeTokenData: Data? = nil
    var isAtomic: Bool = true

    var perRecordProgressBlock: ((Record, Double) -> Void)? = nil
    var perRecordCompletionBlock: ((Record?, Error?) -> Void)? = nil
    var modifyRecordsCompletionBlock: (([Record]?, [RecordID]?, Error?) -> Void)? = nil

    init(saved: [Record]? = nil, deleted: [RecordID]? = nil, error: Error? = nil) {
        self.saved = saved
        self.deleted = deleted
        self.error = error
        super.init()
    }

    override func main() {
        modifyRecordsCompletionBlock?(saved, deleted, error)
    }
}

