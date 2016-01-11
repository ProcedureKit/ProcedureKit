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

public protocol CKDatabaseOperationType: CKOperationType {
    typealias Database
    var database: Database? { get set }
}

public protocol CKPreviousServerChangeToken: CKOperationType {
    var previousServerChangeToken: ServerChangeToken? { get set }
}

public protocol CKResultsLimit: CKOperationType {
    var resultsLimit: Int { get set }
}

public protocol CKMoreComing: CKOperationType {
    var moreComing: Bool { get }
}

public protocol CKDesiredKeys: CKOperationType {
    var desiredKeys: [String]? { get set }
}

public typealias CKBatchedOperationType = protocol<CKResultsLimit, CKMoreComing>

public typealias CKFetchOperationType = protocol<CKPreviousServerChangeToken, CKBatchedOperationType>

public protocol CKDiscoverAllContactsOperationType: CKOperationType {
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

public protocol CKDiscoverUserInfosOperationType: CKOperationType {
    var emailAddresses: [String]? { get set }
    var userRecordIDs: [RecordID]? { get set }
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

public protocol CKFetchNotificationChangesOperationType: CKFetchOperationType {

    var notificationChangedBlock: ((Notification) -> Void)? { get set }
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, NSError?) -> Void)? { get set }
}

public protocol CKMarkNotificationsReadOperationType: CKOperationType {
    var notificationIDs: [NotificationID] { get set }
    var markNotificationsReadCompletionBlock: (([NotificationID]?, NSError?) -> Void)? { get set }
}

public protocol CKModifyBadgeOperationType: CKOperationType {
    var badgeValue: Int { get set }
    var modifyBadgeCompletionBlock: ((NSError?) -> Void)? { get set }
}

public protocol CKFetchRecordChangesOperationType: CKDatabaseOperationType, CKFetchOperationType, CKDesiredKeys {

    var recordZoneID: RecordZoneID { get set }
    var recordChangedBlock: ((Record) -> Void)? { get set }
    var recordWithIDWasDeletedBlock: ((RecordID) -> Void)? { get set }
    var fetchRecordChangesCompletionBlock: ((ServerChangeToken?, NSData?, NSError?) -> Void)? { get set }
}

public protocol CKFetchRecordZonesOperationType: CKDatabaseOperationType {
    var recordZoneIDs: [RecordZoneID]? { get set }
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, NSError?) -> Void)? { get set }
}

public protocol CKFetchRecordsOperationType: CKDatabaseOperationType, CKDesiredKeys {
    var recordIDs: [RecordID]? { get set }
    var perRecordProgressBlock: ((RecordID, Double) -> Void)? { get set }
    var perRecordCompletionBlock: ((Record?, RecordID?, NSError?) -> Void)? { get set }
    var fetchRecordsCompletionBlock: (([RecordID: Record]?, NSError?) -> Void)? { get set }
}

public protocol CKFetchSubscriptionsOperationType: CKDatabaseOperationType {
    var subscriptionIDs: [String]? { get set }
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, NSError?) -> Void)? { get set }
}

public protocol CKModifyRecordZonesOperationType: CKDatabaseOperationType {
    var recordZonesToSave: [RecordZone]? { get set }
    var recordZoneIDsToDelete: [RecordZoneID]? { get set }
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, NSError?) -> Void)? { get set }
}

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

public protocol CKModifySubscriptionsOperationType: CKDatabaseOperationType {
    var subscriptionsToSave: [Subscription]? { get set }
    var subscriptionIDsToDelete: [String]? { get set }
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, NSError?) -> Void)? { get set }
}

public protocol CKQueryOperationType: CKDatabaseOperationType, CKResultsLimit, CKDesiredKeys {

    var query: Query? { get set }
    var cursor: QueryCursor? { get set }
    var zoneID: RecordZoneID? { get set }
    var recordFetchedBlock: ((Record) -> Void)? { get set }
    var queryCompletionBlock: ((QueryCursor?, NSError?) -> Void)? { get set }
}

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

extension CKDatabaseOperation: CKDatabaseOperationType {
    public typealias Database = CKDatabase
}

extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationType { }

extension CKDiscoverUserInfosOperation: CKDiscoverUserInfosOperationType { }

extension CKFetchNotificationChangesOperation: CKFetchNotificationChangesOperationType { }

extension CKMarkNotificationsReadOperation: CKMarkNotificationsReadOperationType { }

extension CKModifyBadgeOperation: CKModifyBadgeOperationType { }

extension CKFetchRecordChangesOperation: CKFetchRecordChangesOperationType { }

extension CKFetchRecordZonesOperation: CKFetchRecordZonesOperationType { }

extension CKFetchRecordsOperation: CKFetchRecordsOperationType { }

extension CKFetchSubscriptionsOperation: CKFetchSubscriptionsOperationType { }

extension CKModifyRecordZonesOperation: CKModifyRecordZonesOperationType { }

extension CKModifyRecordsOperation: CKModifyRecordsOperationType { }

extension CKModifySubscriptionsOperation: CKModifySubscriptionsOperationType { }

extension CKQueryOperation: CKQueryOperationType { }

// MARK: - CloudKitOperation

public class CloudKitOperation<T where T: NSOperation, T: CKOperationType>: ReachableOperation<T> {

    internal var _batchProcessingEnabled: Bool = false

    public convenience init(connectivity: Reachability.Connectivity = .AnyConnectionKind, @autoclosure(escaping) _ creator: () -> T) {
        self.init(connectivity: connectivity, reachability: Reachability.sharedInstance, operation: creator)
    }

    override init(connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType, @autoclosure(escaping) operation creator: () -> T) {
        super.init(connectivity: connectivity, reachability: reachability, operation: creator)
        name = "CloudKit Operation<\(operation.dynamicType)>"
    }

    internal func updateCreator(block: T -> Void) {
        let _creator = creator
        creator = {
            let op = _creator()
            block(op)
            return op
        }
    }
}

// MARK: - CKOperationType

extension CloudKitOperation where T: CKOperationType {

    public var container: T.Container? {
        get { return operation.container }
        set { operation.container = newValue }
    }
}

// MARK: - CKDatabaseOperation

extension CloudKitOperation where T: CKDatabaseOperationType {

    public var database: T.Database? {
        get { return operation.database }
        set { operation.database = newValue }
    }
}

// MARK: - Common Properties

extension CloudKitOperation where T: CKPreviousServerChangeToken {

    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set { operation.previousServerChangeToken = newValue }
    }
}

extension CloudKitOperation where T: CKResultsLimit {

    public var resultsLimit: Int {
        get { return operation.resultsLimit }
        set { operation.resultsLimit = newValue }
    }
}

extension CloudKitOperation where T: CKMoreComing {

    public var moreComing: Bool {
        return operation.moreComing
    }
}

extension CloudKitOperation where T: CKDesiredKeys {

    public var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set { operation.desiredKeys = newValue }
    }
}

// MARK: - Greedy Batch Processing

extension CloudKitOperation where T: CKBatchedOperationType {

    public var enableBatchProcessing: Bool {
        get { return _batchProcessingEnabled }
        set { _batchProcessingEnabled = newValue }
    }

    internal func setupBatchProcessing() {
        if let target = target as? GroupOperation {
            let doBatchProcessing = self.performBatchProcessing
            target.addChildObserver { group, _, errors in
                if errors.isEmpty {
                    doBatchProcessing(group)
                }
            }
        }
    }

    internal func performBatchProcessing(group: GroupOperation) {
        guard enableBatchProcessing && moreComing else { return }
        let op = creator()
        operation = op
        group.addOperation(op)
    }
}

// MARK: - CKDiscoverAllContactsOperation

extension CloudKitOperation where T: CKDiscoverAllContactsOperationType {

    public typealias DiscoverAllContactsCompletionBlock = [T.DiscoveredUserInfo]? -> Void

    public func setDiscoverAllContactsCompletionBlock(block: DiscoverAllContactsCompletionBlock) {
        operation.discoverAllContactsCompletionBlock = { [unowned target] userInfo, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(userInfo)
            }
        }
    }
}

// MARK: - CKDiscoverUserInfosOperation

extension CloudKitOperation where T: CKDiscoverUserInfosOperationType {

    public typealias DiscoverUserInfosCompletionBlock = ([String: T.DiscoveredUserInfo]?, [T.RecordID: T.DiscoveredUserInfo]?) -> Void

    public var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set { operation.emailAddresses = newValue }
    }

    public var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set { operation.userRecordIDs = newValue }
    }

    public func setDiscoverUserInfosCompletionBlock(block: DiscoverUserInfosCompletionBlock) {
        operation.discoverUserInfosCompletionBlock = { [unowned target] userInfoByEmail, userInfoByRecordID, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(userInfoByEmail, userInfoByRecordID)
            }
        }
    }
}

// MARK: - CKFetchNotificationChangesOperation

extension CloudKitOperation where T: CKFetchNotificationChangesOperationType {

    public typealias FetchNotificationChangesChangedBlock = T.Notification -> Void
    public typealias FetchNotificationChangesCompletionBlock = T.ServerChangeToken? -> Void

    public var notificationChangedBlock: ((T.Notification) -> Void)? {
        get { return operation.notificationChangedBlock }
        set {
            operation.notificationChangedBlock = newValue
            updateCreator { $0.notificationChangedBlock = newValue }
        }
    }

    public func setFetchNotificationChangesCompletionBlock(block: FetchNotificationChangesCompletionBlock) {

        let completion: (T.ServerChangeToken?, NSError?) -> Void = { [unowned target] token, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(token)
            }
        }
        operation.fetchNotificationChangesCompletionBlock = completion
        updateCreator { $0.fetchNotificationChangesCompletionBlock = completion }
        setupBatchProcessing()
    }
}

// MARK: - CKMarkNotificationsReadOperation

extension CloudKitOperation where T: CKMarkNotificationsReadOperationType {

    public typealias MarkNotificationReadCompletionBlock = [T.NotificationID]? -> Void

    public var notificationIDs: [T.NotificationID] {
        get { return operation.notificationIDs }
        set { operation.notificationIDs = newValue }
    }

    public func setMarkNotificationReadCompletionBlock(block: MarkNotificationReadCompletionBlock) {
        operation.markNotificationsReadCompletionBlock = { [unowned target] notificationIDs, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(notificationIDs)
            }
        }
    }
}

// MARK: - CKModifyBadgeOperation

extension CloudKitOperation where T: CKModifyBadgeOperationType {

    public typealias ModifyBadgeCompletionBlock = () -> Void

    public var badgeValue: Int {
        get { return operation.badgeValue }
        set { operation.badgeValue = newValue }
    }

    public func setModifyBadgeCompletionBlock(block: ModifyBadgeCompletionBlock) {
        operation.modifyBadgeCompletionBlock = { [unowned target] error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block()
            }
        }
     }
}

// MARK: - CKFetchRecordChangesOperation

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

    public func setFetchRecordChangesCompletionBlock(block: FetchRecordChangesCompletionBlock) {
        let completion: (T.ServerChangeToken?, NSData?, NSError?) -> Void = { [unowned target] token, data, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(token, data)
            }
        }

        operation.fetchRecordChangesCompletionBlock = completion
        updateCreator { $0.fetchRecordChangesCompletionBlock = completion }
        setupBatchProcessing()
    }
}

// MARK: - CKFetchRecordZonesOperation

extension CloudKitOperation where T: CKFetchRecordZonesOperationType {

    public typealias FetchRecordZonesCompletionBlock = [T.RecordZoneID: T.RecordZone]? -> Void

    public var recordZoneIDs: [T.RecordZoneID]? {
        get { return operation.recordZoneIDs }
        set { operation.recordZoneIDs = newValue }
    }

    public func setFetchRecordZonesCompletionBlock(block: FetchRecordZonesCompletionBlock) {
        operation.fetchRecordZonesCompletionBlock = { [unowned target] zonesByID, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(zonesByID)
            }
        }
    }
}

// MARK: - CKFetchRecordsOperation

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

    public func setFetchRecordsCompletionBlock(block: FetchRecordsCompletionBlock) {
        operation.fetchRecordsCompletionBlock = { [unowned target] recordsByID, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(recordsByID)
            }
        }
    }
}

// MARK: - CKFetchSubscriptionsOperation

extension CloudKitOperation where T: CKFetchSubscriptionsOperationType {

    public typealias FetchSubscriptionCompletionBlock = [String: T.Subscription]? -> Void

    public var subscriptionIDs: [String]? {
        get { return operation.subscriptionIDs }
        set { operation.subscriptionIDs = newValue }
    }

    public func setFetchSubscriptionCompletionBlock(block: FetchSubscriptionCompletionBlock) {
        operation.fetchSubscriptionCompletionBlock = { [unowned target] subscriptionsByID, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(subscriptionsByID)
            }
        }
    }
}

// MARK: - CKModifyRecordZonesOperation

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

    public func setModifyRecordZonesCompletionBlock(block: ModifyRecordZonesCompletionBlock) {
        operation.modifyRecordZonesCompletionBlock = { [unowned target] saved, deleted, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

// MARK: - CKModifyRecordsOperation

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

    public func setModifyRecordsCompletionBlock(block: ModifyRecordsCompletionBlock) {
        operation.modifyRecordsCompletionBlock = { [unowned target] saved, deleted, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

// MARK: - CKModifySubscriptionsOperation

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

    public func setModifySubscriptionsCompletionBlock(block: ModifySubscriptionsCompletionBlock) {
        operation.modifySubscriptionsCompletionBlock = { [unowned target] saved, deleted, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

// MARK: - CKQueryOperation

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

    public func setQueryCompletionBlock(block: QueryCompletionBlock) {
        operation.queryCompletionBlock = { [unowned target] cursor, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(cursor)
            }
        }
    }
}






















