//
//  CloudKitOperationExtensions.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/03/2016.
//
//

import Foundation
import CloudKit

// swiftlint:disable file_length

// MARK: - CKOperationType

extension OPRCKOperation where T: CKOperationType {

    var container: T.Container? {
        get { return operation.container }
        set { operation.container = newValue }
    }
}

extension CloudKitOperation where T: CKOperationType {

    /// - returns: the CloudKit container
    public var container: T.Container? {
        get { return operation.container }
        set {
            operation.container = newValue
            addConfigureBlock { $0.container = newValue }
        }
    }
}

extension BatchedCloudKitOperation where T: CKOperationType {

    /// - returns: the CloudKit container
    public var container: T.Container? {
        get { return operation.container }
        set {
            operation.container = newValue
            addConfigureBlock { $0.container = newValue }
        }
    }
}

// MARK: - CKDatabaseOperation

extension OPRCKOperation where T: CKDatabaseOperationType {

    public var database: T.Database? {
        get { return operation.database }
        set { operation.database = newValue }
    }
}

extension CloudKitOperation where T: CKDatabaseOperationType {

    /// - returns: the CloudKit database
    public var database: T.Database? {
        get { return operation.database }
        set {
            operation.database = newValue
            addConfigureBlock { $0.database = newValue }
        }
    }
}

extension BatchedCloudKitOperation where T: CKDatabaseOperationType {

    /// - returns: the CloudKit database
    public var database: T.Database? {
        get { return operation.database }
        set {
            operation.database = newValue
            addConfigureBlock { $0.database = newValue }
        }
    }
}

// MARK: - CKPreviousServerChangeToken

extension OPRCKOperation where T: CKPreviousServerChangeToken {

    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set { operation.previousServerChangeToken = newValue }
    }
}

extension CloudKitOperation where T: CKPreviousServerChangeToken {

    /// - returns: the previous server change token
    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set {
            operation.previousServerChangeToken = newValue
            addConfigureBlock { $0.previousServerChangeToken = newValue }
        }
    }
}

extension BatchedCloudKitOperation where T: CKPreviousServerChangeToken {

    /// - returns: the previous server change token
    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set {
            operation.previousServerChangeToken = newValue
            addConfigureBlock { $0.previousServerChangeToken = newValue }
        }
    }
}

// MARK: - CKResultsLimit

extension OPRCKOperation where T: CKResultsLimit {

    public var resultsLimit: Int {
        get { return operation.resultsLimit }
        set { operation.resultsLimit = newValue }
    }
}

extension CloudKitOperation where T: CKResultsLimit {

    /// - returns: the results limit
    public var resultsLimit: Int {
        get { return operation.resultsLimit }
        set {
            operation.resultsLimit = newValue
            addConfigureBlock { $0.resultsLimit = newValue }
        }
    }
}

extension BatchedCloudKitOperation where T: CKResultsLimit {

    /// - returns: the results limit
    public var resultsLimit: Int {
        get { return operation.resultsLimit }
        set {
            operation.resultsLimit = newValue
            addConfigureBlock { $0.resultsLimit = newValue }
        }
    }
}

// MARK: - CKMoreComing

extension OPRCKOperation where T: CKMoreComing {

    public var moreComing: Bool {
        return operation.moreComing
    }
}

extension CloudKitOperation where T: CKMoreComing {

    /// - returns: a flag to indicate whether there are more results on the server
    public var moreComing: Bool {
        return operation.moreComing
    }
}

extension BatchedCloudKitOperation where T: CKMoreComing {

    /// - returns: a flag to indicate whether there are more results on the server
    public var moreComing: Bool {
        return operation.moreComing
    }
}

// MARK: - CKDesiredKeys

extension OPRCKOperation where T: CKDesiredKeys {

    public var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set { operation.desiredKeys = newValue }
    }
}

extension CloudKitOperation where T: CKDesiredKeys {

    /// - returns: the desired keys
    public var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set {
            operation.desiredKeys = newValue
            addConfigureBlock { $0.desiredKeys = newValue }
        }
    }
}

extension BatchedCloudKitOperation where T: CKDesiredKeys {

    /// - returns: the desired keys
    public var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set {
            operation.desiredKeys = newValue
            addConfigureBlock { $0.desiredKeys = newValue }
        }
    }
}

// MARK: - BatchProcessOperationType

extension OPRCKOperation where T: BatchProcessOperationType {

    var toProcess: [T.Process]? {
        get { return operation.toProcess }
        set { operation.toProcess = newValue }
    }
}

public extension CloudKitOperation where T: BatchProcessOperationType {

    var toProcess: [T.Process]? {
        get { return operation.toProcess }
        set {
            operation.toProcess = newValue
            addConfigureBlock { $0.toProcess = newValue }
        }
    }
}

// MARK: - BatchModifyOperationType

extension OPRCKOperation where T: BatchModifyOperationType {

    var toSave: [T.Save]? {
        get { return operation.toSave }
        set { operation.toSave = newValue }
    }

    var toDelete: [T.Delete]? {
        get { return operation.toDelete }
        set { operation.toDelete = newValue }
    }
}

public extension CloudKitOperation where T: BatchModifyOperationType {

    var toSave: [T.Save]? {
        get { return operation.toSave }
        set {
            operation.toSave = newValue
            addConfigureBlock { $0.toSave = newValue }
        }
    }

    var toDelete: [T.Delete]? {
        get { return operation.toDelete }
        set {
            operation.toDelete = newValue
            addConfigureBlock { $0.toDelete = newValue }
        }
    }
}

// MARK: - CKDiscoverAllContactsOperation

public struct DiscoverAllContactsError<DiscoveredUserInfo>: CloudKitErrorType {

    public let underlyingError: NSError
    public let userInfo: [DiscoveredUserInfo]?

    init(error: NSError, userInfo: [DiscoveredUserInfo]?) {
        self.underlyingError = error
        self.userInfo = userInfo
    }
}

extension OPRCKOperation where T: CKDiscoverAllContactsOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    func setDiscoverAllContactsCompletionBlock(block: CloudKitOperation<T>.DiscoverAllContactsCompletionBlock) {
        operation.discoverAllContactsCompletionBlock = { [unowned self] userInfo, error in
            if let error = error {
                self.addFatalError(DiscoverAllContactsError(error: error, userInfo: userInfo))
            }
            else {
                block(userInfo)
            }
        }
    }
}

extension CloudKitOperation where T: CKDiscoverAllContactsOperationType {

    /// A typealias for the block type used by CloudKitOperation<CKDiscoverAllContactsOperation>
    public typealias DiscoverAllContactsCompletionBlock = [T.DiscoveredUserInfo]? -> Void

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a DiscoverAllContactsCompletionBlock block
     */
    public func setDiscoverAllContactsCompletionBlock(block: DiscoverAllContactsCompletionBlock) {
        addConfigureBlock { $0.setDiscoverAllContactsCompletionBlock(block) }
    }
}

// MARK: - CKDiscoverUserInfosOperation

extension OPRCKOperation where T: CKDiscoverUserInfosOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set { operation.emailAddresses = newValue }
    }

    public var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set { operation.userRecordIDs = newValue }
    }

    func setDiscoverUserInfosCompletionBlock(block: CloudKitOperation<T>.DiscoverUserInfosCompletionBlock) {
        operation.discoverUserInfosCompletionBlock = { [unowned self] userInfoByEmail, userInfoByRecordID, error in
            if let error = error {
                self.addFatalError(CloudKitError(error: error))
            }
            else {
                block(userInfoByEmail, userInfoByRecordID)
            }
        }
    }
}

extension CloudKitOperation where T: CKDiscoverUserInfosOperationType {

    /// A typealias for the block type used by CloudKitOperation<CKDiscoverUserInfosOperation>
    public typealias DiscoverUserInfosCompletionBlock = ([String: T.DiscoveredUserInfo]?, [T.RecordID: T.DiscoveredUserInfo]?) -> Void

    /// - returns: get or set the email addresses
    public var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set {
            operation.emailAddresses = newValue
            addConfigureBlock { $0.emailAddresses = newValue }
        }
    }

    /// - returns: get or set the user records IDs
    public var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set {
            operation.userRecordIDs = newValue
            addConfigureBlock { $0.userRecordIDs = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a DiscoverUserInfosCompletionBlock block
     */
    public func setDiscoverUserInfosCompletionBlock(block: DiscoverUserInfosCompletionBlock) {
        addConfigureBlock { $0.setDiscoverUserInfosCompletionBlock(block) }
    }
}

// MARK: - CKFetchNotificationChangesOperation

public struct FetchNotificationChangesError<ServerChangeToken>: CloudKitErrorType {

    public let underlyingError: NSError
    public let token: ServerChangeToken?

    init(error: NSError, token: ServerChangeToken?) {
        self.underlyingError = error
        self.token = token
    }
}

extension OPRCKOperation where T: CKFetchNotificationChangesOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var notificationChangedBlock: CloudKitOperation<T>.FetchNotificationChangesChangedBlock? {
        get { return operation.notificationChangedBlock }
        set { operation.notificationChangedBlock = newValue }
    }

    func setFetchNotificationChangesCompletionBlock(block: CloudKitOperation<T>.FetchNotificationChangesCompletionBlock) {

        operation.fetchNotificationChangesCompletionBlock = { [unowned self] token, error in
            if let error = error {
                self.addFatalError(FetchNotificationChangesError(error: error, token: token))
            }
            else {
                block(token)
            }
        }
    }
}

extension CloudKitOperation where T: CKFetchNotificationChangesOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKFetchNotificationChangesOperation>
    public typealias FetchNotificationChangesChangedBlock = T.Notification -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchNotificationChangesOperation>
    public typealias FetchNotificationChangesCompletionBlock = T.ServerChangeToken? -> Void

    /// - returns: the notification changed block
    public var notificationChangedBlock: FetchNotificationChangesChangedBlock? {
        get { return operation.notificationChangedBlock }
        set {
            operation.notificationChangedBlock = newValue
            addConfigureBlock { $0.notificationChangedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchNotificationChangesCompletionBlock block
     */
    public func setFetchNotificationChangesCompletionBlock(block: FetchNotificationChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchNotificationChangesCompletionBlock(block) }
    }
}

extension BatchedCloudKitOperation where T: CKFetchNotificationChangesOperationType {

    /// - returns: the notification changed block
    public var notificationChangedBlock: CloudKitOperation<T>.FetchNotificationChangesChangedBlock? {
        get { return operation.notificationChangedBlock }
        set {
            operation.notificationChangedBlock = newValue
            addConfigureBlock { $0.notificationChangedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a CloudKitOperation<T>.FetchNotificationChangesCompletionBlock block
     */
    public func setFetchNotificationChangesCompletionBlock(block: CloudKitOperation<T>.FetchNotificationChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchNotificationChangesCompletionBlock(block) }
    }
}

// MARK: - CKMarkNotificationsReadOperation

public struct MarkNotificationsReadError<NotificationID>: CloudKitErrorType {

    public let underlyingError: NSError
    public let marked: [NotificationID]?

    init(error: NSError, marked: [NotificationID]?) {
        self.underlyingError = error
        self.marked = marked
    }
}

extension MarkNotificationsReadError: CloudKitBatchProcessErrorType {

    public var processed: [NotificationID]? {
        return marked
    }
}

extension OPRCKOperation where T: CKMarkNotificationsReadOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var notificationIDs: [T.NotificationID] {
        get { return operation.notificationIDs }
        set { operation.notificationIDs = newValue }
    }

    func setMarkNotificationReadCompletionBlock(block: CloudKitOperation<T>.MarkNotificationReadCompletionBlock) {
        operation.markNotificationsReadCompletionBlock = { [unowned self] notificationIDs, error in
            if let error = error {
                self.addFatalError(MarkNotificationsReadError(error: error, marked: notificationIDs))
            }
            else {
                block(notificationIDs)
            }
        }
    }
}

extension CloudKitOperation where T: CKMarkNotificationsReadOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKMarkNotificationsReadOperation>
    public typealias MarkNotificationReadCompletionBlock = [T.NotificationID]? -> Void

    /// - returns: the notification IDs
    public var notificationIDs: [T.NotificationID] {
        get { return operation.notificationIDs }
        set {
            operation.notificationIDs = newValue
            addConfigureBlock { $0.notificationIDs = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a MarkNotificationReadCompletionBlock block
     */
    public func setMarkNotificationReadCompletionBlock(block: MarkNotificationReadCompletionBlock) {
        addConfigureBlock { $0.setMarkNotificationReadCompletionBlock(block) }
    }
}

// MARK: - CKModifyBadgeOperation

extension OPRCKOperation where T: CKModifyBadgeOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var badgeValue: Int {
        get { return operation.badgeValue }
        set { operation.badgeValue = newValue }
    }

    func setModifyBadgeCompletionBlock(block: CloudKitOperation<T>.ModifyBadgeCompletionBlock) {
        operation.modifyBadgeCompletionBlock = { [unowned self] error in
            if let error = error {
                self.addFatalError(CloudKitError(error: error))
            }
            else {
                block()
            }
        }
    }
}

extension CloudKitOperation where T: CKModifyBadgeOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKModifyBadgeOperation>
    public typealias ModifyBadgeCompletionBlock = () -> Void

    public var badgeValue: Int {
        get { return operation.badgeValue }
        set {
            operation.badgeValue = newValue
            addConfigureBlock { $0.badgeValue = newValue }
        }
    }

    public func setModifyBadgeCompletionBlock(block: ModifyBadgeCompletionBlock) {
        addConfigureBlock { $0.setModifyBadgeCompletionBlock(block) }
    }
}

// MARK: - CKFetchRecordChangesOperation

public struct FetchRecordChangesError<ServerChangeToken>: CloudKitErrorType {

    public let underlyingError: NSError
    public let token: ServerChangeToken?
    public let data: NSData?

    init(error: NSError, token: ServerChangeToken?, data: NSData?) {
        self.underlyingError = error
        self.token = token
        self.data = data
    }
}

extension OPRCKOperation where T: CKFetchRecordChangesOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set { operation.recordZoneID = newValue }
    }

    public var recordChangedBlock: CloudKitOperation<T>.FetchRecordChangesRecordChangedBlock? {
        get { return operation.recordChangedBlock }
        set { operation.recordChangedBlock = newValue }
    }

    public var recordWithIDWasDeletedBlock: CloudKitOperation<T>.FetchRecordChangesRecordDeletedBlock? {
        get { return operation.recordWithIDWasDeletedBlock }
        set { operation.recordWithIDWasDeletedBlock = newValue }
    }

    func setFetchRecordChangesCompletionBlock(block: CloudKitOperation<T>.FetchRecordChangesCompletionBlock) {
        operation.fetchRecordChangesCompletionBlock = { [unowned self] token, data, error in
            if let error = error {
                self.addFatalError(FetchRecordChangesError(error: error, token: token, data: data))
            }
            else {
                block(token, data)
            }
        }
    }
}

extension CloudKitOperation where T: CKFetchRecordChangesOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordChangesOperation>
    public typealias FetchRecordChangesRecordChangedBlock = T.Record -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordChangesOperation>
    public typealias FetchRecordChangesRecordDeletedBlock = T.RecordID -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordChangesOperation>
    public typealias FetchRecordChangesCompletionBlock = (T.ServerChangeToken?, NSData?) -> Void

    /// - returns: the record zone ID
    public var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set {
            operation.recordZoneID = newValue
            addConfigureBlock { $0.recordZoneID = newValue }
        }
    }

    /// - returns: a block for when a record changes
    public var recordChangedBlock: FetchRecordChangesRecordChangedBlock? {
        get { return operation.recordChangedBlock }
        set {
            operation.recordChangedBlock = newValue
            addConfigureBlock { $0.recordChangedBlock = newValue }
        }
    }

    /// - returns: a block for when a record with ID is deleted
    public var recordWithIDWasDeletedBlock: FetchRecordChangesRecordDeletedBlock? {
        get { return operation.recordWithIDWasDeletedBlock }
        set {
            operation.recordWithIDWasDeletedBlock = newValue
            addConfigureBlock { $0.recordWithIDWasDeletedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchRecordChangesCompletionBlock block
     */
    public func setFetchRecordChangesCompletionBlock(block: FetchRecordChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordChangesCompletionBlock(block) }
    }
}

extension BatchedCloudKitOperation where T: CKFetchRecordChangesOperationType {

    /// - returns: the record zone ID
    public var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set {
            operation.recordZoneID = newValue
            addConfigureBlock { $0.recordZoneID = newValue }
        }
    }

    /// - returns: a block for when a record changes
    public var recordChangedBlock: CloudKitOperation<T>.FetchRecordChangesRecordChangedBlock? {
        get { return operation.recordChangedBlock }
        set {
            operation.recordChangedBlock = newValue
            addConfigureBlock { $0.recordChangedBlock = newValue }
        }
    }

    /// - returns: a block for when a record with ID is deleted
    public var recordWithIDWasDeletedBlock: CloudKitOperation<T>.FetchRecordChangesRecordDeletedBlock? {
        get { return operation.recordWithIDWasDeletedBlock }
        set {
            operation.recordWithIDWasDeletedBlock = newValue
            addConfigureBlock { $0.recordWithIDWasDeletedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchRecordChangesCompletionBlock block
     */
    public func setFetchRecordChangesCompletionBlock(block: CloudKitOperation<T>.FetchRecordChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordChangesCompletionBlock(block) }
    }
}

// MARK: - CKFetchRecordZonesOperation

public struct FetchRecordZonesError<RecordZone, RecordZoneID: Hashable>: CloudKitErrorType {

    public let underlyingError: NSError
    public let zonesByID: [RecordZoneID: RecordZone]?

    init(error: NSError, zonesByID: [RecordZoneID: RecordZone]?) {
        self.underlyingError = error
        self.zonesByID = zonesByID
    }
}

extension OPRCKOperation where T: CKFetchRecordZonesOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var recordZoneIDs: [T.RecordZoneID]? {
        get { return operation.recordZoneIDs }
        set { operation.recordZoneIDs = newValue }
    }

    func setFetchRecordZonesCompletionBlock(block: CloudKitOperation<T>.FetchRecordZonesCompletionBlock) {
        operation.fetchRecordZonesCompletionBlock = { [unowned self] zonesByID, error in
            if let error = error {
                self.addFatalError(FetchRecordZonesError(error: error, zonesByID: zonesByID))
            }
            else {
                block(zonesByID)
            }
        }
    }
}

extension CloudKitOperation where T: CKFetchRecordZonesOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordZonesOperation>
    public typealias FetchRecordZonesCompletionBlock = [T.RecordZoneID: T.RecordZone]? -> Void

    /// - returns: the record zone IDs
    public var recordZoneIDs: [T.RecordZoneID]? {
        get { return operation.recordZoneIDs }
        set {
            operation.recordZoneIDs = newValue
            addConfigureBlock { $0.recordZoneIDs = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchRecordZonesCompletionBlock block
     */
    public func setFetchRecordZonesCompletionBlock(block: FetchRecordZonesCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordZonesCompletionBlock(block) }
    }
}

// MARK: - CKFetchRecordsOperation

public struct FetchRecordsError<Record, RecordID: Hashable>: CloudKitErrorType {

    public let underlyingError: NSError
    public let recordsByID: [RecordID: Record]?

    init(error: NSError, recordsByID: [RecordID: Record]?) {
        self.underlyingError = error
        self.recordsByID = recordsByID
    }
}

extension OPRCKOperation where T: CKFetchRecordsOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var recordIDs: [T.RecordID]? {
        get { return operation.recordIDs }
        set { operation.recordIDs = newValue }
    }

    public var perRecordProgressBlock: CloudKitOperation<T>.FetchRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    public var perRecordCompletionBlock: CloudKitOperation<T>.FetchRecordsPerRecordCompletionBlock? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    func setFetchRecordsCompletionBlock(block: CloudKitOperation<T>.FetchRecordsCompletionBlock) {
        operation.fetchRecordsCompletionBlock = { [unowned self] recordsByID, error in
            if let error = error {
                self.addFatalError(FetchRecordsError(error: error, recordsByID: recordsByID))
            }
            else {
                block(recordsByID)
            }
        }
    }
}

extension CloudKitOperation where T: CKFetchRecordsOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordsOperation>
    public typealias FetchRecordsPerRecordProgressBlock = (T.RecordID, Double) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordsOperation>
    public typealias FetchRecordsPerRecordCompletionBlock = (T.Record?, T.RecordID?, NSError?) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordsOperation>
    public typealias FetchRecordsCompletionBlock = [T.RecordID: T.Record]? -> Void

    /// - returns: the record IDs
    public var recordIDs: [T.RecordID]? {
        get { return operation.recordIDs }
        set {
            operation.recordIDs = newValue
            addConfigureBlock { $0.recordIDs = newValue }
        }
    }

    /// - returns: a block for the record progress
    public var perRecordProgressBlock: FetchRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set {
            operation.perRecordProgressBlock = newValue
            addConfigureBlock { $0.perRecordProgressBlock = newValue }
        }
    }

    /// - returns: a block for the record completion
    public var perRecordCompletionBlock: FetchRecordsPerRecordCompletionBlock? {
        get { return operation.perRecordCompletionBlock }
        set {
            operation.perRecordCompletionBlock = newValue
            addConfigureBlock { $0.perRecordCompletionBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchRecordsCompletionBlock block
     */
    public func setFetchRecordsCompletionBlock(block: FetchRecordsCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordsCompletionBlock(block) }
    }
}

// MARK: - CKFetchSubscriptionsOperation

public struct FetchSubscriptionsError<Subscription>: CloudKitErrorType {

    public let underlyingError: NSError
    public let subscriptionsByID: [String: Subscription]?

    init(error: NSError, subscriptionsByID: [String: Subscription]?) {
        self.underlyingError = error
        self.subscriptionsByID = subscriptionsByID
    }
}

extension OPRCKOperation where T: CKFetchSubscriptionsOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var subscriptionIDs: [String]? {
        get { return operation.subscriptionIDs }
        set { operation.subscriptionIDs = newValue }
    }

    func setFetchSubscriptionCompletionBlock(block: CloudKitOperation<T>.FetchSubscriptionCompletionBlock) {
        operation.fetchSubscriptionCompletionBlock = { [unowned self] subscriptionsByID, error in
            if let error = error {
                self.addFatalError(FetchSubscriptionsError(error: error, subscriptionsByID: subscriptionsByID))
            }
            else {
                block(subscriptionsByID)
            }
        }
    }
}

extension CloudKitOperation where T: CKFetchSubscriptionsOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKFetchSubscriptionsOperation>
    public typealias FetchSubscriptionCompletionBlock = [String: T.Subscription]? -> Void

    /// - returns: the subscription IDs
    public var subscriptionIDs: [String]? {
        get { return operation.subscriptionIDs }
        set {
            operation.subscriptionIDs = newValue
            addConfigureBlock { $0.subscriptionIDs = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchSubscriptionCompletionBlock block
     */
    public func setFetchSubscriptionCompletionBlock(block: FetchSubscriptionCompletionBlock) {
        addConfigureBlock { $0.setFetchSubscriptionCompletionBlock(block) }
    }
}

// MARK: - CKModifyRecordZonesOperation

public struct ModifyRecordZonesError<RecordZone, RecordZoneID>: CloudKitErrorType, CloudKitBatchModifyErrorType {

    public let underlyingError: NSError
    public let saved: [RecordZone]?
    public let deleted: [RecordZoneID]?

    init(error: NSError, saved: [RecordZone]?, deleted: [RecordZoneID]?) {
        self.underlyingError = error
        self.saved = saved
        self.deleted = deleted
    }
}

extension OPRCKOperation where T: CKModifyRecordZonesOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var recordZonesToSave: [T.RecordZone]? {
        get { return operation.recordZonesToSave }
        set { operation.recordZonesToSave = newValue }
    }

    public var recordZoneIDsToDelete: [T.RecordZoneID]? {
        get { return operation.recordZoneIDsToDelete }
        set { operation.recordZoneIDsToDelete = newValue }
    }

    func setModifyRecordZonesCompletionBlock(block: CloudKitOperation<T>.ModifyRecordZonesCompletionBlock) {
        operation.modifyRecordZonesCompletionBlock = { [unowned self] saved, deleted, error in
            if let error = error {
                self.addFatalError(ModifyRecordZonesError(error: error, saved: saved, deleted: deleted))
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

extension CloudKitOperation where T: CKModifyRecordZonesOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKModifyRecordZonesOperation>
    public typealias ModifyRecordZonesCompletionBlock = ([T.RecordZone]?, [T.RecordZoneID]?) -> Void

    /// - returns: the record zones to save
    public var recordZonesToSave: [T.RecordZone]? {
        get { return operation.recordZonesToSave }
        set {
            operation.recordZonesToSave = newValue
            addConfigureBlock { $0.recordZonesToSave = newValue }
        }
    }

    /// - returns: the record zone IDs to delete
    public var recordZoneIDsToDelete: [T.RecordZoneID]? {
        get { return operation.recordZoneIDsToDelete }
        set {
            operation.recordZoneIDsToDelete = newValue
            addConfigureBlock { $0.recordZoneIDsToDelete = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a ModifyRecordZonesCompletionBlock block
     */
    public func setModifyRecordZonesCompletionBlock(block: ModifyRecordZonesCompletionBlock) {
        addConfigureBlock { $0.setModifyRecordZonesCompletionBlock(block) }
    }
}

// MARK: - CKModifyRecordsOperation

public struct ModifyRecordsError<Record, RecordID>: CloudKitErrorType, CloudKitBatchModifyErrorType {

    public let underlyingError: NSError
    public let saved: [Record]?
    public let deleted: [RecordID]?

    init(error: NSError, saved: [Record]?, deleted: [RecordID]?) {
        self.underlyingError = error
        self.saved = saved
        self.deleted = deleted
    }
}

extension OPRCKOperation where T: CKModifyRecordsOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    typealias ModifyRecordsCompletionBlock = ([T.Record]?, [T.RecordID]?) -> Void

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

    public var isAtomic: Bool {
        get { return operation.isAtomic }
        set { operation.isAtomic = newValue }
    }

    public var perRecordProgressBlock: CloudKitOperation<T>.ModifyRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    public var perRecordCompletionBlock: CloudKitOperation<T>.ModifyRecordsPerRecordCompletionBlock? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    func setModifyRecordsCompletionBlock(block: CloudKitOperation<T>.ModifyRecordsCompletionBlock) {
        operation.modifyRecordsCompletionBlock = { [unowned self] saved, deleted, error in
            if let error = error {
                self.addFatalError(ModifyRecordsError(error: error, saved: saved, deleted: deleted))
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

extension CloudKitOperation where T: CKModifyRecordsOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKModifyRecordsOperation>
    public typealias ModifyRecordsPerRecordProgressBlock = (T.Record, Double) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKModifyRecordsOperation>
    public typealias ModifyRecordsPerRecordCompletionBlock = (T.Record?, NSError?) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKModifyRecordsOperation>
    public typealias ModifyRecordsCompletionBlock = ([T.Record]?, [T.RecordID]?) -> Void

    /// - returns: the records to save
    public var recordsToSave: [T.Record]? {
        get { return operation.recordsToSave }
        set {
            operation.recordsToSave = newValue
            addConfigureBlock { $0.recordsToSave = newValue }
        }
    }

    /// - returns: the record IDs to delete
    public var recordIDsToDelete: [T.RecordID]? {
        get { return operation.recordIDsToDelete }
        set {
            operation.recordIDsToDelete = newValue
            addConfigureBlock { $0.recordIDsToDelete = newValue }
        }
    }

    /// - returns: the save policy
    public var savePolicy: T.RecordSavePolicy {
        get { return operation.savePolicy }
        set {
            operation.savePolicy = newValue
            addConfigureBlock { $0.savePolicy = newValue }
        }
    }

    /// - returns: the client change token data
    public var clientChangeTokenData: NSData? {
        get { return operation.clientChangeTokenData }
        set {
            operation.clientChangeTokenData = newValue
            addConfigureBlock { $0.clientChangeTokenData = newValue }
        }
    }

    /// - returns: a flag to indicate atomicity
    public var isAtomic: Bool {
        get { return operation.isAtomic }
        set {
            operation.isAtomic = newValue
            addConfigureBlock { $0.isAtomic = newValue }
        }
    }

    /// - returns: a block for per record progress
    public var perRecordProgressBlock: ModifyRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set {
            operation.perRecordProgressBlock = newValue
            addConfigureBlock { $0.perRecordProgressBlock = newValue }
        }
    }

    /// - returns: a block for per record completion
    public var perRecordCompletionBlock: ModifyRecordsPerRecordCompletionBlock? {
        get { return operation.perRecordCompletionBlock }
        set {
            operation.perRecordCompletionBlock = newValue
            addConfigureBlock { $0.perRecordCompletionBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a ModifyRecordsCompletionBlock block
     */
    public func setModifyRecordsCompletionBlock(block: ModifyRecordsCompletionBlock) {
        addConfigureBlock { $0.setModifyRecordsCompletionBlock(block) }
    }
}

// MARK: - CKModifySubscriptionsOperation

public struct ModifySubscriptionsError<Subscription, SubscriptionID>: CloudKitErrorType, CloudKitBatchModifyErrorType {

    public let underlyingError: NSError
    public let saved: [Subscription]?
    public let deleted: [SubscriptionID]?

    init(error: NSError, saved: [Subscription]?, deleted: [SubscriptionID]?) {
        self.underlyingError = error
        self.saved = saved
        self.deleted = deleted
    }
}

extension OPRCKOperation where T: CKModifySubscriptionsOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

    public var subscriptionsToSave: [T.Subscription]? {
        get { return operation.subscriptionsToSave }
        set { operation.subscriptionsToSave = newValue }
    }

    public var subscriptionIDsToDelete: [String]? {
        get { return operation.subscriptionIDsToDelete }
        set { operation.subscriptionIDsToDelete = newValue }
    }

    func setModifySubscriptionsCompletionBlock(block: CloudKitOperation<T>.ModifySubscriptionsCompletionBlock) {
        operation.modifySubscriptionsCompletionBlock = { [unowned self] saved, deleted, error in
            if let error = error {
                self.addFatalError(ModifySubscriptionsError(error: error, saved: saved, deleted: deleted))
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

extension CloudKitOperation where T: CKModifySubscriptionsOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKModifySubscriptionsOperation>
    public typealias ModifySubscriptionsCompletionBlock = ([T.Subscription]?, [String]?) -> Void

    /// - returns: the subscriptions to save
    public var subscriptionsToSave: [T.Subscription]? {
        get { return operation.subscriptionsToSave }
        set {
            operation.subscriptionsToSave = newValue
            addConfigureBlock { $0.subscriptionsToSave = newValue }
        }
    }

    /// - returns: the subscription IDs to delete
    public var subscriptionIDsToDelete: [String]? {
        get { return operation.subscriptionIDsToDelete }
        set {
            operation.subscriptionIDsToDelete = newValue
            addConfigureBlock { $0.subscriptionIDsToDelete = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a ModifySubscriptionsCompletionBlock block
     */
    public func setModifySubscriptionsCompletionBlock(block: ModifySubscriptionsCompletionBlock) {
        addConfigureBlock { $0.setModifySubscriptionsCompletionBlock(block) }
    }
}

// MARK: - CKQueryOperation

public struct QueryError<QueryCursor>: CloudKitErrorType {

    public let underlyingError: NSError
    public let cursor: QueryCursor?

    init(error: NSError, cursor: QueryCursor?) {
        self.underlyingError = error
        self.cursor = cursor
    }
}

extension OPRCKOperation where T: CKQueryOperationType, T: AssociatedErrorType, T.Error: CloudKitErrorType {

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

    public var recordFetchedBlock: CloudKitOperation<T>.QueryRecordFetchedBlock? {
        get { return operation.recordFetchedBlock }
        set { operation.recordFetchedBlock = newValue }
    }

    func setQueryCompletionBlock(block: CloudKitOperation<T>.QueryCompletionBlock) {
        operation.queryCompletionBlock = { [unowned self] cursor, error in
            if let error = error {
                self.addFatalError(QueryError(error: error, cursor: cursor))
            }
            else {
                block(cursor)
            }
        }
    }
}

extension CloudKitOperation where T: CKQueryOperationType {

    /// A typealias for the block types used by CloudKitOperation<CKQueryOperation>
    public typealias QueryRecordFetchedBlock = T.Record -> Void

    /// A typealias for the block types used by CloudKitOperation<CKQueryOperation>
    public typealias QueryCompletionBlock = T.QueryCursor? -> Void

    /// - returns: the query
    public var query: T.Query? {
        get { return operation.query }
        set {
            operation.query = newValue
            addConfigureBlock { $0.query = newValue }
        }
    }

    /// - returns: the query cursor
    public var cursor: T.QueryCursor? {
        get { return operation.cursor }
        set {
            operation.cursor = newValue
            addConfigureBlock { $0.cursor = newValue }
        }
    }

    /// - returns: the zone ID
    public var zoneID: T.RecordZoneID? {
        get { return operation.zoneID }
        set {
            operation.zoneID = newValue
            addConfigureBlock { $0.zoneID = newValue }
        }
    }

    /// - returns: a block for each record fetched
    public var recordFetchedBlock: QueryRecordFetchedBlock? {
        get { return operation.recordFetchedBlock }
        set {
            operation.recordFetchedBlock = newValue
            addConfigureBlock { $0.recordFetchedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a QueryCompletionBlock block
     */
    public func setQueryCompletionBlock(block: QueryCompletionBlock) {
        addConfigureBlock { $0.setQueryCompletionBlock(block) }
    }
}

// swiftlint:enable file_length
