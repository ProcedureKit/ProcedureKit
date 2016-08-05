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

class TestDiscoverAllContactsOperation: TestCloudOperation, CKDiscoverAllContactsOperationType, AssociatedErrorType {
    typealias Error = DiscoverAllContactsError<DiscoveredUserInfo>

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

class TestDiscoverUserInfosOperation: TestCloudOperation, CKDiscoverUserInfosOperationType, AssociatedErrorType {
    typealias Error = CloudKitError

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

class TestFetchNotificationChangesOperation: TestCloudOperation, CKFetchNotificationChangesOperationType, AssociatedErrorType {

    typealias Error = FetchNotificationChangesError<ServerChangeToken>

    var error: NSError?
    var finalPreviousServerChangeToken: ServerChangeToken?
    var changedNotifications: [Notification]? = .None
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
        if let changes = changedNotifications, block = notificationChangedBlock {
            if changes.count > 0 {
                changes.forEach(block)
            }
        }
        fetchNotificationChangesCompletionBlock?(finalPreviousServerChangeToken, error)
    }
}

class TestMarkNotificationsReadOperation: TestCloudOperation, CKMarkNotificationsReadOperationType, AssociatedErrorType {

    typealias Error = MarkNotificationsReadError<String>

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

class TestModifyBadgeOperation: TestCloudOperation, CKModifyBadgeOperationType, AssociatedErrorType {

    typealias Error = CloudKitError

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

class TestFetchRecordChangesOperation: TestDatabaseOperation, CKFetchRecordChangesOperationType, AssociatedErrorType {
    typealias Error = FetchRecordChangesError<ServerChangeToken>

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

class TestFetchRecordZonesOperation: TestDatabaseOperation, CKFetchRecordZonesOperationType, AssociatedErrorType {
    typealias Error = FetchRecordZonesError<RecordZone, RecordZoneID>

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

class TestFetchRecordsOperation: TestDatabaseOperation, CKFetchRecordsOperationType, AssociatedErrorType {
    typealias Error = FetchRecordsError<Record, RecordID>

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

class TestFetchSubscriptionsOperation: TestDatabaseOperation, CKFetchSubscriptionsOperationType, AssociatedErrorType {

    typealias Error = FetchSubscriptionsError<Subscription>

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

class TestModifyRecordZonesOperation: TestDatabaseOperation, CKModifyRecordZonesOperationType, AssociatedErrorType {
    typealias Error = ModifyRecordZonesError<RecordZone, RecordZoneID>

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

class TestModifyRecordsOperation: TestDatabaseOperation, CKModifyRecordsOperationType, AssociatedErrorType {
    typealias Error = ModifyRecordsError<Record, RecordID>

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

class TestModifySubscriptionsOperation: TestDatabaseOperation, CKModifySubscriptionsOperationType, AssociatedErrorType {

    typealias Error = ModifySubscriptionsError<Subscription, String>

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

class TestQueryOperation: TestDatabaseOperation, CKQueryOperationType, AssociatedErrorType {
    typealias Error = QueryError<QueryCursor>

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



class CKTests: OperationTests {

    var network: TestableNetworkReachability!
    var manager: ReachabilityManager!

    override func setUp() {
        super.setUp()
        network = TestableNetworkReachability()
        manager = ReachabilityManager(network)
    }
}

// MARK: - OPRCKOperation Test Cases

class OPRCKOperationTests: CKTests {

    var target: TestCloudOperation!
    var operation: OPRCKOperation<TestCloudOperation>!

    var timeoutObserver: TimeoutObserver? {
        return operation.willExecuteObservers.flatMap({ $0 as? TimeoutObserver }).first
    }

    override func setUp() {
        super.setUp()
        target = TestCloudOperation()
        operation = OPRCKOperation(operation: target)
    }

    func test__get_container() {
        let container = "I'm a test container!"
        target.container = container
        XCTAssertEqual(operation.container, container)
    }

    func test__set_container() {
        let container = "I'm a test container!"
        operation.container = container
        XCTAssertEqual(target.container, container)
    }

    func test__set_get_container() {
        let container = "I'm a test container!"
        operation.container = container
        XCTAssertEqual(operation.container, container)
    }

    func test__timeout() {
        XCTAssertEqual(timeoutObserver?.timeout ?? 0, 300)

    }
    func test__no_timeout() {
        operation = OPRCKOperation(operation: target, timeout: .None)
        XCTAssertNil(timeoutObserver)
    }
}

class OPRCKDatabaseOperationTests: CKTests {

    var target: TestDatabaseOperation!
    var operation: OPRCKOperation<TestDatabaseOperation>!

    override func setUp() {
        super.setUp()
        target = TestDatabaseOperation()
        operation = OPRCKOperation(operation: target)
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

    func test__set_get_results_limits() {
        operation.resultsLimit = 10
        XCTAssertEqual(operation.resultsLimit, 10)
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

class OPRCKDiscoverAllContactsOperationTests: CKTests {

    var target: TestDiscoverAllContactsOperation!
    var operation: OPRCKOperation<TestDiscoverAllContactsOperation>!

    override func setUp() {
        super.setUp()
        target = TestDiscoverAllContactsOperation(result: [])
        operation = OPRCKOperation(operation: target)
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__successful_execution_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__error_without_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__success_with_completion_block() {
        var result: [TestDiscoverAllContactsOperation.DiscoveredUserInfo]? = .None
        operation.setDiscoverAllContactsCompletionBlock { userInfos in
            result = userInfos
        }

        waitForOperation(operation)
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

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKDiscoverUserInfosOperationTests: CKTests {

    var target: TestDiscoverUserInfosOperation!
    var operation: OPRCKOperation<TestDiscoverUserInfosOperation>!

    override func setUp() {
        super.setUp()
        target = TestDiscoverUserInfosOperation(userInfosByEmailAddress: [:], userInfoByRecordID: [:])
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)

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

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKFetchNotificationChangesOperationTests: CKTests {

    var target: TestFetchNotificationChangesOperation!
    var operation: OPRCKOperation<TestFetchNotificationChangesOperation>!
    var token: TestFetchNotificationChangesOperation.ServerChangeToken!

    override func setUp() {
        super.setUp()
        token = "i'm a server token"
        target = TestFetchNotificationChangesOperation(token: token)
        operation = OPRCKOperation(operation: target)
    }

    func test__get_set_notification_changed_block() {

        var didItWork = false
        operation.notificationChangedBlock = { _ in
            didItWork = true
        }

        let notification = "hello world"
        operation.notificationChangedBlock?(notification)
        XCTAssertTrue(didItWork)
    }

    func test__get_more_coming() {
        target.moreComing = true
        XCTAssertTrue(operation.moreComing)
    }

    func test__success_with_completion_block() {
        var receivedToken: String?
        operation.setFetchNotificationChangesCompletionBlock { token in
            receivedToken = token
        }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)

        XCTAssertNotNil(receivedToken)
        XCTAssertEqual(receivedToken, token)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchNotificationChangesCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKMarkNotificationsReadOperationTests: CKTests {

    var target: TestMarkNotificationsReadOperation!
    var operation: OPRCKOperation<TestMarkNotificationsReadOperation>!
    var toMark: [TestMarkNotificationsReadOperation.NotificationID]!

    override func setUp() {
        super.setUp()
        toMark = [ "this-is-an-id", "this-is-another-id" ]
        target = TestMarkNotificationsReadOperation(markIDsToRead: toMark)
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertEqual(receivedNotificationIDs ?? ["this is not the id you're looking for"], toMark)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setMarkNotificationReadCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKModifyBadgeOperationTests: CKTests {

    var target: TestModifyBadgeOperation!
    var operation: OPRCKOperation<TestModifyBadgeOperation>!
    var badge: Int!

    override func setUp() {
        super.setUp()
        badge = 9
        target = TestModifyBadgeOperation(value: badge)
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setModifyBadgeCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKFetchRecordChangesOperationTests: CKTests {

    var target: TestFetchRecordChangesOperation!
    var operation: OPRCKOperation<TestFetchRecordChangesOperation>!

    override func setUp() {
        super.setUp()
        target = TestFetchRecordChangesOperation()
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchRecordChangesCompletionBlock { _, _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKFetchRecordZonesOperationTests: CKTests {

    var target: TestFetchRecordZonesOperation!
    var operation: OPRCKOperation<TestFetchRecordZonesOperation>!

    override func setUp() {
        super.setUp()
        target = TestFetchRecordZonesOperation()
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchRecordZonesCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKFetchRecordsOperationTests: CKTests {

    var target: TestFetchRecordsOperation!
    var operation: OPRCKOperation<TestFetchRecordsOperation>!

    override func setUp() {
        super.setUp()
        target = TestFetchRecordsOperation()
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchRecordsCompletionBlock { _ in
            // etc
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKFetchSubscriptionsOperationTests: CKTests {

    var target: TestFetchSubscriptionsOperation!
    var operation: OPRCKOperation<TestFetchSubscriptionsOperation>!

    override func setUp() {
        super.setUp()
        target = TestFetchSubscriptionsOperation()
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setFetchSubscriptionCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKModifyRecordZonesOperationTests: CKTests {

    var target: TestModifyRecordZonesOperation!
    var operation: OPRCKOperation<TestModifyRecordZonesOperation>!

    override func setUp() {
        super.setUp()
        target = TestModifyRecordZonesOperation()
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setModifyRecordZonesCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKModifyRecordsOperationTests: CKTests {

    var target: TestModifyRecordsOperation!
    var operation: OPRCKOperation<TestModifyRecordsOperation>!

    override func setUp() {
        super.setUp()
        target = TestModifyRecordsOperation()
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setModifyRecordsCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKModifySubscriptionsOperationTests: CKTests {

    var target: TestModifySubscriptionsOperation!
    var operation: OPRCKOperation<TestModifySubscriptionsOperation>!

    override func setUp() {
        super.setUp()
        target = TestModifySubscriptionsOperation()
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setModifySubscriptionsCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class OPRCKQueryOperationTests: CKTests {

    var target: TestQueryOperation!
    var operation: OPRCKOperation<TestQueryOperation>!

    override func setUp() {
        super.setUp()
        target = TestQueryOperation()
        operation = OPRCKOperation(operation: target)
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

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertTrue(blockDidRun)
    }

    func test__error_with_completion_block() {
        target.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)

        operation.setQueryCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

// MARK: - CloudKitOperation Test Cases

// Note: This also tests the error-handling/retry code.
class CloudKitOperationDiscoverAllContractsTests: CKTests {

    var operation: CloudKitOperation<TestDiscoverAllContactsOperation>!

    override func setUp() {
        super.setUp()
        operation = CloudKitOperation(strategy: .Immediate) { TestDiscoverAllContactsOperation(result: []) }
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        var result: [TestDiscoverAllContactsOperation.DiscoveredUserInfo]? = .None
        operation.setDiscoverAllContactsCompletionBlock { userInfos in
            result = userInfos
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isEmpty ?? false)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverAllContactsOperation(result: [])
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {

        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverAllContactsOperation(result: [])
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setDiscoverAllContactsCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverAllContactsOperation(result: [])
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(double: 0.001)]
                op.error = NSError(
                    domain: CKErrorDomain,
                    code: CKErrorCode.ServiceUnavailable.rawValue,
                    userInfo: userInfo
                )
                shouldError = false
            }
            return op
        }
        operation.log.severity = .Verbose
        operation.setDiscoverAllContactsCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.failed)
    }

    func test__error_which_retries_without_retry_after_key() {
        var shouldError = true
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverAllContactsOperation(result: [])
            if shouldError {
                op.error = NSError(
                    domain: CKErrorDomain,
                    code: CKErrorCode.ZoneBusy.rawValue,
                    userInfo: nil
                )
                shouldError = false
            }
            return op
        }
        operation.setDiscoverAllContactsCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.failed)
    }

    func test__error_which_retries_with_custom_handler() {

        var shouldError = true
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverAllContactsOperation(result: [])
            if shouldError {
                op.error = NSError(
                    domain: CKErrorDomain,
                    code: CKErrorCode.LimitExceeded.rawValue,
                    userInfo: nil
                )
                shouldError = false
            }
            return op
        }

        var didRunCustomHandler = false
        operation.setErrorHandlerForCode(.LimitExceeded) { operation, error, log, suggested in
            didRunCustomHandler = true
            return suggested
        }

        operation.setDiscoverAllContactsCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertFalse(operation.failed)
        XCTAssertTrue(didRunCustomHandler)
    }

    func test__error_which_is_not_cloud_kit_error() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverAllContactsOperation(result: [])
            op.error = NSError(
                domain: CNErrorDomain,
                code: CNErrorCode.RecordDoesNotExist.rawValue,
                userInfo: nil
            )
            return op
        }

        operation.setDiscoverAllContactsCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }

    func test__get_error_handlers() {
        operation = CloudKitOperation { TestDiscoverAllContactsOperation(result: []) }
        operation.setErrorHandlerForCode(.InternalError) { $3 }
        let errorHandlers = operation.errorHandlers
        XCTAssertEqual(errorHandlers.count, 1)
        XCTAssertNotNil(errorHandlers[.InternalError])
    }

    func test__set_error_handlers() {
        operation = CloudKitOperation { TestDiscoverAllContactsOperation(result: []) }
        let handler: CloudKitOperation<TestDiscoverAllContactsOperation>.ErrorHandler = { $3 }
        operation.setErrorHandlers([.InternalError: handler])
        let errorHandlers = operation.errorHandlers
        XCTAssertEqual(errorHandlers.count, 1)
        XCTAssertNotNil(errorHandlers[.InternalError])
    }

    func test__set_prepare_for_retry_handler__with_error_which_retries_with_default_retry_handler() {
        var userInfosByAddress: [String: TestDiscoverUserInfosOperation.DiscoveredUserInfo]? = .None
        var userInfosByRecordID: [TestDiscoverUserInfosOperation.RecordID: TestDiscoverUserInfosOperation.DiscoveredUserInfo]? = .None

        var shouldError = true
        let operation: CloudKitOperation<TestDiscoverUserInfosOperation> = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverUserInfosOperation(userInfosByEmailAddress: [:], userInfoByRecordID: [:])
            if shouldError {
                op.error = NSError(
                    domain: CKErrorDomain,
                    code: CKErrorCode.ZoneBusy.rawValue,
                    userInfo: nil
                )
                shouldError = false
            }
            return op
        }
        operation.setDiscoverUserInfosCompletionBlock { _, _ in }
        operation.setFinallyConfigureRetryOperationBlock { retryOperation in
            // retry operation gets a new completion block that stores the result values
            retryOperation.setDiscoverUserInfosCompletionBlock { byAddress, byRecordID in
                userInfosByAddress = byAddress
                userInfosByRecordID = byRecordID
            }
        }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertNotNil(userInfosByAddress)
        XCTAssertTrue(userInfosByAddress?.isEmpty ?? false)
        XCTAssertNotNil(userInfosByRecordID)
        XCTAssertTrue(userInfosByRecordID?.isEmpty ?? false)
    }
}

class CloudKitOperationDiscoverUserInfosOperationTests: CKTests {

    var operation: CloudKitOperation<TestDiscoverUserInfosOperation>!

    override func setUp() {
        super.setUp()
        operation = CloudKitOperation(strategy: .Immediate) { TestDiscoverUserInfosOperation(userInfosByEmailAddress: [:], userInfoByRecordID: [:]) }
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__success_without_completion_block() {

        let emailAddresses = [ "hello@world.com" ]
        operation.emailAddresses = emailAddresses
        let userRecordIDs = [ "Hello World" ]
        operation.userRecordIDs = userRecordIDs

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)

        XCTAssertEqual(operation.emailAddresses ?? [], emailAddresses)
        XCTAssertEqual(operation.userRecordIDs ?? [], userRecordIDs)
    }

    func test__success_with_completion_block() {
        var userInfosByAddress: [String: TestDiscoverUserInfosOperation.DiscoveredUserInfo]? = .None
        var userInfosByRecordID: [TestDiscoverUserInfosOperation.RecordID: TestDiscoverUserInfosOperation.DiscoveredUserInfo]? = .None

        operation.setDiscoverUserInfosCompletionBlock { byAddress, byRecordID in
            userInfosByAddress = byAddress
            userInfosByRecordID = byRecordID
        }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertNotNil(userInfosByAddress)
        XCTAssertTrue(userInfosByAddress?.isEmpty ?? false)
        XCTAssertNotNil(userInfosByRecordID)
        XCTAssertTrue(userInfosByRecordID?.isEmpty ?? false)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverUserInfosOperation(userInfosByEmailAddress: [:], userInfoByRecordID: [:])
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestDiscoverUserInfosOperation(userInfosByEmailAddress: [:], userInfoByRecordID: [:])
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setDiscoverUserInfosCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationFetchNotificationChangesOperationTests: CKTests {

    var operation: CloudKitOperation<TestFetchNotificationChangesOperation>!

    override func setUp() {
        super.setUp()
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchNotificationChangesOperation(token: "i'm a server token")
            op.moreComing = true
            op.changedNotifications = [ "Hello", "World" ]
            return op
        }
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__success_without_completion_block() {

        var changedNotifications: [TestFetchNotificationChangesOperation.Notification] = []
        operation.notificationChangedBlock = { changedNotifications.append($0) }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertNotNil(operation.notificationChangedBlock)
        XCTAssertEqual(changedNotifications, [ "Hello", "World" ])
        XCTAssertTrue(operation.moreComing)
    }

    func test__success_with_completion_block() {

        operation.notificationChangedBlock = { _ in }
        operation.setFetchNotificationChangesCompletionBlock { _ in }

        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchNotificationChangesOperation(token: "i'm a server token")
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchNotificationChangesOperation(token: "i'm a server token")
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setFetchNotificationChangesCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationMarkNotificationsReadOperationTests: CKTests {

    var notificationIDs: [TestMarkNotificationsReadOperation.NotificationID]!
    var operation: CloudKitOperation<TestMarkNotificationsReadOperation>!

    override func setUp() {
        super.setUp()
        notificationIDs = [ "a-notification-id", "another-notification-id" ]
        operation = CloudKitOperation(strategy: .Immediate) { TestMarkNotificationsReadOperation() }
        operation.notificationIDs = notificationIDs
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.notificationIDs, notificationIDs)
    }

    func test__success_with_completion_block() {
        operation.setMarkNotificationReadCompletionBlock { _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestMarkNotificationsReadOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestMarkNotificationsReadOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setMarkNotificationReadCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationModifyBadgeCompletionTests: CKTests {

    var badgeValue: Int = 6
    var operation: CloudKitOperation<TestModifyBadgeOperation>!

    override func setUp() {
        super.setUp()
        operation = CloudKitOperation(strategy: .Immediate) { TestModifyBadgeOperation() }
        operation.badgeValue = badgeValue
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.badgeValue, badgeValue)
    }

    func test__success_with_completion_block() {
        operation.setModifyBadgeCompletionBlock { _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestModifyBadgeOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestModifyBadgeOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setModifyBadgeCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationFetchRecordChangesTests: CKTests {

    var container: TestFetchRecordChangesOperation.Container!
    var db: TestFetchRecordChangesOperation.Database!
    var token: TestFetchRecordChangesOperation.ServerChangeToken!
    var resultsLimit: Int = 0
    var keys: [String]!
    var zoneID: TestFetchRecordChangesOperation.RecordZoneID!
    var operation: CloudKitOperation<TestFetchRecordChangesOperation>!

    override func setUp() {
        super.setUp()
        container = "I'm a test container!"
        db = "I'm a test database!"
        token = "I'm a server token"
        resultsLimit = 10
        keys = [ "desired-key-1",  "desired-key-2" ]
        zoneID = "I'm a zone id"
        operation = CloudKitOperation(strategy: .Immediate) { TestFetchRecordChangesOperation() }
        operation.container = container
        operation.database = db
        operation.previousServerChangeToken = token
        operation.resultsLimit = resultsLimit
        operation.desiredKeys = keys
        operation.recordZoneID = zoneID
        operation.recordChangedBlock = { _ in }
        operation.recordWithIDWasDeletedBlock = { _ in }
    }

    func test__setting_common_properties() {

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)

        XCTAssertEqual(operation.container, container)
        XCTAssertEqual(operation.database, db)
        XCTAssertEqual(operation.previousServerChangeToken, token)
        XCTAssertEqual(operation.resultsLimit, resultsLimit)
        XCTAssertEqual(operation.desiredKeys!, keys)
        XCTAssertEqual(operation.recordZoneID, zoneID)
        XCTAssertNotNil(operation.recordChangedBlock)
        XCTAssertNotNil(operation.recordWithIDWasDeletedBlock)
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        operation.setFetchRecordChangesCompletionBlock { _, _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchRecordChangesOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchRecordChangesOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setFetchRecordChangesCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationFetchRecordZonesTests: CKTests {

    var zoneIDs: [TestFetchRecordZonesOperation.RecordZoneID]!
    var operation: CloudKitOperation<TestFetchRecordZonesOperation>!

    override func setUp() {
        super.setUp()
        zoneIDs = [ "a-record-zone", "another-record-zone" ]
        operation = CloudKitOperation(strategy: .Immediate) { TestFetchRecordZonesOperation() }
        operation.recordZoneIDs = zoneIDs
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.recordZoneIDs ?? [], zoneIDs)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        operation.setFetchRecordZonesCompletionBlock { _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchRecordZonesOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchRecordZonesOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setFetchRecordZonesCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationFetchRecordsTests: CKTests {

    var recordIDs: [TestFetchRecordsOperation.RecordID]!
    var operation: CloudKitOperation<TestFetchRecordsOperation>!

    override func setUp() {
        super.setUp()
        recordIDs = [ "a-record-id", "another-record-id" ]
        operation = CloudKitOperation(strategy: .Immediate) { TestFetchRecordsOperation() }
        operation.recordIDs = recordIDs
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.recordIDs ?? [], recordIDs)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        operation.perRecordProgressBlock = { _, _ in }
        operation.perRecordCompletionBlock = { _, _, _ in }
        operation.setFetchRecordsCompletionBlock { _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertNotNil(operation.perRecordProgressBlock)
        XCTAssertNotNil(operation.perRecordCompletionBlock)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchRecordsOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchRecordsOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setFetchRecordsCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationFetchSubscriptionsTests: CKTests {

    var subscriptionIDs: [String]!
    var operation: CloudKitOperation<TestFetchSubscriptionsOperation>!

    override func setUp() {
        super.setUp()
        subscriptionIDs = [ "a-subscription-id", "another-subscription-id" ]
        operation = CloudKitOperation(strategy: .Immediate) { TestFetchSubscriptionsOperation() }
        operation.subscriptionIDs = subscriptionIDs
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.subscriptionIDs ?? [], subscriptionIDs)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        operation.setFetchSubscriptionCompletionBlock { _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchSubscriptionsOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestFetchSubscriptionsOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setFetchSubscriptionCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationModifyRecordZonesTests: CKTests {

    var zonesToSave: [TestModifyRecordZonesOperation.RecordZone]!
    var zoneIDsToDelete: [TestModifyRecordZonesOperation.RecordZoneID]!
    var operation: CloudKitOperation<TestModifyRecordZonesOperation>!

    override func setUp() {
        super.setUp()
        zonesToSave = [ "a-record-zone", "another-record-zone" ]
        zoneIDsToDelete = [ "a-record-zone-id", "another-record-zone-id" ]
        operation = CloudKitOperation(strategy: .Immediate) { TestModifyRecordZonesOperation() }
        operation.recordZonesToSave = zonesToSave
        operation.recordZoneIDsToDelete = zoneIDsToDelete
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.recordZonesToSave ?? [], zonesToSave)
        XCTAssertEqual(operation.recordZoneIDsToDelete ?? [], zoneIDsToDelete)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        operation.setModifyRecordZonesCompletionBlock { _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestModifyRecordZonesOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestModifyRecordZonesOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setModifyRecordZonesCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationModifyRecordsTests: CKTests {

    var recordsToSave: [TestModifyRecordZonesOperation.Record]!
    var recordIDsToDelete: [TestModifyRecordZonesOperation.RecordID]!
    var policy: TestModifyRecordZonesOperation.RecordSavePolicy = 0
    var clientChangeToken: NSData!
    var atomic: Bool = false
    var operation: CloudKitOperation<TestModifyRecordsOperation>!

    override func setUp() {
        super.setUp()
        recordsToSave = [ "a-record", "another-record" ]
        recordIDsToDelete = [ "a-record-id", "another-record-id" ]
        policy = 1
        clientChangeToken = "I'm a client change token".dataUsingEncoding(NSUTF8StringEncoding)
        atomic = true

        operation = CloudKitOperation(strategy: .Immediate) { TestModifyRecordsOperation() }
        operation.recordsToSave = recordsToSave
        operation.recordIDsToDelete = recordIDsToDelete
        operation.savePolicy = policy
        operation.clientChangeTokenData = clientChangeToken
        operation.atomic = atomic
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.recordsToSave ?? [], recordsToSave)
        XCTAssertEqual(operation.recordIDsToDelete ?? [], recordIDsToDelete)
        XCTAssertEqual(operation.savePolicy, policy)
        XCTAssertEqual(operation.clientChangeTokenData, clientChangeToken)
        XCTAssertEqual(operation.atomic, atomic)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        operation.perRecordProgressBlock = { _, _ in }
        operation.perRecordCompletionBlock = { _, _ in }
        operation.setModifyRecordsCompletionBlock { _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertNotNil(operation.perRecordProgressBlock)
        XCTAssertNotNil(operation.perRecordCompletionBlock)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestModifyRecordsOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestModifyRecordsOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setModifyRecordsCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationModifySubscriptionsTests: CKTests {

    var subscriptionsToSave: [TestModifySubscriptionsOperation.Subscription]!
    var subscriptionIDsToDelete: [String]!
    var operation: CloudKitOperation<TestModifySubscriptionsOperation>!

    override func setUp() {
        super.setUp()
        subscriptionsToSave = [ "a-subscription", "another-subscription" ]
        subscriptionIDsToDelete = [ "a-subscription-id", "another-subscription-id" ]

        operation = CloudKitOperation(strategy: .Immediate) { TestModifySubscriptionsOperation() }
        operation.subscriptionsToSave = subscriptionsToSave
        operation.subscriptionIDsToDelete = subscriptionIDsToDelete
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.subscriptionsToSave ?? [], subscriptionsToSave)
        XCTAssertEqual(operation.subscriptionIDsToDelete ?? [], subscriptionIDsToDelete)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        operation.setModifySubscriptionsCompletionBlock { _, _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestModifySubscriptionsOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestModifySubscriptionsOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setModifySubscriptionsCompletionBlock { _, _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

class CloudKitOperationQueryTests: CKTests {

    var query: TestQueryOperation.Query!
    var cursor: TestQueryOperation.QueryCursor!
    var zoneID: TestQueryOperation.RecordZoneID!
    var operation: CloudKitOperation<TestQueryOperation>!

    override func setUp() {
        super.setUp()
        query = "I'm a query"
        cursor = "I'm a cursor"
        zoneID = "a-zone-id"
        operation = CloudKitOperation(strategy: .Immediate) { TestQueryOperation() }
        operation.query = query
        operation.cursor = cursor
        operation.zoneID = zoneID
    }

    func test__execution_after_cancellation() {
        operation.cancel()
        waitForOperation(operation)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.cancelled)
        XCTAssertEqual(operation.query ?? "I'm the wrong query", query)
        XCTAssertEqual(operation.cursor ?? "I'm the wrong cursor", cursor)
        XCTAssertEqual(operation.zoneID ?? "I'm the wrong zone id", zoneID)
    }

    func test__success_without_completion_block() {
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
    }

    func test__success_with_completion_block() {
        operation.recordFetchedBlock = { _ in }
        operation.setQueryCompletionBlock { _ in }
        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertNotNil(operation.recordFetchedBlock)
    }

    func test__error_without_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestQueryOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 0)
    }

    func test__error_with_completion_block() {
        operation = CloudKitOperation(strategy: .Immediate) {
            let op = TestQueryOperation()
            op.error = NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: nil)
            return op
        }
        operation.setQueryCompletionBlock { _ in }

        waitForOperation(operation)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
    }
}

// MARK: - BatchedCloudKitOperation Test Cases

class BatchedFetchNotificationChangesOperationTests: CKTests {

    typealias Target = TestFetchNotificationChangesOperation

    var token: String!
    var error: NSError?
    var numberOfBatches: Int = 3
    var count: Int = 0
    var operation: BatchedCloudKitOperation<Target>!

    override func setUp() {
        super.setUp()
        token = "I'm a server token!"
        error = .None
        numberOfBatches = 3
        count = 0
        operation = BatchedCloudKitOperation(createNextOperation)
    }

    func createNextOperation() -> Target? {
        let target = Target(token: token, error: error)
        target.changedNotifications = [ "hello", "world" ]
        if count < numberOfBatches - 1 {
            target.moreComing = true
        }
        return target
    }

    func test__get_set_notification_changed_block() {

        var didItWork = false
        operation.notificationChangedBlock = { _ in
            didItWork = true
        }

        let notification = "hello world"
        operation.notificationChangedBlock?(notification)
        XCTAssertTrue(didItWork)
    }

    func test__batch() {
        var notifications: [String] = []
        operation.notificationChangedBlock = { notification in
            notifications.append(notification)
        }

        operation.setFetchNotificationChangesCompletionBlock { [unowned self] _ in
            self.count += 1
        }

        waitForOperation(operation)

        XCTAssertEqual(operation.errors.count, 0)
        XCTAssertEqual(count, 3)
        XCTAssertEqual(notifications, [ "hello", "world", "hello", "world", "hello", "world" ])
    }
}

class BatchedFetchRecordChangesOperationTests: CKTests {

    typealias Target = TestFetchRecordChangesOperation

    var numberOfBatches: Int = 3
    var count: Int = 0
    var operation: BatchedCloudKitOperation<Target>!

    override func setUp() {
        super.setUp()
        numberOfBatches = 3
        count = 0
        operation = BatchedCloudKitOperation(createNextOperation)
    }

    func createNextOperation() -> Target {
        let target = Target()
        if count < numberOfBatches - 1 {
            target.moreComing = true
        }
        return target
    }

    func test__get_set_record_zone_id() {
        let zoneID = "a-different-zone-id"
        operation.recordZoneID = zoneID
        XCTAssertEqual(operation.recordZoneID, zoneID)
    }

    func test__get_set_record_changed_block() {
        operation.recordChangedBlock = { _ in }
        XCTAssertNotNil(operation.recordChangedBlock)
    }

    func test__get_set_record_with_id_was_deleted_block() {
        operation.recordWithIDWasDeletedBlock = { _ in }
        XCTAssertNotNil(operation.recordWithIDWasDeletedBlock)
    }

    func test__batch() {

        operation.recordZoneID = "a-zone-id"
        operation.recordChangedBlock = { _ in }
        operation.recordWithIDWasDeletedBlock = { _ in }
        operation.setFetchRecordChangesCompletionBlock { [unowned self] _, _ in
            self.count += 1
        }

        waitForOperation(operation)
        XCTAssertEqual(operation.errors.count, 0)

        XCTAssertEqual(count, 3)
    }

    func test__set_prepare_for_next_operation_handler() {

        var currentServerChangeToken: String? = "initial"

        operation.previousServerChangeToken = currentServerChangeToken
        operation.operation.token = "0" // set token to return on completion
        operation.recordZoneID = "a-zone-id"
        operation.recordChangedBlock = { _ in }
        operation.recordWithIDWasDeletedBlock = { _ in }
        operation.setFetchRecordChangesCompletionBlock { [unowned self] newServerChangeToken, _ in
            currentServerChangeToken = newServerChangeToken
            self.count += 1
        }

        operation.setConfigureNextOperationBlock { nextOperation in
            nextOperation.previousServerChangeToken = currentServerChangeToken
            // simulate the next server change token
            if let currentServerChangeToken = currentServerChangeToken {
                nextOperation.operation.token = "\(currentServerChangeToken).\(self.count)"
            }
            else {
                nextOperation.operation.token = "firstTokenAfterNil"
            }
        }

        waitForOperation(operation)
        XCTAssertEqual(operation.errors.count, 0)

        XCTAssertEqual(count, 3)
        XCTAssertEqual(currentServerChangeToken, "0.1.2")
    }
}

// MARK: - Cloud Kit Error Recovery Test Cases

class CloudKitRecoveryTests: CKTests {

    var operation: OPRCKOperation<TestDiscoverUserInfosOperation>!
    var recovery: CloudKitRecovery<TestDiscoverUserInfosOperation>!

    override func setUp() {
        super.setUp()
        let target = TestDiscoverUserInfosOperation(userInfosByEmailAddress: [:], userInfoByRecordID: [:])
        operation = OPRCKOperation(operation: target)
        recovery = CloudKitRecovery()
    }

    func createInfoWithErrors(errors: [ErrorType]) -> RetryFailureInfo<OPRCKOperation<TestDiscoverUserInfosOperation>> {
        return RetryFailureInfo(
            operation: operation,
            errors: errors,
            historicalErrors: [],
            count: 0,
            addOperations: { _ in },
            log: operation.log,
            configure: { _ in }
        )
    }

    func test__extract_cloud_kit_errors__with_single_cloud_kit_error() {
        let errors: [ErrorType] = [
            CloudKitError(error: NSError(domain: CKErrorDomain, code: CKErrorCode.NotAuthenticated.rawValue, userInfo: nil))
        ]
        let info = createInfoWithErrors(errors)
        guard let (code, _) = recovery.cloudKitErrorsFromInfo(info) else {
            XCTFail("Did not receive an error back."); return
        }

        XCTAssertEqual(code, CKErrorCode.NotAuthenticated)
    }

    func test__extract_cloud_kit_errors__with_mixture_cloud_kit_errors() {
        let errors: [ErrorType] = [
            // This is actually a Contacts error code
            NSError(domain: CNErrorDomain, code: CNErrorCode.RecordDoesNotExist.rawValue, userInfo: nil),
            CloudKitError(error: NSError(domain: CKErrorDomain, code: CKErrorCode.MissingEntitlement.rawValue, userInfo: nil)),
            CloudKitError(error: NSError(domain: CKErrorDomain, code: CKErrorCode.NotAuthenticated.rawValue, userInfo: nil))
        ]

        let info = createInfoWithErrors(errors)
        guard let (code, _) = recovery.cloudKitErrorsFromInfo(info) else {
            XCTFail("Did not receive an error back."); return
        }

        XCTAssertEqual(code, CKErrorCode.MissingEntitlement)
    }
}
