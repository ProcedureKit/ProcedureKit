//
//  CloudKitOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/01/2016.
//
//

import XCTest
import CloudKit
@testable import Operations

class CloudKitOperationTests: OperationTests { }

// MARK: Test Operations

class TestCloudOperation: NSOperation, CKOperationType {
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

    var container: String? // just a test
}

class TestDatabaseOperation: TestCloudOperation, CKDatabaseOperationType, CKPreviousServerChangeToken, CKResultsLimit, CKMoreComing, CKDesiredKeys {
    var database: String?
    var previousServerChangeToken: ServerChangeToken? = .None
    var resultsLimit: Int = 100
    var moreComing: Bool = false
    var desiredKeys: [String]? = .None
}

class TestDiscoverAllContactsOperation: TestCloudOperation, CKDiscoverAllContactsOperationType {

    var result: [DiscoveredUserInfo]?
    var error: NSError?
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, NSError?) -> Void)? = .None

    init(result: [DiscoveredUserInfo]? = .None, error: NSError? = .None) {
        self.result = result
        self.error = error
        super.init()
    }

    override func main() {
        discoverAllContactsCompletionBlock?(result, error)
    }
}

class TestDiscoverUserInfosOperation: TestCloudOperation, CKDiscoverUserInfosOperationType {

    var emailAddresses: [String]?
    var userRecordIDs: [RecordID]?
    var userInfosByEmailAddress: [String: DiscoveredUserInfo]?
    var userInfoByRecordID: [RecordID: DiscoveredUserInfo]?
    var error: NSError?
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, NSError?) -> Void)?

    init(userInfosByEmailAddress: [String: DiscoveredUserInfo]? = .None, userInfoByRecordID: [RecordID: DiscoveredUserInfo]? = .None, error: NSError? = .None) {
        self.userInfosByEmailAddress = userInfosByEmailAddress
        self.userInfoByRecordID = userInfoByRecordID
        self.error = error
        super.init()
    }

    override func main() {
        discoverUserInfosCompletionBlock?(userInfosByEmailAddress, userInfoByRecordID, error)
    }
}

class TestFetchNotificationChangesOperation: TestCloudOperation, CKFetchNotificationChangesOperationType {

    var error: NSError?
    var finalPreviousServerChangeToken: ServerChangeToken?

    var previousServerChangeToken: ServerChangeToken? = .None
    var resultsLimit: Int = 100
    var moreComing: Bool = false
    var notificationChangedBlock: (Notification -> Void)? = .None
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, NSError?) -> Void)? = .None

    init(token: ServerChangeToken? = .None, error: NSError? = .None) {
        self.finalPreviousServerChangeToken = token
        self.error = error
        super.init()
    }

    override func main() {
        fetchNotificationChangesCompletionBlock?(finalPreviousServerChangeToken, error)
    }
}

class TestMarkNotificationsReadOperation: TestCloudOperation, CKMarkNotificationsReadOperationType {

    var notificationIDs: [String]
    var error: NSError?

    var markNotificationsReadCompletionBlock: (([String]?, NSError?) -> Void)?

    init(markIDsToRead: [String] = [], error: NSError? = .None) {
        self.notificationIDs = markIDsToRead
        self.error = error
        super.init()
    }

    override func main() {
        markNotificationsReadCompletionBlock?(notificationIDs, error)
    }
}

class TestModifyBadgeOperation: TestCloudOperation, CKModifyBadgeOperationType {

    var badgeValue: Int
    var error: NSError?

    var modifyBadgeCompletionBlock: ((NSError?) -> Void)?

    init(value: Int = 0, error: NSError? = .None) {
        self.badgeValue = value
        self.error = error
    }

    override func main() {
        modifyBadgeCompletionBlock?(error)
    }
}

class TestFetchRecordChangesOperation: TestDatabaseOperation, CKFetchRecordChangesOperationType {

    typealias RecordZoneID = String
    typealias ServerChangeToken = String

    var token: String?
    var data: NSData?
    var error: NSError?

    var recordZoneID: RecordZoneID = "zone-id"
    var recordChangedBlock: ((Record) -> Void)? = .None
    var recordWithIDWasDeletedBlock: ((RecordID) -> Void)? = .None
    var fetchRecordChangesCompletionBlock: ((ServerChangeToken?, NSData?, NSError?) -> Void)? = .None

    init(token: String? = "new-token", data: NSData? = .None, error: NSError? = .None) {
        self.token = token
        self.data = data
        self.error = error
        super.init()
    }

    override func main() {
        fetchRecordChangesCompletionBlock?(token, data, error)
    }
}

class TestFetchRecordZonesOperation: TestDatabaseOperation, CKFetchRecordZonesOperationType {

    var zonesByID: [RecordZoneID: RecordZone]?
    var error: NSError?

    var recordZoneIDs: [RecordZoneID]?
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, NSError?) -> Void)?

    init(zonesByID: [RecordZoneID: RecordZone]? = .None, error: NSError? = .None) {
        self.zonesByID = zonesByID
        self.error = error
        super.init()
    }

    override func main() {
        fetchRecordZonesCompletionBlock?(zonesByID, error)
    }
}

class TestFetchRecordsOperation: TestDatabaseOperation, CKFetchRecordsOperationType {

    var recordsByID: [RecordID: Record]?
    var error: NSError?

    var recordIDs: [RecordID]?
    var perRecordProgressBlock: ((RecordID, Double) -> Void)?
    var perRecordCompletionBlock: ((Record?, RecordID?, NSError?) -> Void)?
    var fetchRecordsCompletionBlock: (([RecordID: Record]?, NSError?) -> Void)?

    init(recordsByID: [RecordID: Record]? = .None, error: NSError? = .None) {
        self.recordsByID = recordsByID
        self.error = error
        super.init()
    }

    override func main() {
        fetchRecordsCompletionBlock?(recordsByID, error)
    }
}

class TestFetchSubscriptionsOperation: TestDatabaseOperation, CKFetchSubscriptionsOperationType {

    var subscriptionsByID: [String: Subscription]?
    var error: NSError?

    var subscriptionIDs: [String]?
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, NSError?) -> Void)?

    init(subscriptionsByID: [String: Subscription]? = .None, error: NSError? = .None) {
        self.subscriptionsByID = subscriptionsByID
        self.error = error
        super.init()
    }

    override func main() {
        fetchSubscriptionCompletionBlock?(subscriptionsByID, error)
    }
}

class TestModifyRecordZonesOperation: TestDatabaseOperation, CKModifyRecordZonesOperationType {

    var saved: [RecordZone]?
    var deleted: [RecordZoneID]?
    var error: NSError?

    var recordZonesToSave: [RecordZone]?
    var recordZoneIDsToDelete: [RecordZoneID]?
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, NSError?) -> Void)?

    init(saved: [RecordZone]? = .None, deleted: [RecordZoneID]? = .None, error: NSError? = .None) {
        self.saved = saved
        self.deleted = deleted
        self.error = error
        super.init()
    }

    override func main() {
        modifyRecordZonesCompletionBlock?(saved, deleted, error)
    }
}

class TestModifyRecordsOperation: TestDatabaseOperation, CKModifyRecordsOperationType {

    var saved: [Record]?
    var deleted: [RecordID]?
    var error: NSError?

    var recordsToSave: [Record]?
    var recordIDsToDelete: [RecordID]?
    var savePolicy: RecordSavePolicy = 0
    var clientChangeTokenData: NSData?
    var atomic: Bool = true

    var perRecordProgressBlock: ((Record, Double) -> Void)?
    var perRecordCompletionBlock: ((Record?, NSError?) -> Void)?
    var modifyRecordsCompletionBlock: (([Record]?, [RecordID]?, NSError?) -> Void)?

    init(saved: [Record]? = .None, deleted: [RecordID]? = .None, error: NSError? = .None) {
        self.saved = saved
        self.deleted = deleted
        self.error = error
        super.init()
    }

    override func main() {
        modifyRecordsCompletionBlock?(saved, deleted, error)
    }
}

class TestModifySubscriptionsOperation: TestDatabaseOperation, CKModifySubscriptionsOperationType {

    var saved: [Subscription]?
    var deleted: [String]?
    var error: NSError?

    var subscriptionsToSave: [Subscription]?
    var subscriptionIDsToDelete: [String]?
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, NSError?) -> Void)?

    init(saved: [Subscription]? = .None, deleted: [String]? = .None, error: NSError? = .None) {
        self.saved = saved
        self.deleted = deleted
        self.error = error
        super.init()
    }

    override func main() {
        modifySubscriptionsCompletionBlock?(saved, deleted, error)
    }
}

class TestQueryOperation: TestDatabaseOperation, CKQueryOperationType {

    var error: NSError?

    var query: Query?
    var cursor: QueryCursor?
    var zoneID: RecordZoneID?
    var recordFetchedBlock: ((Record) -> Void)?
    var queryCompletionBlock: ((QueryCursor?, NSError?) -> Void)?

    init(error: NSError? = .None) {
        self.error = error
        super.init()
    }

    override func main() {
        queryCompletionBlock?(cursor, error)
    }
}











// MARK: - Test Cases

class CloudOperationTests: CloudKitOperationTests {

    var target: TestCloudOperation!
    var operation: CloudKitOperation<TestCloudOperation>!

    override func setUp() {
        super.setUp()
        target = TestCloudOperation()
        operation = CloudKitOperation(target)
    }

    func test__get_countainer() {
        let container = "I'm a test container!"
        target.container = container
        XCTAssertEqual(operation.container, container)
    }

    func test__set_database() {
        let container = "I'm a test container!"
        operation.container = container
        XCTAssertEqual(target.container, container)
    }
}

class DatabaseOperationTests: CloudKitOperationTests {

    var target: TestDatabaseOperation!
    var operation: CloudKitOperation<TestDatabaseOperation>!

    override func setUp() {
        super.setUp()
        target = TestDatabaseOperation()
        operation = CloudKitOperation(target)
    }

    func test__get_database() {
        let db = "I'm a test database!"
        target.database = db
        XCTAssertEqual(operation.database, db)
    }

    func test__set_database() {
        let db = "I'm a test database!"
        operation.database = db
        XCTAssertEqual(target.database, db)
    }

    func test__get_previous_server_change_token() {
        let token = "i'm a server token"
        target.previousServerChangeToken = token
        XCTAssertEqual(operation.previousServerChangeToken, token)
    }

    func test__set_previous_server_change_token() {
        let token = "i'm a server token"
        operation.previousServerChangeToken = token
        XCTAssertEqual(target.previousServerChangeToken, token)
    }

    func test__get_results_limit() {
        target.resultsLimit = 10
        XCTAssertEqual(operation.resultsLimit, 10)
    }

    func test__set_results_limits() {
        operation.resultsLimit = 10
        XCTAssertEqual(target.resultsLimit, 10)
    }

    func test__get_more_coming() {
        target.moreComing = true
        XCTAssertTrue(operation.moreComing)
    }

    func test__get_desired_keys() {
        let keys = [ "desired-key-1",  "desired-key-2" ]
        target.desiredKeys = keys
        XCTAssertNotNil(operation.desiredKeys)
        XCTAssertEqual(operation.desiredKeys!, keys)
    }

    func test__set_desired_keys() {
        let keys = [ "desired-key-1",  "desired-key-2" ]
        operation.desiredKeys = keys
        XCTAssertNotNil(target.desiredKeys)
        XCTAssertEqual(target.desiredKeys!, keys)
    }
}

class DiscoverAllContactsOperationTests: CloudKitOperationTests {

    var target: TestDiscoverAllContactsOperation!
    var operation: CloudKitOperation<TestDiscoverAllContactsOperation>!

    override func setUp() {
        super.setUp()
        target = TestDiscoverAllContactsOperation(result: [])
        operation = CloudKitOperation(target)
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__successful_execution_without_completion_block() {

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
    }

    func test__error_without_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__success_with_completion_block() {
        var result: [TestDiscoverAllContactsOperation.DiscoveredUserInfo]? = .None
        operation.setDiscoverAllContactsCompletionBlock { userInfos in
            result = userInfos
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isEmpty ?? false)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setDiscoverAllContactsCompletionBlock { userInfos in
            // etc
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class DiscoverUserInfosOperationTests: CloudKitOperationTests {

    var target: TestDiscoverUserInfosOperation!
    var operation: CloudKitOperation<TestDiscoverUserInfosOperation>!

    override func setUp() {
        super.setUp()
        target = TestDiscoverUserInfosOperation(userInfosByEmailAddress: [:], userInfoByRecordID: [:])
        operation = CloudKitOperation(target)
    }

    func test__get_email_addresses() {
        target.emailAddresses = [ "hello@world.com" ]
        XCTAssertNotNil(operation.emailAddresses)
        XCTAssertEqual(operation.emailAddresses!.count, 1)
        XCTAssertEqual(operation.emailAddresses!, [ "hello@world.com" ])
    }

    func test__set_email_addresses() {
        operation.emailAddresses = [ "hello@world.com" ]
        XCTAssertNotNil(target.emailAddresses)
        XCTAssertEqual(target.emailAddresses!.count, 1)
        XCTAssertEqual(target.emailAddresses!, [ "hello@world.com" ])
    }

    func test__get_user_record_ids() {
        target.userRecordIDs = [ "Hello World" ]
        XCTAssertNotNil(operation.userRecordIDs)
        XCTAssertEqual(operation.userRecordIDs!.count, 1)
        XCTAssertEqual(operation.userRecordIDs!, [ "Hello World" ])
    }

    func test__set_user_record_ids() {
        operation.userRecordIDs = [ "Hello World" ]
        XCTAssertNotNil(target.userRecordIDs)
        XCTAssertEqual(target.userRecordIDs!.count, 1)
        XCTAssertEqual(target.userRecordIDs!, [ "Hello World" ])
    }

    func test__success_with_completion_block() {
        var userInfosByAddress: [String: TestDiscoverUserInfosOperation.DiscoveredUserInfo]? = .None
        var userInfosByRecordID: [TestDiscoverUserInfosOperation.RecordID: TestDiscoverUserInfosOperation.DiscoveredUserInfo]? = .None

        operation.setDiscoverUserInfosCompletionBlock { byAddress, byRecordID in
            userInfosByAddress = byAddress
            userInfosByRecordID = byRecordID
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertNotNil(userInfosByAddress)
        XCTAssertTrue(userInfosByAddress?.isEmpty ?? false)
        XCTAssertNotNil(userInfosByRecordID)
        XCTAssertTrue(userInfosByRecordID?.isEmpty ?? false)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setDiscoverUserInfosCompletionBlock { _, _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class FetchNotificationChangesOperationTests: CloudKitOperationTests {

    var token: TestFetchNotificationChangesOperation.ServerChangeToken!
    var target: TestFetchNotificationChangesOperation!
    var operation: CloudKitOperation<TestFetchNotificationChangesOperation>!

    override func setUp() {
        super.setUp()
        token = "i'm a server token"
        target = TestFetchNotificationChangesOperation(token: token)
        operation = CloudKitOperation(target)
    }

    func test__get_set_notification_charged_block() {

        var didItWork = false
        operation.notificationChangedBlock = { _ in
            didItWork = true
        }

        let notification = "hello world"
        operation.notificationChangedBlock?(notification)
        XCTAssertTrue(didItWork)
    }

    func test__success_with_completion_block() {
        var receivedToken: String?
        operation.setFetchNotificationChangesCompletionBlock { token in
            receivedToken = token
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)

        XCTAssertNotNil(receivedToken)
        XCTAssertEqual(receivedToken, token)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchNotificationChangesCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class MarkNotificationsReadOperationTests: CloudKitOperationTests {

    var toMark: [TestMarkNotificationsReadOperation.NotificationID]!
    var target: TestMarkNotificationsReadOperation!
    var operation: CloudKitOperation<TestMarkNotificationsReadOperation>!

    override func setUp() {
        super.setUp()
        toMark = [ "this-is-an-id", "this-is-another-id" ]
        target = TestMarkNotificationsReadOperation(markIDsToRead: toMark)
        operation = CloudKitOperation(target)
    }

    func test__get_notification_id() {
        target.notificationIDs = toMark
        XCTAssertEqual(operation.notificationIDs, toMark)
    }

    func test__set_notification_id() {
        operation.notificationIDs = toMark
        XCTAssertEqual(operation.notificationIDs, toMark)
    }

    func test__success_with_completion_block() {
        var receivedNotificationIDs: [String]?
        operation.setMarkNotificationReadCompletionBlock { notificationID in
            receivedNotificationIDs = notificationID
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertEqual(receivedNotificationIDs!, toMark)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setMarkNotificationReadCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class ModifyBadgeOperationTests: CloudKitOperationTests {

    var badge: Int!
    var target: TestModifyBadgeOperation!
    var operation: CloudKitOperation<TestModifyBadgeOperation>!

    override func setUp() {
        super.setUp()
        badge = 9
        target = TestModifyBadgeOperation(value: badge)
        operation = CloudKitOperation(target)
    }

    func test__get_badge_value() {
        target.badgeValue = 4
        XCTAssertEqual(operation.badgeValue, 4)
    }
    
    func test__set_badge_value() {
        operation.badgeValue = 4
        XCTAssertEqual(target.badgeValue, 4)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setModifyBadgeCompletionBlock { notificationID in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setModifyBadgeCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class FetchRecordChangesOperationTests: CloudKitOperationTests {

    var target: TestFetchRecordChangesOperation!
    var operation: CloudKitOperation<TestFetchRecordChangesOperation>!

    override func setUp() {
        super.setUp()
        target = TestFetchRecordChangesOperation()
        operation = CloudKitOperation(target)
    }

    func test__get_record_zone_id() {
        let zoneID = "zone-id"
        target.recordZoneID = zoneID
        XCTAssertEqual(operation.recordZoneID, zoneID)
    }

    func test__set_record_zone_id() {
        let zoneID = "a-different-zone-id"
        operation.recordZoneID = zoneID
        XCTAssertEqual(target.recordZoneID, zoneID)
    }

    func test__get_record_changed_block() {
        target.recordChangedBlock = { _ in }
        XCTAssertNotNil(operation.recordChangedBlock)
    }
    
    func test__set_record_changed_block() {
        operation.recordChangedBlock = { _ in }
        XCTAssertNotNil(target.recordChangedBlock)
    }

    func test__get_record_with_id_was_deleted_block() {
        target.recordWithIDWasDeletedBlock = { _ in }
        XCTAssertNotNil(operation.recordWithIDWasDeletedBlock)
    }

    func test__set_record_with_id_was_deleted_block() {
        operation.recordWithIDWasDeletedBlock = { _ in }
        XCTAssertNotNil(target.recordWithIDWasDeletedBlock)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setFetchRecordChangesCompletionBlock { token, data in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchRecordChangesCompletionBlock { _, _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class FetchRecordZonesOperationTests: CloudKitOperationTests {

    var target: TestFetchRecordZonesOperation!
    var operation: CloudKitOperation<TestFetchRecordZonesOperation>!

    override func setUp() {
        super.setUp()
        target = TestFetchRecordZonesOperation()
        operation = CloudKitOperation(target)
    }

    func test__get_record_zone_ids() {
        let zoneIDs = [ "a-zone-id", "another-zone-id" ]
        target.recordZoneIDs = zoneIDs
        XCTAssertEqual(operation.recordZoneIDs!, zoneIDs)
    }

    func test__set_record_zone_ids() {
        let zoneIDs = [ "a-zone-id", "another-zone-id" ]
        operation.recordZoneIDs = zoneIDs
        XCTAssertEqual(target.recordZoneIDs!, zoneIDs)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setFetchRecordZonesCompletionBlock { zonesByID in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchRecordZonesCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class FetchRecordsOperationTests: CloudKitOperationTests {

    var target: TestFetchRecordsOperation!
    var operation: CloudKitOperation<TestFetchRecordsOperation>!

    override func setUp() {
        super.setUp()
        target = TestFetchRecordsOperation()
        operation = CloudKitOperation(target)
    }
    
    func test__get_record_ids() {
        let IDs = [ "an-id", "another-id" ]
        target.recordIDs = IDs
        XCTAssertEqual(operation.recordIDs!, IDs)
    }

    func test__set_record_zone_ids() {
        let IDs = [ "an-id", "another-id" ]
        operation.recordIDs = IDs
        XCTAssertEqual(target.recordIDs!, IDs)
    }

    func test__get_per_record_progress_block() {
        target.perRecordProgressBlock = { _, _ in }
        XCTAssertNotNil(operation.perRecordProgressBlock)
    }

    func test__set_per_record_progress_block() {
        operation.perRecordProgressBlock = { _, _ in }
        XCTAssertNotNil(target.perRecordProgressBlock)
    }

    func test__get_per_record_completion_block() {
        target.perRecordCompletionBlock = { _, _, _ in }
        XCTAssertNotNil(operation.perRecordCompletionBlock)
    }

    func test__set_per_record_completion_block() {
        operation.perRecordCompletionBlock = { _, _, _ in }
        XCTAssertNotNil(target.perRecordCompletionBlock)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setFetchRecordsCompletionBlock { subscriptionsByID in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchRecordsCompletionBlock { _ in
            // etc
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class FetchSubscriptionsOperationTests: CloudKitOperationTests {

    var target: TestFetchSubscriptionsOperation!
    var operation: CloudKitOperation<TestFetchSubscriptionsOperation>!

    override func setUp() {
        super.setUp()
        target = TestFetchSubscriptionsOperation()
        operation = CloudKitOperation(target)
    }

    func test__get_subscription_ids() {
        let IDs = [ "an-id", "another-id" ]
        target.subscriptionIDs = IDs
        XCTAssertEqual(operation.subscriptionIDs!, IDs)
    }

    func test__set_subscription_ids() {
        let IDs = [ "an-id", "another-id" ]
        operation.subscriptionIDs = IDs
        XCTAssertEqual(target.subscriptionIDs!, IDs)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setFetchSubscriptionCompletionBlock { subscriptionsByID in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchSubscriptionCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class ModifyRecordZonesOperationTests: CloudKitOperationTests {

    var target: TestModifyRecordZonesOperation!
    var operation: CloudKitOperation<TestModifyRecordZonesOperation>!

    override func setUp() {
        super.setUp()
        target = TestModifyRecordZonesOperation()
        operation = CloudKitOperation(target)
    }

    func test__get_zones_to_save() {
        let zones = [ "a-zone", "another-zone" ]
        target.recordZonesToSave = zones
        XCTAssertEqual(operation.recordZonesToSave!, zones)
    }

    func test__set_zones_to_save() {
        let zones = [ "a-zone", "another-zone" ]
        operation.recordZonesToSave = zones
        XCTAssertEqual(target.recordZonesToSave!, zones)
    }

    func test__get_zone_ids_to_delete() {
        let zoneIDs = [ "a-zone-id", "another-zone-id" ]
        target.recordZoneIDsToDelete = zoneIDs
        XCTAssertEqual(operation.recordZoneIDsToDelete!, zoneIDs)
    }

    func test__set_zone_ids_to_delete() {
        let zoneIDs = [ "a-zone-id", "another-zone-id" ]
        operation.recordZoneIDsToDelete = zoneIDs
        XCTAssertEqual(target.recordZoneIDsToDelete!, zoneIDs)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setModifyRecordZonesCompletionBlock { subscriptionsByID in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setModifyRecordZonesCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class ModifyRecordsOperationTests: CloudKitOperationTests {

    var target: TestModifyRecordsOperation!
    var operation: CloudKitOperation<TestModifyRecordsOperation>!

    override func setUp() {
        super.setUp()
        target = TestModifyRecordsOperation()
        operation = CloudKitOperation(target)
    }
    
    func test__get_records_to_save() {
        let records = [ "a-record", "another-record" ]
        target.recordsToSave = records
        XCTAssertEqual(operation.recordsToSave!, records)
    }

    func test__set_records_to_save() {
        let records = [ "a-record", "another-record" ]
        operation.recordsToSave = records
        XCTAssertEqual(target.recordsToSave!, records)
    }

    func test__get_record_ids_to_delete() {
        let recordIDs = [ "a-record-id", "another-record-id" ]
        target.recordIDsToDelete = recordIDs
        XCTAssertEqual(operation.recordIDsToDelete!, recordIDs)
    }

    func test__set_record_ids_to_delete() {
        let recordIDs = [ "a-record-id", "another-record-id" ]
        operation.recordIDsToDelete = recordIDs
        XCTAssertEqual(target.recordIDsToDelete!, recordIDs)
    }

    func test__get_save_policy() {
        target.savePolicy = 100
        XCTAssertEqual(operation.savePolicy, 100)
    }

    func test__set_save_policy() {
        operation.savePolicy = 100
        XCTAssertEqual(target.savePolicy, 100)
    }

    func test__get_client_change_token_data() {
        let data = "this-is-some-data".dataUsingEncoding(NSUTF8StringEncoding)
        target.clientChangeTokenData = data
        XCTAssertEqual(operation.clientChangeTokenData, data)
    }

    func test__set_client_change_token_data() {
        let data = "this-is-some-data".dataUsingEncoding(NSUTF8StringEncoding)
        operation.clientChangeTokenData = data
        XCTAssertEqual(target.clientChangeTokenData, data)
    }

    func test__get_atomic() {
        target.atomic = true
        XCTAssertTrue(operation.atomic)
    }

    func test__set_atomic() {
        operation.atomic = true
        XCTAssertTrue(target.atomic)
    }

    func test__get_per_record_progress_block() {
        target.perRecordProgressBlock = { _, _ in }
        XCTAssertNotNil(operation.perRecordProgressBlock)
    }

    func test__set_per_record_progress_block() {
        operation.perRecordProgressBlock = { _, _ in }
        XCTAssertNotNil(target.perRecordProgressBlock)
    }

    func test__get_per_record_completion_block() {
        target.perRecordCompletionBlock = { _, _ in }
        XCTAssertNotNil(operation.perRecordCompletionBlock)
    }

    func test__set_per_record_completion_block() {
        operation.perRecordCompletionBlock = { _, _ in }
        XCTAssertNotNil(target.perRecordCompletionBlock)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setModifyRecordsCompletionBlock { subscriptionsByID in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setModifyRecordsCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class ModifySubscriptionsOperationTests: CloudKitOperationTests {

    var target: TestModifySubscriptionsOperation!
    var operation: CloudKitOperation<TestModifySubscriptionsOperation>!

    override func setUp() {
        super.setUp()
        target = TestModifySubscriptionsOperation()
        operation = CloudKitOperation(target)
    }
    
    func test__get_subscriptions_to_save() {
        let subscriptions = [ "a-subscription", "another-subscription" ]
        target.subscriptionsToSave = subscriptions
        XCTAssertEqual(operation.subscriptionsToSave!, subscriptions)
    }

    func test__set_subscriptions_to_save() {
        let subscriptions = [ "a-subscription", "another-subscription" ]
        operation.subscriptionsToSave = subscriptions
        XCTAssertEqual(target.subscriptionsToSave!, subscriptions)
    }

    func test__get_subscription_ids_to_delete() {
        let subscriptionIDs = [ "a-subscription-id", "another-subscription-id" ]
        target.subscriptionIDsToDelete = subscriptionIDs
        XCTAssertEqual(operation.subscriptionIDsToDelete!, subscriptionIDs)
    }

    func test__set_subscription_ids_to_delete() {
        let subscriptionIDs = [ "a-subscription-id", "another-subscription-id" ]
        operation.subscriptionIDsToDelete = subscriptionIDs
        XCTAssertEqual(target.subscriptionIDsToDelete!, subscriptionIDs)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setModifySubscriptionsCompletionBlock { subscriptionsByID in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setModifySubscriptionsCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class QueryOperationTests: CloudKitOperationTests {

    var target: TestQueryOperation!
    var operation: CloudKitOperation<TestQueryOperation>!

    override func setUp() {
        super.setUp()
        target = TestQueryOperation()
        operation = CloudKitOperation(target)
    }
    
    func test__get_query() {
        let query = "a-query"
        target.query = query
        XCTAssertEqual(operation.query!, query)
    }

    func test__set_query() {
        let query = "a-query"
        operation.query = query
        XCTAssertEqual(target.query!, query)
    }

    func test__get_cursor() {
        let cursor = "a-cursor"
        target.cursor = cursor
        XCTAssertEqual(operation.cursor!, cursor)
    }

    func test__set_cursor() {
        let cursor = "a-cursor"
        operation.cursor = cursor
        XCTAssertEqual(target.cursor!, cursor)
    }

    func test__get_zone_id() {
        let zoneID = "a-zone-id"
        target.zoneID = zoneID
        XCTAssertEqual(operation.zoneID!, zoneID)
    }

    func test__set_zone_id() {
        let zoneID = "a-zone-id"
        operation.zoneID = zoneID
        XCTAssertEqual(target.zoneID!, zoneID)
    }

    func test__get_record_fetched_block() {
        target.recordFetchedBlock = { _ in }
        XCTAssertNotNil(operation.recordFetchedBlock)
    }

    func test__set_record_fetched_block() {
        operation.recordFetchedBlock = { _ in }
        XCTAssertNotNil(target.recordFetchedBlock)
    }

    func test__success_with_completion_block() {
        var blockDidRun = false
        operation.setQueryCompletionBlock { subscriptionsByID in
            blockDidRun = true
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setQueryCompletionBlock { _ in }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}



