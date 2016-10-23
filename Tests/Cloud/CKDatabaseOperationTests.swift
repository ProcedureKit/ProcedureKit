//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKDatabaseOperation: TestCKOperation, CKDatabaseOperationProtocol, CKPreviousServerChangeToken, CKResultsLimit, CKMoreComing, CKDesiredKeys {
    var database: String?
    var previousServerChangeToken: ServerChangeToken? = nil
    var resultsLimit: Int = 100
    var moreComing: Bool = false
    var desiredKeys: [String]? = nil
}
