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

    typealias RecordZoneID: Hashable
    typealias NotificationID: Hashable
    typealias RecordID: Hashable

    var container: Container? { get set }
}

public class CloudKitOperation<T where T: CKOperationType, T: NSOperation>: Operation {

    public private(set) var operation: T
    public let recoverFromError: (T, ErrorType) -> T?

    internal private(set) var configure: (T -> T)?

    public init(_ op: T, recovery: (T, ErrorType) -> T? = { _, _ in .None }) {
        operation = op
        recoverFromError = recovery
        super.init()
        name = "CloudKitOperation<\(operation.dynamicType)>"
    }

    public override func cancel() {
        operation.cancel()
        super.cancel()
    }

    public override func execute() {
        defer { go(operation) }
        guard let _ = configure else {
            let warning = "A completion block was not set for: \(operation.dynamicType), error handling will not be triggered."
            log.warning(warning)
            operation.addCompletionBlock {
                self.finish()
            }
            return
        }
    }

    private func go(op: T) -> T {
        let _op = configure?(op) ?? op
        produceOperation(_op)
        return _op
    }

    func receivedError(error: ErrorType) {
        guard let op = recoverFromError(operation, error) else {
            finish(error)
            return
        }

        operation = go(op)
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
}

extension CloudKitOperation where T: CKOperationType {

    public var container: T.Container? {
        get { return operation.container }
        set { operation.container = newValue }
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
        get { return operation.database }
        set { operation.database = newValue }
    }
}

// MARK: - Common Properties

public protocol CKPreviousServerChangeToken: CKOperationType {
    var previousServerChangeToken: ServerChangeToken? { get set }
}

extension CloudKitOperation where T: CKPreviousServerChangeToken {

    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set { operation.previousServerChangeToken = newValue }
    }
}

public protocol CKResultsLimit: CKOperationType {
    var resultsLimit: Int { get set }
}

extension CloudKitOperation where T: CKResultsLimit {

    public var resultsLimit: Int {
        get { return operation.resultsLimit }
        set { operation.resultsLimit = newValue }
    }
}

public protocol CKMoreComing: CKOperationType {
    var moreComing: Bool { get }
}

extension CloudKitOperation where T: CKMoreComing {

    public var moreComing: Bool {
        return operation.moreComing
    }
}

public protocol CKDesiredKeys: CKOperationType {
    var desiredKeys: [String]? { get set }
}

extension CloudKitOperation where T: CKDesiredKeys {

    public var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set { operation.desiredKeys = newValue }
    }
}

public typealias CKFetchOperationType = protocol<CKPreviousServerChangeToken, CKResultsLimit, CKMoreComing>



// MARK: - CKDiscoverAllContactsOperation

public protocol CKDiscoverAllContactsOperationType: CKOperationType {
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationType { }

extension CloudKitOperation where T: CKDiscoverAllContactsOperationType {

    public typealias DiscoverAllContactsCompletionBlock = [T.DiscoveredUserInfo]? -> Void

    public func setDiscoverAllContactsCompletionBlock(block: DiscoverAllContactsCompletionBlock?) {
        guard let block = block else {
            configure = .None
            operation.discoverAllContactsCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.discoverAllContactsCompletionBlock = { userInfo, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(userInfo)
                    self.finish()
                }
            }
            return op
        }
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

    public var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set { operation.emailAddresses = newValue }
    }

    public var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set { operation.userRecordIDs = newValue }
    }

    public func setDiscoverUserInfosCompletionBlock(block: DiscoverUserInfosCompletionBlock?) {
        guard let block = block else {
            configure = .None
            operation.discoverUserInfosCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.emailAddresses = self.operation.emailAddresses
            op.userRecordIDs = self.operation.userRecordIDs
            op.discoverUserInfosCompletionBlock = { userInfoByEmail, userInfoByRecordID, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(userInfoByEmail, userInfoByRecordID)
                    self.finish()
                }
            }

            return op
        }
    }
}

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
            configure = .None
            operation.fetchNotificationChangesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.previousServerChangeToken = self.operation.previousServerChangeToken
            op.resultsLimit = self.operation.resultsLimit
            op.notificationChangedBlock = self.operation.notificationChangedBlock
            op.fetchNotificationChangesCompletionBlock = { token, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(token)
                    self.finish()
                }
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
            configure = .None
            operation.markNotificationsReadCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.notificationIDs = self.operation.notificationIDs
            op.markNotificationsReadCompletionBlock = { notificationIDs, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(notificationIDs)
                    self.finish()
                }
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
            configure = .None
            operation.modifyBadgeCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.badgeValue = self.operation.badgeValue
            op.modifyBadgeCompletionBlock = { error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block()
                    self.finish()
                }
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
            configure = .None
            operation.fetchRecordChangesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordZoneID = self.operation.recordZoneID
            op.previousServerChangeToken = self.operation.previousServerChangeToken
            op.desiredKeys = self.operation.desiredKeys
            op.resultsLimit = self.operation.resultsLimit
            op.recordChangedBlock = self.operation.recordChangedBlock
            op.recordWithIDWasDeletedBlock = self.operation.recordWithIDWasDeletedBlock
            op.fetchRecordChangesCompletionBlock = { token, data, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(token, data)
                    self.finish()
                }
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
            configure = .None
            operation.fetchRecordZonesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordZoneIDs = self.operation.recordZoneIDs
            op.fetchRecordZonesCompletionBlock = { zonesByID, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(zonesByID)
                    self.finish()
                }
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
            configure = .None
            operation.fetchRecordsCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordIDs = self.operation.recordIDs
            op.perRecordProgressBlock = self.operation.perRecordProgressBlock
            op.perRecordCompletionBlock = self.operation.perRecordCompletionBlock
            op.fetchRecordsCompletionBlock = { recordsByID, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(recordsByID)
                    self.finish()
                }
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
            configure = .None
            operation.fetchSubscriptionCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.subscriptionIDs = self.operation.subscriptionIDs
            op.fetchSubscriptionCompletionBlock = { subscriptionsByID, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(subscriptionsByID)
                    self.finish()
                }
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
            configure = .None
            operation.modifyRecordZonesCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordZonesToSave = self.operation.recordZonesToSave
            op.recordZoneIDsToDelete = self.operation.recordZoneIDsToDelete
            op.modifyRecordZonesCompletionBlock = { saved, deleted, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(saved, deleted)
                    self.finish()
                }
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
            configure = .None
            operation.modifyRecordsCompletionBlock = .None
            return
        }

        let previousConfigure = configure
        configure = { [unowned self] _op in
            let op = previousConfigure?(_op) ?? _op
            op.recordsToSave = self.operation.recordsToSave
            op.recordIDsToDelete = self.operation.recordIDsToDelete
            op.savePolicy = self.operation.savePolicy
            op.clientChangeTokenData = self.operation.clientChangeTokenData
            op.atomic = self.operation.atomic
            op.perRecordProgressBlock = self.operation.perRecordProgressBlock
            op.perRecordCompletionBlock = self.operation.perRecordCompletionBlock
            op.modifyRecordsCompletionBlock = { saved, deleted, error in
                if let error = error {
                    self.receivedError(error)
                }
                else {
                    block(saved, deleted)
                    self.finish()
                }
            }
            return op
        }
    }
}

// MARK: - CKModifySubscriptionsOperation
// MARK: - CKQueryOperation



















