//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKOperation: Operation, CKOperationProtocol {

    typealias ServerChangeToken = String
    typealias RecordZone = String
    typealias RecordZoneID = String
    typealias Notification = String
    typealias NotificationID = String
    typealias Record = String
    typealias RecordID = String
    typealias Subscription = String
    typealias RecordSavePolicy = Int
    typealias DiscoveredUserInfo = String
    typealias Query = String
    typealias QueryCursor = String

    typealias UserIdentity = String
    typealias UserIdentityLookupInfo = String
    typealias Share = String
    typealias ShareMetadata = String
    typealias ShareParticipant = String

    var container: String? // just a test
    var allowsCellularAccess: Bool = true

    //@available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
    var operationID: String = ""
    var longLived: Bool = false

    var longLivedOperationWasPersistedBlock: () -> Void = { }

    //@available(iOS 10.0, tvOS 10.0, OSX 10.12, watchOS 3.0, *)
    var timeoutIntervalForRequest: TimeInterval = 0
    var timeoutIntervalForResource: TimeInterval = 0
}

class CKOperationTests: CKProcedureTestCase {

    var target: TestCKOperation!
    var operation: CKProcedure<TestCKOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__container() {
        let container = "I'm a cloud kit container"
        operation.container = container
        XCTAssertEqual(operation.container, container)
        XCTAssertEqual(target.container, container)
    }

    func test__set_get__allowsCellularAccess() {
        let allowsCellularAccess = true
        operation.allowsCellularAccess = allowsCellularAccess
        XCTAssertEqual(operation.allowsCellularAccess, allowsCellularAccess)
        XCTAssertEqual(target.allowsCellularAccess, allowsCellularAccess)
    }

    @available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
    func test__get_operationID() {
        let operationID = "test operationID"
        target.operationID = operationID
        XCTAssertEqual(operation.operationID, operationID)
    }

    @available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
    func test__set_get__longLived() {
        let longLived = true
        operation.longLived = longLived
        XCTAssertEqual(operation.longLived, longLived)
        XCTAssertEqual(target.longLived, longLived)
    }

    @available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
    func test__set_get__longLivedOperationWasPersistedBlock() {
        var setByBlock = false
        let block: () -> Void = { setByBlock = true }
        operation.longLivedOperationWasPersistedBlock = block
        operation.longLivedOperationWasPersistedBlock()
        XCTAssertTrue(setByBlock)
    }

    @available(iOS 10.0, tvOS 10.0, OSX 10.12, watchOS 3.0, *)
    func test__set_get__timeoutIntervalForRequest() {
        let timeout: TimeInterval = 42
        operation.timeoutIntervalForRequest = timeout
        XCTAssertEqual(operation.timeoutIntervalForRequest, timeout)
        XCTAssertEqual(target.timeoutIntervalForRequest, timeout)
    }

    @available(iOS 10.0, tvOS 10.0, OSX 10.12, watchOS 3.0, *)
    func test__set_get__timeoutIntervalForResource() {
        let timeout: TimeInterval = 42
        operation.timeoutIntervalForResource = timeout
        XCTAssertEqual(operation.timeoutIntervalForResource, timeout)
        XCTAssertEqual(target.timeoutIntervalForResource, timeout)
    }
}
