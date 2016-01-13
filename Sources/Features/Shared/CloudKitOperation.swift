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

public protocol CKBatchedOperationType: CKResultsLimit, CKMoreComing { }

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

extension CKDiscoverAllContactsOperation:       CKDiscoverAllContactsOperationType { }
extension CKDiscoverUserInfosOperation:         CKDiscoverUserInfosOperationType { }
extension CKFetchNotificationChangesOperation:  CKFetchNotificationChangesOperationType   { }
extension CKMarkNotificationsReadOperation:     CKMarkNotificationsReadOperationType { }
extension CKModifyBadgeOperation:               CKModifyBadgeOperationType { }
extension CKFetchRecordChangesOperation:        CKFetchRecordChangesOperationType { }
extension CKFetchRecordZonesOperation:          CKFetchRecordZonesOperationType { }
extension CKFetchRecordsOperation:              CKFetchRecordsOperationType { }
extension CKFetchSubscriptionsOperation:        CKFetchSubscriptionsOperationType { }
extension CKModifyRecordZonesOperation:         CKModifyRecordZonesOperationType { }
extension CKModifyRecordsOperation:             CKModifyRecordsOperationType { }
extension CKModifySubscriptionsOperation:       CKModifySubscriptionsOperationType { }
extension CKQueryOperation:                     CKQueryOperationType { }


// MARK: Internal CK Operation

class CloudKitOperation<T where T: NSOperation, T: CKOperationType>: ReachableOperation<T> {

    convenience init(_ op: T) {
        self.init(operation: op, connectivity: .AnyConnectionKind, reachability: Reachability.sharedInstance)
    }

    override init(operation op: T, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        super.init(operation: op, connectivity: connectivity, reachability: reachability)
        name = "InternalCKOperation<\(T.self)>"
    }
}

// MARK: - Cloud Kit Error Recovery

public class CloudKitRecovery {

    func recoverWithInfo<T where T: NSOperation, T: CKOperationType>(info: RetryFailureInfo<CloudKitOperation<T>>, delay: Delay?, next: CloudKitOperation<T>) -> (Delay?, CloudKitOperation<T>)? {
        return .None
    }
}

// MARK: - CloudKitOperation

public class CloudKit<T where T: NSOperation, T: CKOperationType>: RetryOperation<CloudKitOperation<T>> {

    let recovery: CloudKitRecovery

    var operation: T {
        return current.operation
    }

    public convenience init(_ body: () -> T?) {
        self.init(generator: anyGenerator(body), connectivity: .AnyConnectionKind, reachability: Reachability.sharedInstance)
    }

    convenience init(connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType, _ body: () -> T?) {
        self.init(generator: anyGenerator(body), connectivity: .AnyConnectionKind, reachability: Reachability.sharedInstance)
    }

    init<G where G: GeneratorType, G.Element == T>(generator gen: G, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {

        // Creates a standard random delay between retries
        let strategy: WaitStrategy = .Random((0.1, 1.0))
        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }

        // Maps the generator to wrap the target operation.
        let generator = MapGenerator(gen) { CloudKitOperation(operation: $0, connectivity: connectivity, reachability: reachability) }

        // Creates a CloudKitRecovery object
        let _recovery = CloudKitRecovery()
        self.recovery = _recovery

        // Creates a Retry Handler using the recovery object
        let handler: Handler = { info, delay, next in
            return _recovery.recoverWithInfo(info, delay: delay, next: next)
        }

        super.init(maxCount: .None, delay: delay, generator: generator, retry: handler)
        name = "CloudKitOperation<\(T.self)>"
    }
}

// MARK: - BatchedCloudKitOperation

class CloudKitGenerator<T where T: NSOperation, T: CKOperationType>: GeneratorType {

    let connectivity: Reachability.Connectivity
    let reachability: SystemReachabilityType

    var generator: AnyGenerator<T>
    var more: Bool = true

    init<G where G: GeneratorType, G.Element == T>(generator: G, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        self.generator = anyGenerator(generator)
        self.connectivity = connectivity
        self.reachability = reachability
    }

    func next() -> CloudKit<T>? {
        guard more else { return .None }
        return CloudKit(generator: generator, connectivity: connectivity, reachability: reachability)
    }
}

public class BatchedCloudKit<T where T: NSOperation, T: CKBatchedOperationType>: RepeatedOperation<CloudKit<T>> {

    public var enableBatchProcessing: Bool
    var generator: CloudKitGenerator<T>

    public var operation: T {
        return current.operation
    }

    public convenience init(enableBatchProcessing enable: Bool = true, _ body: () -> T?) {
        self.init(generator: anyGenerator(body), enableBatchProcessing: enable, connectivity: .AnyConnectionKind, reachability: Reachability.sharedInstance)
    }

    init<G where G: GeneratorType, G.Element == T>(generator gen: G, enableBatchProcessing enable: Bool = true, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        enableBatchProcessing = enable
        generator = CloudKitGenerator(generator: gen, connectivity: connectivity, reachability: reachability)

        // Creates a standard fixed delay between retries
        let strategy: WaitStrategy = .Fixed(0.1)
        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }
        let tuple = TupleGenerator(primary: generator, secondary: delay)

        super.init(generator: anyGenerator(tuple))
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty, let cloudKitOperation = operation as? CloudKit<T> {
            generator.more = enableBatchProcessing && cloudKitOperation.current.moreComing
        }
        super.operationDidFinish(operation, withErrors: errors)
    }
}






// MARK: - CKOperationType

extension CloudKitOperation where T: CKOperationType {

    internal var container: T.Container? {
        get { return operation.container }
        set { operation.container = newValue }
    }
}

extension CloudKit where T: CKOperationType {

    public var container: T.Container? {
        get { return operation.container }
        set {
            operation.container = newValue
            addConfigureBlock { $0.container = newValue }
        }
    }
}

// MARK: - CKDatabaseOperation

extension CloudKitOperation where T: CKDatabaseOperationType {

    internal var database: T.Database? {
        get { return operation.database }
        set { operation.database = newValue }
    }
}

extension CloudKit where T: CKDatabaseOperationType {

    public var database: T.Database? {
        get { return operation.database }
        set {
            operation.database = newValue
            addConfigureBlock { $0.database = newValue }
        }
    }
}

// MARK: - CKPreviousServerChangeToken

extension CloudKitOperation where T: CKPreviousServerChangeToken {

    internal var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set { operation.previousServerChangeToken = newValue }
    }
}

extension CloudKit where T: CKPreviousServerChangeToken {

    public var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set {
            operation.previousServerChangeToken = newValue
            addConfigureBlock { $0.previousServerChangeToken = newValue }
        }
    }
}

// MARK: - CKResultsLimit

extension CloudKitOperation where T: CKResultsLimit {

    internal var resultsLimit: Int {
        get { return operation.resultsLimit }
        set { operation.resultsLimit = newValue }
    }
}

extension CloudKit where T: CKResultsLimit {

    public var resultsLimit: Int {
        get { return operation.resultsLimit }
        set {
            operation.resultsLimit = newValue
            addConfigureBlock { $0.resultsLimit = newValue }
        }
    }
}

// MARK: - CKMoreComing

extension CloudKitOperation where T: CKMoreComing {

    internal var moreComing: Bool {
        return operation.moreComing
    }
}

extension CloudKit where T: CKMoreComing {

    public var moreComing: Bool {
        return operation.moreComing
    }
}

// MARK: - CKDesiredKeys

extension CloudKitOperation where T: CKDesiredKeys {

    internal var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set { operation.desiredKeys = newValue }
    }
}

extension CloudKit where T: CKDesiredKeys {

    public var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set {
            operation.desiredKeys = newValue
            addConfigureBlock { $0.desiredKeys = newValue }
        }
    }
}

// MARK: - CKDiscoverAllContactsOperation

extension CloudKitOperation where T: CKDiscoverAllContactsOperationType {

    internal typealias DiscoverAllContactsCompletionBlock = [T.DiscoveredUserInfo]? -> Void

    internal func setDiscoverAllContactsCompletionBlock(block: DiscoverAllContactsCompletionBlock) {
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

extension CloudKit where T: CKDiscoverAllContactsOperationType {

    public typealias DiscoverAllContactsCompletionBlock = [T.DiscoveredUserInfo]? -> Void

    public func setDiscoverAllContactsCompletionBlock(block: DiscoverAllContactsCompletionBlock) {
        addConfigureBlock { $0.setDiscoverAllContactsCompletionBlock(block) }
    }
}

// MARK: - CKDiscoverUserInfosOperation

extension CloudKitOperation where T: CKDiscoverUserInfosOperationType {

    internal typealias DiscoverUserInfosCompletionBlock = ([String: T.DiscoveredUserInfo]?, [T.RecordID: T.DiscoveredUserInfo]?) -> Void

    internal var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set { operation.emailAddresses = newValue }
    }

    internal var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set { operation.userRecordIDs = newValue }
    }

    internal func setDiscoverUserInfosCompletionBlock(block: DiscoverUserInfosCompletionBlock) {
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

extension CloudKit where T: CKDiscoverUserInfosOperationType {

    public typealias DiscoverUserInfosCompletionBlock = ([String: T.DiscoveredUserInfo]?, [T.RecordID: T.DiscoveredUserInfo]?) -> Void

    public var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set {
            operation.emailAddresses = newValue
            addConfigureBlock { $0.emailAddresses = newValue }
        }
    }

    public var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set {
            operation.userRecordIDs = newValue
            addConfigureBlock { $0.userRecordIDs = newValue }
        }
    }

    public func setDiscoverUserInfosCompletionBlock(block: DiscoverUserInfosCompletionBlock) {
        addConfigureBlock { $0.setDiscoverUserInfosCompletionBlock(block) }
    }
}

// MARK: - CKFetchNotificationChangesOperation

extension CloudKitOperation where T: CKFetchNotificationChangesOperationType {

    internal typealias FetchNotificationChangesChangedBlock = T.Notification -> Void
    internal typealias FetchNotificationChangesCompletionBlock = T.ServerChangeToken? -> Void

    internal var notificationChangedBlock: ((T.Notification) -> Void)? {
        get { return operation.notificationChangedBlock }
        set { operation.notificationChangedBlock = newValue }
    }

    internal func setFetchNotificationChangesCompletionBlock(block: FetchNotificationChangesCompletionBlock) {

        operation.fetchNotificationChangesCompletionBlock = { [unowned target] token, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(token)
            }
        }
    }
}

extension CloudKit where T: CKFetchNotificationChangesOperationType {

    public typealias FetchNotificationChangesChangedBlock = T.Notification -> Void
    public typealias FetchNotificationChangesCompletionBlock = T.ServerChangeToken? -> Void

    public var notificationChangedBlock: ((T.Notification) -> Void)? {
        get { return operation.notificationChangedBlock }
        set {
            operation.notificationChangedBlock = newValue
            addConfigureBlock { $0.notificationChangedBlock = newValue }
        }
    }

    public func setFetchNotificationChangesCompletionBlock(block: FetchNotificationChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchNotificationChangesCompletionBlock(block) }
    }
}

extension BatchedCloudKit where T: CKFetchNotificationChangesOperationType {

    public typealias FetchNotificationChangesChangedBlock = T.Notification -> Void
    public typealias FetchNotificationChangesCompletionBlock = T.ServerChangeToken? -> Void

    public var notificationChangedBlock: ((T.Notification) -> Void)? {
        get { return operation.notificationChangedBlock }
        set {
            operation.notificationChangedBlock = newValue
            addConfigureBlock { $0.notificationChangedBlock = newValue }
        }
    }

    public func setFetchNotificationChangesCompletionBlock(block: FetchNotificationChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchNotificationChangesCompletionBlock(block) }
    }
}

// MARK: - CKMarkNotificationsReadOperation

extension CloudKitOperation where T: CKMarkNotificationsReadOperationType {

    internal typealias MarkNotificationReadCompletionBlock = [T.NotificationID]? -> Void

    internal var notificationIDs: [T.NotificationID] {
        get { return operation.notificationIDs }
        set { operation.notificationIDs = newValue }
    }

    internal func setMarkNotificationReadCompletionBlock(block: MarkNotificationReadCompletionBlock) {
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

extension CloudKit where T: CKMarkNotificationsReadOperationType {

    public typealias MarkNotificationReadCompletionBlock = [T.NotificationID]? -> Void

    public var notificationIDs: [T.NotificationID] {
        get { return operation.notificationIDs }
        set {
            operation.notificationIDs = newValue
            addConfigureBlock { $0.notificationIDs = newValue }
        }
    }

    public func setMarkNotificationReadCompletionBlock(block: MarkNotificationReadCompletionBlock) {
        addConfigureBlock { $0.setMarkNotificationReadCompletionBlock(block) }
    }
}

// MARK: - CKModifyBadgeOperation

extension CloudKitOperation where T: CKModifyBadgeOperationType {

    internal typealias ModifyBadgeCompletionBlock = () -> Void

    internal var badgeValue: Int {
        get { return operation.badgeValue }
        set { operation.badgeValue = newValue }
    }

    internal func setModifyBadgeCompletionBlock(block: ModifyBadgeCompletionBlock) {
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

extension CloudKit where T: CKModifyBadgeOperationType {

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

extension CloudKitOperation where T: CKFetchRecordChangesOperationType {

    internal typealias FetchRecordChangesCompletionBlock = (T.ServerChangeToken?, NSData?) -> Void

    internal var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set { operation.recordZoneID = newValue }
    }

    internal var recordChangedBlock: ((T.Record) -> Void)? {
        get { return operation.recordChangedBlock }
        set { operation.recordChangedBlock = newValue }
    }

    internal var recordWithIDWasDeletedBlock: ((T.RecordID) -> Void)? {
        get { return operation.recordWithIDWasDeletedBlock }
        set { operation.recordWithIDWasDeletedBlock = newValue }
    }

    internal func setFetchRecordChangesCompletionBlock(block: FetchRecordChangesCompletionBlock) {
        operation.fetchRecordChangesCompletionBlock = { [unowned target] token, data, error in
            if let error = error, target = target as? GroupOperation {
                target.aggregateError(error)
            }
            else {
                block(token, data)
            }
        }
    }
}

extension CloudKit where T: CKFetchRecordChangesOperationType {

    public typealias FetchRecordChangesCompletionBlock = (T.ServerChangeToken?, NSData?) -> Void

    public var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set {
            operation.recordZoneID = newValue
            addConfigureBlock { $0.recordZoneID = newValue }
        }
    }

    public var recordChangedBlock: ((T.Record) -> Void)? {
        get { return operation.recordChangedBlock }
        set {
            operation.recordChangedBlock = newValue
            addConfigureBlock { $0.recordChangedBlock = newValue }
        }
    }

    public var recordWithIDWasDeletedBlock: ((T.RecordID) -> Void)? {
        get { return operation.recordWithIDWasDeletedBlock }
        set {
            operation.recordWithIDWasDeletedBlock = newValue
            addConfigureBlock { $0.recordWithIDWasDeletedBlock = newValue }
        }
    }

    public func setFetchRecordChangesCompletionBlock(block: FetchRecordChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordChangesCompletionBlock(block) }
    }
}

extension BatchedCloudKit where T: CKFetchRecordChangesOperationType {

    public typealias FetchRecordChangesCompletionBlock = (T.ServerChangeToken?, NSData?) -> Void

    public var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set {
            operation.recordZoneID = newValue
            addConfigureBlock { $0.recordZoneID = newValue }
        }
    }

    public var recordChangedBlock: ((T.Record) -> Void)? {
        get { return operation.recordChangedBlock }
        set {
            operation.recordChangedBlock = newValue
            addConfigureBlock { $0.recordChangedBlock = newValue }
        }
    }

    public var recordWithIDWasDeletedBlock: ((T.RecordID) -> Void)? {
        get { return operation.recordWithIDWasDeletedBlock }
        set {
            operation.recordWithIDWasDeletedBlock = newValue
            addConfigureBlock { $0.recordWithIDWasDeletedBlock = newValue }
        }
    }

    public func setFetchRecordChangesCompletionBlock(block: FetchRecordChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordChangesCompletionBlock(block) }
    }
}

// MARK: - CKFetchRecordZonesOperation

extension CloudKitOperation where T: CKFetchRecordZonesOperationType {

    internal typealias FetchRecordZonesCompletionBlock = [T.RecordZoneID: T.RecordZone]? -> Void

    internal var recordZoneIDs: [T.RecordZoneID]? {
        get { return operation.recordZoneIDs }
        set { operation.recordZoneIDs = newValue }
    }

    internal func setFetchRecordZonesCompletionBlock(block: FetchRecordZonesCompletionBlock) {
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

extension CloudKit where T: CKFetchRecordZonesOperationType {

    public typealias FetchRecordZonesCompletionBlock = [T.RecordZoneID: T.RecordZone]? -> Void

    public var recordZoneIDs: [T.RecordZoneID]? {
        get { return operation.recordZoneIDs }
        set {
            operation.recordZoneIDs = newValue
            addConfigureBlock { $0.recordZoneIDs = newValue }
        }
    }

    public func setFetchRecordZonesCompletionBlock(block: FetchRecordZonesCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordZonesCompletionBlock(block) }
    }
}

// MARK: - CKFetchRecordsOperation

extension CloudKitOperation where T: CKFetchRecordsOperationType {

    internal typealias FetchRecordsCompletionBlock = [T.RecordID: T.Record]? -> Void

    internal var recordIDs: [T.RecordID]? {
        get { return operation.recordIDs }
        set { operation.recordIDs = newValue }
    }

    internal var perRecordProgressBlock: ((T.RecordID, Double) -> Void)? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    internal var perRecordCompletionBlock: ((T.Record?, T.RecordID?, NSError?) -> Void)? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    internal func setFetchRecordsCompletionBlock(block: FetchRecordsCompletionBlock) {
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

extension CloudKit where T: CKFetchRecordsOperationType {

    public typealias FetchRecordsCompletionBlock = [T.RecordID: T.Record]? -> Void

    public var recordIDs: [T.RecordID]? {
        get { return operation.recordIDs }
        set {
            operation.recordIDs = newValue
            addConfigureBlock { $0.recordIDs = newValue }
        }
    }

    public var perRecordProgressBlock: ((T.RecordID, Double) -> Void)? {
        get { return operation.perRecordProgressBlock }
        set {
            operation.perRecordProgressBlock = newValue
            addConfigureBlock { $0.perRecordProgressBlock = newValue }
        }
    }

    public var perRecordCompletionBlock: ((T.Record?, T.RecordID?, NSError?) -> Void)? {
        get { return operation.perRecordCompletionBlock }
        set {
            operation.perRecordCompletionBlock = newValue
            addConfigureBlock { $0.perRecordCompletionBlock = newValue }
        }
    }

    public func setFetchRecordsCompletionBlock(block: FetchRecordsCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordsCompletionBlock(block) }
    }
}

// MARK: - CKFetchSubscriptionsOperation

extension CloudKitOperation where T: CKFetchSubscriptionsOperationType {

    internal typealias FetchSubscriptionCompletionBlock = [String: T.Subscription]? -> Void

    internal var subscriptionIDs: [String]? {
        get { return operation.subscriptionIDs }
        set { operation.subscriptionIDs = newValue }
    }

    internal func setFetchSubscriptionCompletionBlock(block: FetchSubscriptionCompletionBlock) {
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

extension CloudKit where T: CKFetchSubscriptionsOperationType {

    public typealias FetchSubscriptionCompletionBlock = [String: T.Subscription]? -> Void

    public var subscriptionIDs: [String]? {
        get { return operation.subscriptionIDs }
        set {
            operation.subscriptionIDs = newValue
            addConfigureBlock { $0.subscriptionIDs = newValue }
        }
    }

    public func setFetchSubscriptionCompletionBlock(block: FetchSubscriptionCompletionBlock) {
        addConfigureBlock { $0.setFetchSubscriptionCompletionBlock(block) }
    }
}

// MARK: - CKModifyRecordZonesOperation

extension CloudKitOperation where T: CKModifyRecordZonesOperationType {

    internal typealias ModifyRecordZonesCompletionBlock = ([T.RecordZone]?, [T.RecordZoneID]?) -> Void

    internal var recordZonesToSave: [T.RecordZone]? {
        get { return operation.recordZonesToSave }
        set { operation.recordZonesToSave = newValue }
    }

    internal var recordZoneIDsToDelete: [T.RecordZoneID]? {
        get { return operation.recordZoneIDsToDelete }
        set { operation.recordZoneIDsToDelete = newValue }
    }

    internal func setModifyRecordZonesCompletionBlock(block: ModifyRecordZonesCompletionBlock) {
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

extension CloudKit where T: CKModifyRecordZonesOperationType {

    public typealias ModifyRecordZonesCompletionBlock = ([T.RecordZone]?, [T.RecordZoneID]?) -> Void

    public var recordZonesToSave: [T.RecordZone]? {
        get { return operation.recordZonesToSave }
        set {
            operation.recordZonesToSave = newValue
            addConfigureBlock { $0.recordZonesToSave = newValue }
        }
    }

    public var recordZoneIDsToDelete: [T.RecordZoneID]? {
        get { return operation.recordZoneIDsToDelete }
        set {
            operation.recordZoneIDsToDelete = newValue
            addConfigureBlock { $0.recordZoneIDsToDelete = newValue }
        }
    }

    public func setModifyRecordZonesCompletionBlock(block: ModifyRecordZonesCompletionBlock) {
        addConfigureBlock { $0.setModifyRecordZonesCompletionBlock(block) }
    }
}

// MARK: - CKModifyRecordsOperation

extension CloudKitOperation where T: CKModifyRecordsOperationType {

    internal typealias ModifyRecordsCompletionBlock = ([T.Record]?, [T.RecordID]?) -> Void

    internal var recordsToSave: [T.Record]? {
        get { return operation.recordsToSave }
        set { operation.recordsToSave = newValue }
    }

    internal var recordIDsToDelete: [T.RecordID]? {
        get { return operation.recordIDsToDelete }
        set { operation.recordIDsToDelete = newValue }
    }

    internal var savePolicy: T.RecordSavePolicy {
        get { return operation.savePolicy }
        set { operation.savePolicy = newValue }
    }

    internal var clientChangeTokenData: NSData? {
        get { return operation.clientChangeTokenData }
        set { operation.clientChangeTokenData = newValue }
    }

    internal var atomic: Bool {
        get { return operation.atomic }
        set { operation.atomic = newValue }
    }

    internal var perRecordProgressBlock: ((T.Record, Double) -> Void)? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    internal var perRecordCompletionBlock: ((T.Record?, NSError?) -> Void)? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    internal func setModifyRecordsCompletionBlock(block: ModifyRecordsCompletionBlock) {
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

extension CloudKit where T: CKModifyRecordsOperationType {

    public typealias ModifyRecordsCompletionBlock = ([T.Record]?, [T.RecordID]?) -> Void

    public var recordsToSave: [T.Record]? {
        get { return operation.recordsToSave }
        set {
            operation.recordsToSave = newValue
            addConfigureBlock { $0.recordsToSave = newValue }
        }
    }

    public var recordIDsToDelete: [T.RecordID]? {
        get { return operation.recordIDsToDelete }
        set {
            operation.recordIDsToDelete = newValue
            addConfigureBlock { $0.recordIDsToDelete = newValue }
        }
    }

    public var savePolicy: T.RecordSavePolicy {
        get { return operation.savePolicy }
        set {
            operation.savePolicy = newValue
            addConfigureBlock { $0.savePolicy = newValue }
        }
    }

    public var clientChangeTokenData: NSData? {
        get { return operation.clientChangeTokenData }
        set {
            operation.clientChangeTokenData = newValue
            addConfigureBlock { $0.clientChangeTokenData = newValue }
        }
    }

    public var atomic: Bool {
        get { return operation.atomic }
        set {
            operation.atomic = newValue
            addConfigureBlock { $0.atomic = newValue }
        }
    }

    public var perRecordProgressBlock: ((T.Record, Double) -> Void)? {
        get { return operation.perRecordProgressBlock }
        set {
            operation.perRecordProgressBlock = newValue
            addConfigureBlock { $0.perRecordProgressBlock = newValue }
        }
    }

    public var perRecordCompletionBlock: ((T.Record?, NSError?) -> Void)? {
        get { return operation.perRecordCompletionBlock }
        set {
            operation.perRecordCompletionBlock = newValue
            addConfigureBlock { $0.perRecordCompletionBlock = newValue }
        }
    }

    public func setModifyRecordsCompletionBlock(block: ModifyRecordsCompletionBlock) {
        addConfigureBlock { $0.setModifyRecordsCompletionBlock(block) }
    }
}

// MARK: - CKModifySubscriptionsOperation

extension CloudKitOperation where T: CKModifySubscriptionsOperationType {

    internal typealias ModifySubscriptionsCompletionBlock = ([T.Subscription]?, [String]?) -> Void

    internal var subscriptionsToSave: [T.Subscription]? {
        get { return operation.subscriptionsToSave }
        set { operation.subscriptionsToSave = newValue }
    }

    internal var subscriptionIDsToDelete: [String]? {
        get { return operation.subscriptionIDsToDelete }
        set { operation.subscriptionIDsToDelete = newValue }
    }

    internal func setModifySubscriptionsCompletionBlock(block: ModifySubscriptionsCompletionBlock) {
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

extension CloudKit where T: CKModifySubscriptionsOperationType {

    public typealias ModifySubscriptionsCompletionBlock = ([T.Subscription]?, [String]?) -> Void

    public var subscriptionsToSave: [T.Subscription]? {
        get { return operation.subscriptionsToSave }
        set {
            operation.subscriptionsToSave = newValue
            addConfigureBlock { $0.subscriptionsToSave = newValue }
        }
    }

    public var subscriptionIDsToDelete: [String]? {
        get { return operation.subscriptionIDsToDelete }
        set {
            operation.subscriptionIDsToDelete = newValue
            addConfigureBlock { $0.subscriptionIDsToDelete = newValue }
        }
    }

    public func setModifySubscriptionsCompletionBlock(block: ModifySubscriptionsCompletionBlock) {
        addConfigureBlock { $0.setModifySubscriptionsCompletionBlock(block) }
    }
}

// MARK: - CKQueryOperation

extension CloudKitOperation where T: CKQueryOperationType {

    internal typealias QueryCompletionBlock = T.QueryCursor? -> Void

    internal var query: T.Query? {
        get { return operation.query }
        set { operation.query = newValue }
    }

    internal var cursor: T.QueryCursor? {
        get { return operation.cursor }
        set { operation.cursor = newValue }
    }

    internal var zoneID: T.RecordZoneID? {
        get { return operation.zoneID }
        set { operation.zoneID = newValue }
    }

    internal var recordFetchedBlock: ((T.Record) -> Void)? {
        get { return operation.recordFetchedBlock }
        set { operation.recordFetchedBlock = newValue }
    }

    internal func setQueryCompletionBlock(block: QueryCompletionBlock) {
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

extension CloudKit where T: CKQueryOperationType {

    public typealias QueryCompletionBlock = T.QueryCursor? -> Void

    public var query: T.Query? {
        get { return operation.query }
        set {
            operation.query = newValue

        }
    }

    public var cursor: T.QueryCursor? {
        get { return operation.cursor }
        set {
            operation.cursor = newValue
            addConfigureBlock { $0.cursor = newValue }
        }
    }

    public var zoneID: T.RecordZoneID? {
        get { return operation.zoneID }
        set {
            operation.zoneID = newValue
            addConfigureBlock { $0.zoneID = newValue }
        }
    }

    public var recordFetchedBlock: ((T.Record) -> Void)? {
        get { return operation.recordFetchedBlock }
        set {
            operation.recordFetchedBlock = newValue
            addConfigureBlock { $0.recordFetchedBlock = newValue }
        }
    }

    public func setQueryCompletionBlock(block: QueryCompletionBlock) {
        addConfigureBlock { $0.setQueryCompletionBlock(block) }
    }
}








