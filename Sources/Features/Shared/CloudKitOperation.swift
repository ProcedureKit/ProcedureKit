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


// MARK: OPRCKOperation

class OPRCKOperation<T where T: NSOperation, T: CKOperationType>: ReachableOperation<T> {

    convenience init(operation op: T) {
        self.init(operation: op, connectivity: .AnyConnectionKind, reachability: Reachability.sharedInstance)
    }

    override init(operation op: T, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        super.init(operation: op, connectivity: connectivity, reachability: reachability)
        name = "OPRCKOperation<\(T.self)>"
    }
}

// MARK: - Cloud Kit Error Recovery

public class CloudKitRecovery<T where T: NSOperation, T: CKOperationType> {
    public typealias Payload = (Delay?, T)
    public typealias Handler = (NSError, Payload?) -> Payload?

    var defaultHandlers: [CKErrorCode: Handler]
    var customHandlers: [CKErrorCode: Handler]

    init() {
        defaultHandlers = [:]
        customHandlers = [:]
        addDefaultHandlers()
    }

    func recoverWithInfo(info: RetryFailureInfo<OPRCKOperation<T>>, recommended: (Delay?, OPRCKOperation<T>)?) -> (Delay?, OPRCKOperation<T>)? {

        // TODO: 
        // 1. Extract the latest/relevent NSError from the info
        // 2. Inspect it for CKError to get the CKErrorCode
        // 3. Lookup error handlers
        // 4. Prefer custom over default? 
        // 5. Consider how we might pass the result of the default into the custom
        // 6. Figure out how to work with OPRCKOperation<T> and handlers which expect T
        // 7. Execute (and return) the result of the error handler.

        return .None
    }

    func addDefaultHandlers() {

        // TODO:
        // 1. Add error handlers for as many CKErrorCodes as possible
    }

    func setDefaultHandlerForCode(code: CKErrorCode, handler: Handler) {
        defaultHandlers.updateValue(handler, forKey: code)
    }

    func setCustomHandlerForCode(code: CKErrorCode, handler: Handler) {
        customHandlers.updateValue(handler, forKey: code)
    }
}

// MARK: - CloudKitOperation

public class CloudKitOperation<T where T: NSOperation, T: CKOperationType>: RetryOperation<OPRCKOperation<T>> {

    public typealias ErrorHandler = CloudKitRecovery<T>.Handler

    let recovery: CloudKitRecovery<T>

    var operation: T {
        return current.operation
    }

    public convenience init(_ body: () -> T?) {
        self.init(generator: anyGenerator(body), connectivity: .AnyConnectionKind, reachability: Reachability.sharedInstance)
    }

    convenience init(connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType, _ body: () -> T?) {
        self.init(generator: anyGenerator(body), connectivity: .AnyConnectionKind, reachability: reachability)
    }

    init<G where G: GeneratorType, G.Element == T>(generator gen: G, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {

        // Creates a standard random delay between retries
        let strategy: WaitStrategy = .Random((0.1, 1.0))
        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }

        // Maps the generator to wrap the target operation.
        let generator = MapGenerator(gen) { OPRCKOperation(operation: $0, connectivity: connectivity, reachability: reachability) }

        // Creates a CloudKitRecovery object
        let _recovery = CloudKitRecovery<T>()

        // Creates a Retry Handler using the recovery object
        let handler: Handler = { info, payload in
            return _recovery.recoverWithInfo(info, recommended: payload)
        }

        recovery = _recovery
        super.init(maxCount: .None, delay: delay, generator: generator, retry: handler)
        name = "CloudKitOperation<\(T.self)>"
    }

    public func setErrorHandlerForCode(code: CKErrorCode, handler: ErrorHandler) {
        recovery.setCustomHandlerForCode(code, handler: handler)
    }
}

// MARK: - BatchedCloudKitOperation

class CloudKitOperationGenerator<T where T: NSOperation, T: CKOperationType>: GeneratorType {

    let connectivity: Reachability.Connectivity
    let reachability: SystemReachabilityType

    var generator: AnyGenerator<T>
    var more: Bool = true

    init<G where G: GeneratorType, G.Element == T>(generator: G, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        self.generator = anyGenerator(generator)
        self.connectivity = connectivity
        self.reachability = reachability
    }

    func next() -> CloudKitOperation<T>? {
        guard more else { return .None }
        return CloudKitOperation(generator: generator, connectivity: connectivity, reachability: reachability)
    }
}

public class BatchedCloudKitOperation<T where T: NSOperation, T: CKBatchedOperationType>: RepeatedOperation<CloudKitOperation<T>> {

    public var enableBatchProcessing: Bool
    var generator: CloudKitOperationGenerator<T>

    public var operation: T {
        return current.operation
    }

    public convenience init(enableBatchProcessing enable: Bool = true, _ body: () -> T?) {
        self.init(generator: anyGenerator(body), enableBatchProcessing: enable, connectivity: .AnyConnectionKind, reachability: Reachability.sharedInstance)
    }

    init<G where G: GeneratorType, G.Element == T>(generator gen: G, enableBatchProcessing enable: Bool = true, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        enableBatchProcessing = enable
        generator = CloudKitOperationGenerator(generator: gen, connectivity: connectivity, reachability: reachability)

        // Creates a standard fixed delay between batches (not reties)
        let strategy: WaitStrategy = .Fixed(0.1)
        let delay = MapGenerator(strategy.generator()) { Delay.By($0) }
        let tuple = TupleGenerator(primary: generator, secondary: delay)

        super.init(generator: anyGenerator(tuple))
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty, let cloudKitOperation = operation as? CloudKitOperation<T> {
            generator.more = enableBatchProcessing && cloudKitOperation.current.moreComing
        }
        super.operationDidFinish(operation, withErrors: errors)
    }
}







// MARK: - CKOperationType

extension OPRCKOperation where T: CKOperationType {

    var container: T.Container? {
        get { return operation.container }
        set { operation.container = newValue }
    }
}

extension CloudKitOperation where T: CKOperationType {

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

    var database: T.Database? {
        get { return operation.database }
        set { operation.database = newValue }
    }
}

extension CloudKitOperation where T: CKDatabaseOperationType {

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

    var previousServerChangeToken: T.ServerChangeToken? {
        get { return operation.previousServerChangeToken }
        set { operation.previousServerChangeToken = newValue }
    }
}

extension CloudKitOperation where T: CKPreviousServerChangeToken {

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

    var resultsLimit: Int {
        get { return operation.resultsLimit }
        set { operation.resultsLimit = newValue }
    }
}

extension CloudKitOperation where T: CKResultsLimit {

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

    var moreComing: Bool {
        return operation.moreComing
    }
}

extension CloudKitOperation where T: CKMoreComing {

    public var moreComing: Bool {
        return operation.moreComing
    }
}

// MARK: - CKDesiredKeys

extension OPRCKOperation where T: CKDesiredKeys {

    var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set { operation.desiredKeys = newValue }
    }
}

extension CloudKitOperation where T: CKDesiredKeys {

    public var desiredKeys: [String]? {
        get { return operation.desiredKeys }
        set {
            operation.desiredKeys = newValue
            addConfigureBlock { $0.desiredKeys = newValue }
        }
    }
}

// MARK: - CKDiscoverAllContactsOperation

extension OPRCKOperation where T: CKDiscoverAllContactsOperationType {

    func setDiscoverAllContactsCompletionBlock(block: CloudKitOperation<T>.DiscoverAllContactsCompletionBlock) {
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

extension CloudKitOperation where T: CKDiscoverAllContactsOperationType {

    public typealias DiscoverAllContactsCompletionBlock = [T.DiscoveredUserInfo]? -> Void

    public func setDiscoverAllContactsCompletionBlock(block: DiscoverAllContactsCompletionBlock) {
        addConfigureBlock { $0.setDiscoverAllContactsCompletionBlock(block) }
    }
}

// MARK: - CKDiscoverUserInfosOperation

extension OPRCKOperation where T: CKDiscoverUserInfosOperationType {

    var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set { operation.emailAddresses = newValue }
    }

    var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set { operation.userRecordIDs = newValue }
    }

    func setDiscoverUserInfosCompletionBlock(block: CloudKitOperation<T>.DiscoverUserInfosCompletionBlock) {
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

extension CloudKitOperation where T: CKDiscoverUserInfosOperationType {

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

extension OPRCKOperation where T: CKFetchNotificationChangesOperationType {

    var notificationChangedBlock: CloudKitOperation<T>.FetchNotificationChangesChangedBlock? {
        get { return operation.notificationChangedBlock }
        set { operation.notificationChangedBlock = newValue }
    }

    func setFetchNotificationChangesCompletionBlock(block: CloudKitOperation<T>.FetchNotificationChangesCompletionBlock) {

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

extension CloudKitOperation where T: CKFetchNotificationChangesOperationType {

    public typealias FetchNotificationChangesChangedBlock = T.Notification -> Void
    public typealias FetchNotificationChangesCompletionBlock = T.ServerChangeToken? -> Void

    public var notificationChangedBlock: FetchNotificationChangesChangedBlock? {
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

extension BatchedCloudKitOperation where T: CKFetchNotificationChangesOperationType {

    public var notificationChangedBlock: CloudKitOperation<T>.FetchNotificationChangesChangedBlock? {
        get { return operation.notificationChangedBlock }
        set {
            operation.notificationChangedBlock = newValue
            addConfigureBlock { $0.notificationChangedBlock = newValue }
        }
    }

    public func setFetchNotificationChangesCompletionBlock(block: CloudKitOperation<T>.FetchNotificationChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchNotificationChangesCompletionBlock(block) }
    }
}

// MARK: - CKMarkNotificationsReadOperation

extension OPRCKOperation where T: CKMarkNotificationsReadOperationType {

    var notificationIDs: [T.NotificationID] {
        get { return operation.notificationIDs }
        set { operation.notificationIDs = newValue }
    }

    func setMarkNotificationReadCompletionBlock(block: CloudKitOperation<T>.MarkNotificationReadCompletionBlock) {
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

extension CloudKitOperation where T: CKMarkNotificationsReadOperationType {

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

extension OPRCKOperation where T: CKModifyBadgeOperationType {

    var badgeValue: Int {
        get { return operation.badgeValue }
        set { operation.badgeValue = newValue }
    }

    func setModifyBadgeCompletionBlock(block: CloudKitOperation<T>.ModifyBadgeCompletionBlock) {
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

extension CloudKitOperation where T: CKModifyBadgeOperationType {

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

extension OPRCKOperation where T: CKFetchRecordChangesOperationType {

    var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set { operation.recordZoneID = newValue }
    }

    var recordChangedBlock: CloudKitOperation<T>.FetchRecordChangesRecordChangedBlock? {
        get { return operation.recordChangedBlock }
        set { operation.recordChangedBlock = newValue }
    }

    var recordWithIDWasDeletedBlock: CloudKitOperation<T>.FetchRecordChangesRecordDeletedBlock? {
        get { return operation.recordWithIDWasDeletedBlock }
        set { operation.recordWithIDWasDeletedBlock = newValue }
    }

    func setFetchRecordChangesCompletionBlock(block: CloudKitOperation<T>.FetchRecordChangesCompletionBlock) {
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

extension CloudKitOperation where T: CKFetchRecordChangesOperationType {

    public typealias FetchRecordChangesRecordChangedBlock = T.Record -> Void
    public typealias FetchRecordChangesRecordDeletedBlock = T.RecordID -> Void
    public typealias FetchRecordChangesCompletionBlock = (T.ServerChangeToken?, NSData?) -> Void

    public var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set {
            operation.recordZoneID = newValue
            addConfigureBlock { $0.recordZoneID = newValue }
        }
    }

    public var recordChangedBlock: FetchRecordChangesRecordChangedBlock? {
        get { return operation.recordChangedBlock }
        set {
            operation.recordChangedBlock = newValue
            addConfigureBlock { $0.recordChangedBlock = newValue }
        }
    }

    public var recordWithIDWasDeletedBlock: FetchRecordChangesRecordDeletedBlock? {
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

extension BatchedCloudKitOperation where T: CKFetchRecordChangesOperationType {

    public var recordZoneID: T.RecordZoneID {
        get { return operation.recordZoneID }
        set {
            operation.recordZoneID = newValue
            addConfigureBlock { $0.recordZoneID = newValue }
        }
    }

    public var recordChangedBlock: CloudKitOperation<T>.FetchRecordChangesRecordChangedBlock? {
        get { return operation.recordChangedBlock }
        set {
            operation.recordChangedBlock = newValue
            addConfigureBlock { $0.recordChangedBlock = newValue }
        }
    }

    public var recordWithIDWasDeletedBlock: CloudKitOperation<T>.FetchRecordChangesRecordDeletedBlock? {
        get { return operation.recordWithIDWasDeletedBlock }
        set {
            operation.recordWithIDWasDeletedBlock = newValue
            addConfigureBlock { $0.recordWithIDWasDeletedBlock = newValue }
        }
    }

    public func setFetchRecordChangesCompletionBlock(block: CloudKitOperation<T>.FetchRecordChangesCompletionBlock) {
        addConfigureBlock { $0.setFetchRecordChangesCompletionBlock(block) }
    }
}

// MARK: - CKFetchRecordZonesOperation

extension OPRCKOperation where T: CKFetchRecordZonesOperationType {

    var recordZoneIDs: [T.RecordZoneID]? {
        get { return operation.recordZoneIDs }
        set { operation.recordZoneIDs = newValue }
    }

    func setFetchRecordZonesCompletionBlock(block: CloudKitOperation<T>.FetchRecordZonesCompletionBlock) {
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

extension CloudKitOperation where T: CKFetchRecordZonesOperationType {

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

extension OPRCKOperation where T: CKFetchRecordsOperationType {

    var recordIDs: [T.RecordID]? {
        get { return operation.recordIDs }
        set { operation.recordIDs = newValue }
    }

    var perRecordProgressBlock: CloudKitOperation<T>.FetchRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    var perRecordCompletionBlock: CloudKitOperation<T>.FetchRecordsPerRecordCompletionBlock? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    func setFetchRecordsCompletionBlock(block: CloudKitOperation<T>.FetchRecordsCompletionBlock) {
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

extension CloudKitOperation where T: CKFetchRecordsOperationType {

    public typealias FetchRecordsPerRecordProgressBlock = (T.RecordID, Double) -> Void
    public typealias FetchRecordsPerRecordCompletionBlock = (T.Record?, T.RecordID?, NSError?) -> Void
    public typealias FetchRecordsCompletionBlock = [T.RecordID: T.Record]? -> Void

    public var recordIDs: [T.RecordID]? {
        get { return operation.recordIDs }
        set {
            operation.recordIDs = newValue
            addConfigureBlock { $0.recordIDs = newValue }
        }
    }

    public var perRecordProgressBlock: FetchRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set {
            operation.perRecordProgressBlock = newValue
            addConfigureBlock { $0.perRecordProgressBlock = newValue }
        }
    }

    public var perRecordCompletionBlock: FetchRecordsPerRecordCompletionBlock? {
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

extension OPRCKOperation where T: CKFetchSubscriptionsOperationType {

    var subscriptionIDs: [String]? {
        get { return operation.subscriptionIDs }
        set { operation.subscriptionIDs = newValue }
    }

    func setFetchSubscriptionCompletionBlock(block: CloudKitOperation<T>.FetchSubscriptionCompletionBlock) {
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

extension CloudKitOperation where T: CKFetchSubscriptionsOperationType {

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

extension OPRCKOperation where T: CKModifyRecordZonesOperationType {

    var recordZonesToSave: [T.RecordZone]? {
        get { return operation.recordZonesToSave }
        set { operation.recordZonesToSave = newValue }
    }

    var recordZoneIDsToDelete: [T.RecordZoneID]? {
        get { return operation.recordZoneIDsToDelete }
        set { operation.recordZoneIDsToDelete = newValue }
    }

    func setModifyRecordZonesCompletionBlock(block: CloudKitOperation<T>.ModifyRecordZonesCompletionBlock) {
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

extension CloudKitOperation where T: CKModifyRecordZonesOperationType {

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

extension OPRCKOperation where T: CKModifyRecordsOperationType {

    typealias ModifyRecordsCompletionBlock = ([T.Record]?, [T.RecordID]?) -> Void

    var recordsToSave: [T.Record]? {
        get { return operation.recordsToSave }
        set { operation.recordsToSave = newValue }
    }

    var recordIDsToDelete: [T.RecordID]? {
        get { return operation.recordIDsToDelete }
        set { operation.recordIDsToDelete = newValue }
    }

    var savePolicy: T.RecordSavePolicy {
        get { return operation.savePolicy }
        set { operation.savePolicy = newValue }
    }

    var clientChangeTokenData: NSData? {
        get { return operation.clientChangeTokenData }
        set { operation.clientChangeTokenData = newValue }
    }

    var atomic: Bool {
        get { return operation.atomic }
        set { operation.atomic = newValue }
    }

    var perRecordProgressBlock: CloudKitOperation<T>.ModifyRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    var perRecordCompletionBlock: CloudKitOperation<T>.ModifyRecordsPerRecordCompletionBlock? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    func setModifyRecordsCompletionBlock(block: CloudKitOperation<T>.ModifyRecordsCompletionBlock) {
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

extension CloudKitOperation where T: CKModifyRecordsOperationType {

    public typealias ModifyRecordsPerRecordProgressBlock = (T.Record, Double) -> Void
    public typealias ModifyRecordsPerRecordCompletionBlock = (T.Record?, NSError?) -> Void
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

    public var perRecordProgressBlock: ModifyRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set {
            operation.perRecordProgressBlock = newValue
            addConfigureBlock { $0.perRecordProgressBlock = newValue }
        }
    }

    public var perRecordCompletionBlock: ModifyRecordsPerRecordCompletionBlock? {
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

extension OPRCKOperation where T: CKModifySubscriptionsOperationType {

    var subscriptionsToSave: [T.Subscription]? {
        get { return operation.subscriptionsToSave }
        set { operation.subscriptionsToSave = newValue }
    }

    var subscriptionIDsToDelete: [String]? {
        get { return operation.subscriptionIDsToDelete }
        set { operation.subscriptionIDsToDelete = newValue }
    }

    func setModifySubscriptionsCompletionBlock(block: CloudKitOperation<T>.ModifySubscriptionsCompletionBlock) {
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

extension CloudKitOperation where T: CKModifySubscriptionsOperationType {

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

extension OPRCKOperation where T: CKQueryOperationType {

    var query: T.Query? {
        get { return operation.query }
        set { operation.query = newValue }
    }

    var cursor: T.QueryCursor? {
        get { return operation.cursor }
        set { operation.cursor = newValue }
    }

    var zoneID: T.RecordZoneID? {
        get { return operation.zoneID }
        set { operation.zoneID = newValue }
    }

    var recordFetchedBlock: ((T.Record) -> Void)? {
        get { return operation.recordFetchedBlock }
        set { operation.recordFetchedBlock = newValue }
    }

    func setQueryCompletionBlock(block: CloudKitOperation<T>.QueryCompletionBlock) {
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

extension CloudKitOperation where T: CKQueryOperationType {

    public typealias QueryCompletionBlock = T.QueryCursor? -> Void

    public var query: T.Query? {
        get { return operation.query }
        set {
            operation.query = newValue
            addConfigureBlock { $0.query = newValue }
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








