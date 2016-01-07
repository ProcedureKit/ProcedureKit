//
//  CloudKitOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CloudKit

public protocol CKOperationType: class {
    typealias Container
    typealias ServerChangeToken
    typealias Notification
    typealias RecordZone
    typealias Record
    typealias Subscription
    typealias RecordSavePolicy
    typealias DiscoveredUserInfo
    typealias Query
    typealias QueryCursor

    typealias RecordZoneID: Hashable
    typealias NotificationID: Hashable
    typealias RecordID: Hashable

    var container: Container? { get set }
}

public class CloudKitOperation<T where T: CKOperationType, T: NSOperation>: RetryOperation<ComposedOperation<T>> {
    public typealias Composed = ComposedOperation<T>
    typealias Config = (previous: Composed?, new: Composed) -> Composed

    private var configuration: Config

    public init<D, G where D: GeneratorType, D.Element == NSTimeInterval, G: GeneratorType, G.Element == Composed>(delay: D, maxCount max: Int?, shouldRetry: RetryFailureInfo<T> -> Bool, generator: G) {
        configuration = { _, new in return new }
        let composedRetry: RetryFailureInfo<Composed> -> Bool = { info in
            // TODO...
            return true
        }
        super.init(delay: delay, maxCount: max, shouldRetry: composedRetry, generator: generator)
        name = "Cloud Kit Operation <\(operation.dynamicType)>"
    }

    public convenience init<D where D: GeneratorType, D.Element == NSTimeInterval>(@autoclosure(escaping) _ operation: () -> T, delay: D, maxCount max: Int?, shouldRetry: RetryFailureInfo<T> -> Bool) {
        self.init(delay: delay, maxCount: max, shouldRetry: shouldRetry, generator: anyGenerator { ComposedOperation(operation: operation()) })
    }

    public convenience init(@autoclosure(escaping) _ operation: () -> T, strategy: WaitStrategy = .Fixed(0.1), maxCount max: Int? = 5, shouldRetry: RetryFailureInfo<T> -> Bool = { _ in true }) {
        self.init(operation, delay: strategy.generate(), maxCount: max, shouldRetry: shouldRetry)
    }

    public override func next() -> Composed? {
        return super.next().map(applyConfiguration)
    }

    internal func addConfigurationBlock(block: Config) {
        let configure = configuration
        configuration = { previous, new in
            block(previous: previous, new: configure(previous: previous, new: new))
        }
    }

    internal func applyConfiguration(op: Composed) -> Composed {
        return configuration(previous: operation, new: op)
    }
}

// MARK: - CKOperationType

extension CKOperation: CKOperationType {
    public typealias Container = CKContainer
    public typealias ServerChangeToken = CKServerChangeToken
    public typealias DiscoveredUserInfo = CKDiscoveredUserInfo
    public typealias RecordZone = CKRecordZone
    public typealias RecordZoneID = CKRecordZoneID
    public typealias Notification = CKNotification
    public typealias NotificationID = CKNotificationID
    public typealias Record = CKRecord
    public typealias RecordID = CKRecordID
    public typealias Subscription = CKSubscription
    public typealias RecordSavePolicy = CKRecordSavePolicy
    public typealias Query = CKQuery
    public typealias QueryCursor = CKQueryCursor
}

/*

extension CloudKitOperation where T: CKOperationType {

    public var container: T.Container? {
        get { return operation?.container }
        set { operation?.container = newValue }
    }
}

// MARK: - CKDatabaseOperation

public protocol CKDatabaseOperationType: CKOperationType {
    typealias Database
    var database: Database? { get set }
}

extension CKDatabaseOperation: CKDatabaseOperationType {
    public typealias Database = CKDatabase
}

extension CloudKitOperation where T: CKDatabaseOperationType {

    public var database: T.Database? {
        get { return operation?.database }
        set { operation?.database = newValue }
    }
}

// MARK: - Common Properties

public protocol CKPreviousServerChangeToken: CKOperationType {
    var previousServerChangeToken: ServerChangeToken? { get set }
}

extension CloudKitOperation where T: CKPreviousServerChangeToken {

    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation?.previousServerChangeToken }
        set { operation?.previousServerChangeToken = newValue }
    }
}

public protocol CKResultsLimit: CKOperationType {
    var resultsLimit: Int { get set }
}

extension CloudKitOperation where T: CKResultsLimit {

    public var resultsLimit: Int {
        get { return operation?.resultsLimit }
        set { operation?.resultsLimit = newValue }
    }
}

public protocol CKMoreComing: CKOperationType {
    var moreComing: Bool { get }
}

extension CloudKitOperation where T: CKMoreComing {

    public var moreComing: Bool {
        return operation?.moreComing
    }
}

public protocol CKDesiredKeys: CKOperationType {
    var desiredKeys: [String]? { get set }
}

extension CloudKitOperation where T: CKDesiredKeys {

    public var desiredKeys: [String]? {
        get { return operation?.desiredKeys }
        set { operation?.desiredKeys = newValue }
    }
}

public typealias CKFetchOperationType = protocol<CKPreviousServerChangeToken, CKResultsLimit, CKMoreComing>

*/

// MARK: - CKDiscoverAllContactsOperation

public protocol CKDiscoverAllContactsOperationType: CKOperationType {
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationType { }

extension CloudKitOperation where T: CKDiscoverAllContactsOperationType {

    public typealias DiscoverAllContactsCompletionBlock = [T.DiscoveredUserInfo]? -> Void

    public func setDiscoverAllContactsCompletionBlock(block: DiscoverAllContactsCompletionBlock) {
        addConfigurationBlock { previous, new in
            new.operation.discoverAllContactsCompletionBlock = { userInfo, error in
                if error == nil {
                    block(userInfo)
                }
            }
            return new
        }





/*
        guard let block = block else {
            config = .None
            operation.discoverAllContactsCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.discoverAllContactsCompletionBlock = { userInfo, error in
                if error == nil {
                    block(userInfo)
                }
                self.finish(error)
            }
            return op
        }
*/
    }
}

// MARK: - CKDiscoverUserInfosOperation

public protocol CKDiscoverUserInfosOperationType: CKOperationType {
    var emailAddresses: [String]? { get set }
    var userRecordIDs: [RecordID]? { get set }
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

extension CKDiscoverUserInfosOperation: CKDiscoverUserInfosOperationType { }

extension CloudKitOperation where T: CKDiscoverUserInfosOperationType {

    public typealias DiscoverUserInfosCompletionBlock = ([String: T.DiscoveredUserInfo]?, [T.RecordID: T.DiscoveredUserInfo]?) -> Void
/*
    public var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set { operation.emailAddresses = newValue }
    }

    public var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set { operation.userRecordIDs = newValue }
    }
*/
    public func setDiscoverUserInfosCompletionBlock(block: DiscoverUserInfosCompletionBlock?) {

/*
        guard let block = block else {
            config = .None
            operation.discoverUserInfosCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.emailAddresses = self.emailAddresses
            op.userRecordIDs = self.userRecordIDs
            op.discoverUserInfosCompletionBlock = { userInfoByEmail, userInfoByRecordID, error in
                if let _ = error {
                    block(userInfoByEmail, userInfoByRecordID)
                }
                self.finish(error)
            }

            return op
        }
*/
    }
}

/*


// MARK: - CKFetchNotificationChangesOperation

public protocol CKFetchNotificationChangesOperationType: CKFetchOperationType {

    var notificationChangedBlock: ((Notification) -> Void)? { get set }
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, NSError?) -> Void)? { get set }
}

extension CKFetchNotificationChangesOperation: CKFetchNotificationChangesOperationType { }

extension CloudKitOperation where T: CKFetchNotificationChangesOperationType {

    public typealias FetchNotificationChangesChangedBlock = T.Notification -> Void
    public typealias FetchNotificationChangesCompletionBlock = T.ServerChangeToken? -> Void

    public var notificationChangedBlock: ((T.Notification) -> Void)? {
        get { return operation.notificationChangedBlock }
        set { operation.notificationChangedBlock = newValue }
    }

    public func setFetchNotificationChangesCompletionBlock(block: FetchNotificationChangesCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.fetchNotificationChangesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.previousServerChangeToken = self.previousServerChangeToken
            op.resultsLimit = self.resultsLimit
            op.notificationChangedBlock = self.notificationChangedBlock
            op.fetchNotificationChangesCompletionBlock = { token, error in
                if let _ = error {
                    block(token)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKMarkNotificationsReadOperation

public protocol CKMarkNotificationsReadOperationType: CKOperationType {
    var notificationIDs: [NotificationID] { get set }
    var markNotificationsReadCompletionBlock: (([NotificationID]?, NSError?) -> Void)? { get set }
}

extension CKMarkNotificationsReadOperation: CKMarkNotificationsReadOperationType { }

extension CloudKitOperation where T: CKMarkNotificationsReadOperationType {

    public typealias MarkNotificationReadCompletionBlock = [T.NotificationID]? -> Void

    public var notificationIDs: [T.NotificationID] {
        get { return operation.notificationIDs }
        set { operation.notificationIDs = newValue }
    }

    public func setMarkNotificationReadCompletionBlock(block: MarkNotificationReadCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.markNotificationsReadCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.notificationIDs = self.notificationIDs
            op.markNotificationsReadCompletionBlock = { notificationIDs, error in
                if let _ = error {
                    block(notificationIDs)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKModifyBadgeOperation

public protocol CKModifyBadgeOperationType: CKOperationType {
    var badgeValue: Int { get set }
    var modifyBadgeCompletionBlock: ((NSError?) -> Void)? { get set }
}

extension CKModifyBadgeOperation: CKModifyBadgeOperationType { }

extension CloudKitOperation where T: CKModifyBadgeOperationType {

    public typealias ModifyBadgeCompletionBlock = () -> Void

    public var badgeValue: Int {
        get { return operation.badgeValue }
        set { operation.badgeValue = newValue }
    }

    public func setModifyBadgeCompletionBlock(block: ModifyBadgeCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.modifyBadgeCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.badgeValue = self.badgeValue
            op.modifyBadgeCompletionBlock = { error in
                if let _ = error {
                    block()
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKFetchRecordChangesOperation

public protocol CKFetchRecordChangesOperationType: CKDatabaseOperationType, CKFetchOperationType, CKDesiredKeys {

    var recordZoneID: RecordZoneID { get set }
    var recordChangedBlock: ((Record) -> Void)? { get set }
    var recordWithIDWasDeletedBlock: ((RecordID) -> Void)? { get set }
    var fetchRecordChangesCompletionBlock: ((ServerChangeToken?, NSData?, NSError?) -> Void)? { get set }
}

extension CKFetchRecordChangesOperation: CKFetchRecordChangesOperationType { }

extension CloudKitOperation where T: CKFetchRecordChangesOperationType {

    public typealias FetchRecordChangesCompletionBlock = (T.ServerChangeToken?, NSData?) -> Void

    public var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set { operation.recordZoneID = newValue }
    }

    public var recordChangedBlock: ((T.Record) -> Void)? {
        get { return operation.recordChangedBlock }
        set { operation.recordChangedBlock = newValue }
    }

    public var recordWithIDWasDeletedBlock: ((T.RecordID) -> Void)? {
        get { return operation.recordWithIDWasDeletedBlock }
        set { operation.recordWithIDWasDeletedBlock = newValue }
    }

    public func setFetchRecordChangesCompletionBlock(block: FetchRecordChangesCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.fetchRecordChangesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordZoneID = self.recordZoneID
            op.previousServerChangeToken = self.previousServerChangeToken
            op.desiredKeys = self.desiredKeys
            op.resultsLimit = self.resultsLimit
            op.recordChangedBlock = self.recordChangedBlock
            op.recordWithIDWasDeletedBlock = self.recordWithIDWasDeletedBlock
            op.fetchRecordChangesCompletionBlock = { token, data, error in
                if let _ = error {
                    block(token, data)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKFetchRecordZonesOperation

public protocol CKFetchRecordZonesOperationType: CKDatabaseOperationType {
    var recordZoneIDs: [RecordZoneID]? { get set }
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, NSError?) -> Void)? { get set }
}

extension CKFetchRecordZonesOperation: CKFetchRecordZonesOperationType { }

extension CloudKitOperation where T: CKFetchRecordZonesOperationType {

    public typealias FetchRecordZonesCompletionBlock = [T.RecordZoneID: T.RecordZone]? -> Void

    public var recordZoneIDs: [T.RecordZoneID]? {
        get { return operation.recordZoneIDs }
        set { operation.recordZoneIDs = newValue }
    }

    public func setFetchRecordZonesCompletionBlock(block: FetchRecordZonesCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.fetchRecordZonesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordZoneIDs = self.recordZoneIDs
            op.fetchRecordZonesCompletionBlock = { zonesByID, error in
                if let _ = error {
                    block(zonesByID)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKFetchRecordsOperation

public protocol CKFetchRecordsOperationType: CKDatabaseOperationType, CKDesiredKeys {
    var recordIDs: [RecordID]? { get set }
    var perRecordProgressBlock: ((RecordID, Double) -> Void)? { get set }
    var perRecordCompletionBlock: ((Record?, RecordID?, NSError?) -> Void)? { get set }
    var fetchRecordsCompletionBlock: (([RecordID: Record]?, NSError?) -> Void)? { get set }
}

extension CKFetchRecordsOperation: CKFetchRecordsOperationType { }

extension CloudKitOperation where T: CKFetchRecordsOperationType {

    public typealias FetchRecordsCompletionBlock = [T.RecordID: T.Record]? -> Void

    public var recordIDs: [T.RecordID]? {
        get { return operation.recordIDs }
        set { operation.recordIDs = newValue }
    }

    public var perRecordProgressBlock: ((T.RecordID, Double) -> Void)? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    public var perRecordCompletionBlock: ((T.Record?, T.RecordID?, NSError?) -> Void)? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    public func setFetchRecordsCompletionBlock(block: FetchRecordsCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.fetchRecordsCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordIDs = self.recordIDs
            op.desiredKeys = self.desiredKeys
            op.perRecordProgressBlock = self.perRecordProgressBlock
            op.perRecordCompletionBlock = self.perRecordCompletionBlock
            op.fetchRecordsCompletionBlock = { recordsByID, error in
                if let _ = error {
                    block(recordsByID)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKFetchSubscriptionsOperation

public protocol CKFetchSubscriptionsOperationType: CKDatabaseOperationType {
    var subscriptionIDs: [String]? { get set }
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, NSError?) -> Void)? { get set }
}

extension CKFetchSubscriptionsOperation: CKFetchSubscriptionsOperationType { }

extension CloudKitOperation where T: CKFetchSubscriptionsOperationType {

    public typealias FetchSubscriptionCompletionBlock = [String: T.Subscription]? -> Void

    public var subscriptionIDs: [String]? {
        get { return operation.subscriptionIDs }
        set { operation.subscriptionIDs = newValue }
    }

    public func setFetchSubscriptionCompletionBlock(block: FetchSubscriptionCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.fetchSubscriptionCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.subscriptionIDs = self.subscriptionIDs
            op.fetchSubscriptionCompletionBlock = { subscriptionsByID, error in
                if let _ = error {
                    block(subscriptionsByID)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKModifyRecordZonesOperation

public protocol CKModifyRecordZonesOperationType: CKDatabaseOperationType {
    var recordZonesToSave: [RecordZone]? { get set }
    var recordZoneIDsToDelete: [RecordZoneID]? { get set }
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, NSError?) -> Void)? { get set }
}

extension CKModifyRecordZonesOperation: CKModifyRecordZonesOperationType { }

extension CloudKitOperation where T: CKModifyRecordZonesOperationType {

    public typealias ModifyRecordZonesCompletionBlock = ([T.RecordZone]?, [T.RecordZoneID]?) -> Void

    public var recordZonesToSave: [T.RecordZone]? {
        get { return operation.recordZonesToSave }
        set { operation.recordZonesToSave = newValue }
    }

    public var recordZoneIDsToDelete: [T.RecordZoneID]? {
        get { return operation.recordZoneIDsToDelete }
        set { operation.recordZoneIDsToDelete = newValue }
    }

    public func setModifyRecordZonesCompletionBlock(block: ModifyRecordZonesCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.modifyRecordZonesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordZonesToSave = self.recordZonesToSave
            op.recordZoneIDsToDelete = self.recordZoneIDsToDelete
            op.modifyRecordZonesCompletionBlock = { saved, deleted, error in
                if let _ = error {
                    block(saved, deleted)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKModifyRecordsOperation

public protocol CKModifyRecordsOperationType: CKDatabaseOperationType {
    var recordsToSave: [Record]? { get set }
    var recordIDsToDelete: [RecordID]? { get set }
    var savePolicy: RecordSavePolicy { get set }
    var clientChangeTokenData: NSData? { get set }
    var atomic: Bool { get set }

    var perRecordProgressBlock: ((Record, Double) -> Void)? { get set }
    var perRecordCompletionBlock: ((Record?, NSError?) -> Void)? { get set }
    var modifyRecordsCompletionBlock: (([Record]?, [RecordID]?, NSError?) -> Void)? { get set }
}

extension CKModifyRecordsOperation: CKModifyRecordsOperationType { }

extension CloudKitOperation where T: CKModifyRecordsOperationType {

    public typealias ModifyRecordsCompletionBlock = ([T.Record]?, [T.RecordID]?) -> Void

    public var recordsToSave: [T.Record]? {
        get { return operation.recordsToSave }
        set { operation.recordsToSave = newValue }
    }

    public var recordIDsToDelete: [T.RecordID]? {
        get { return operation.recordIDsToDelete }
        set { operation.recordIDsToDelete = newValue }
    }

    public var savePolicy: T.RecordSavePolicy {
        get { return operation.savePolicy }
        set { operation.savePolicy = newValue }
    }

    public var clientChangeTokenData: NSData? {
        get { return operation.clientChangeTokenData }
        set { operation.clientChangeTokenData = newValue }
    }

    public var atomic: Bool {
        get { return operation.atomic }
        set { operation.atomic = newValue }
    }

    public var perRecordProgressBlock: ((T.Record, Double) -> Void)? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    public var perRecordCompletionBlock: ((T.Record?, NSError?) -> Void)? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    public func setModifyRecordsCompletionBlock(block: ModifyRecordsCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.modifyRecordsCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordsToSave = self.recordsToSave
            op.recordIDsToDelete = self.recordIDsToDelete
            op.savePolicy = self.savePolicy
            op.clientChangeTokenData = self.clientChangeTokenData
            op.atomic = self.atomic
            op.perRecordProgressBlock = self.perRecordProgressBlock
            op.perRecordCompletionBlock = self.perRecordCompletionBlock
            op.modifyRecordsCompletionBlock = { saved, deleted, error in
                if let _ = error {
                    block(saved, deleted)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKModifySubscriptionsOperation

public protocol CKModifySubscriptionsOperationType: CKDatabaseOperationType {
    var subscriptionsToSave: [Subscription]? { get set }
    var subscriptionIDsToDelete: [String]? { get set }
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, NSError?) -> Void)? { get set }
}

extension CKModifySubscriptionsOperation: CKModifySubscriptionsOperationType { }

extension CloudKitOperation where T: CKModifySubscriptionsOperationType {

    public typealias ModifySubscriptionsCompletionBlock = ([T.Subscription]?, [String]?) -> Void

    public var subscriptionsToSave: [T.Subscription]? {
        get { return operation.subscriptionsToSave }
        set { operation.subscriptionsToSave = newValue }
    }

    public var subscriptionIDsToDelete: [String]? {
        get { return operation.subscriptionIDsToDelete }
        set { operation.subscriptionIDsToDelete = newValue }
    }

    public func setModifySubscriptionsCompletionBlock(block: ModifySubscriptionsCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.modifySubscriptionsCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.subscriptionsToSave = self.subscriptionsToSave
            op.subscriptionIDsToDelete = self.subscriptionIDsToDelete
            op.modifySubscriptionsCompletionBlock = { saved, deleted, error in
                if let _ = error {
                    block(saved, deleted)
                }
                self.finish(error)
            }
            return op
        }
    }
}

// MARK: - CKQueryOperation

public protocol CKQueryOperationType: CKDatabaseOperationType, CKResultsLimit, CKDesiredKeys {

    var query: Query? { get set }
    var cursor: QueryCursor? { get set }
    var zoneID: RecordZoneID? { get set }
    var recordFetchedBlock: ((Record) -> Void)? { get set }
    var queryCompletionBlock: ((QueryCursor?, NSError?) -> Void)? { get set }
}

extension CKQueryOperation: CKQueryOperationType { }

extension CloudKitOperation where T: CKQueryOperationType {

    public typealias QueryCompletionBlock = T.QueryCursor? -> Void

    public var query: T.Query? {
        get { return operation.query }
        set { operation.query = newValue }
    }

    public var cursor: T.QueryCursor? {
        get { return operation.cursor }
        set { operation.cursor = newValue }
    }

    public var zoneID: T.RecordZoneID? {
        get { return operation.zoneID }
        set { operation.zoneID = newValue }
    }

    public var recordFetchedBlock: ((T.Record) -> Void)? {
        get { return operation.recordFetchedBlock }
        set { operation.recordFetchedBlock = newValue }
    }

    public func setQueryCompletionBlock(block: QueryCompletionBlock?) {
        guard let block = block else {
            config = .None
            operation.queryCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        config = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.query = self.query
            op.cursor = self.cursor
            op.zoneID = self.zoneID
            op.desiredKeys = self.desiredKeys
            op.resultsLimit = self.resultsLimit
            op.recordFetchedBlock = self.recordFetchedBlock
            op.queryCompletionBlock = { cursor, error in
                if let _ = error {
                    block(cursor)
                }
                self.finish(error)
            }
            return op
        }
    }
}



*/















