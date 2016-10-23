//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKQueryOperation: TestCKDatabaseOperation, CKQueryOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = QueryError<QueryCursor>

    var error: Error? = nil
    var query: Query? = nil
    var cursor: QueryCursor? = nil
    var zoneID: RecordZoneID? = nil
    var recordFetchedBlock: ((Record) -> Void)? = nil
    var queryCompletionBlock: ((QueryCursor?, Error?) -> Void)? = nil

    init(error: Error? = nil) {
        self.error = error
        super.init()
    }

    override func main() {
        queryCompletionBlock?(cursor, error)
    }
}
