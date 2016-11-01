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
    typealias Database = String

    var database: String?
    var previousServerChangeToken: ServerChangeToken? = nil
    var resultsLimit: Int = 100
    var moreComing: Bool = false
    var desiredKeys: [String]? = nil
}

class CKDatabaseOperationTests: CKProcedureTestCase {

    var target: TestCKDatabaseOperation!
    var operation: CKProcedure<TestCKDatabaseOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKDatabaseOperation()
        operation = CKProcedure(operation: target)
    }
    
    func test__set_get__database() {
        let database = "I'm a cloud kit database"
        operation.database = database
        XCTAssertEqual(operation.database, database)
        XCTAssertEqual(target.database, database)
    }

    func test__set_get__previousServerChangeToken() {
        let token = "I'm a server change token"
        operation.previousServerChangeToken = token
        XCTAssertEqual(operation.previousServerChangeToken, token)
        XCTAssertEqual(target.previousServerChangeToken, token)
    }

    func test__set_get__resultsLimits() {
        let limit: Int = 100
        operation.resultsLimit = limit
        XCTAssertEqual(operation.resultsLimit, limit)
        XCTAssertEqual(target.resultsLimit, limit)
    }

    func test__get__moreComing() {
        target.moreComing = true
        XCTAssertTrue(operation.moreComing)
        target.moreComing = false
        XCTAssertFalse(operation.moreComing)

    }

    func test__set_get__desiredKeys() {
        let keys = [ "desired-key-1",  "desired-key-2" ]
        operation.desiredKeys = keys
        XCTAssertEqual(operation.desiredKeys ?? [], keys)
        XCTAssertEqual(target.desiredKeys ?? [], keys)
    }
}
