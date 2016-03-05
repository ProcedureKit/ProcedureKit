//
//  CloudKitOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CloudKit

/**

 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Operation types.

*/
public protocol CKOperationType: class {

    /// The type of the CloudKit Container
    typealias Container

    /// The type of the CloudKit ServerChangeToken
    typealias ServerChangeToken

    /// The type of the CloudKit Notification
    typealias Notification

    /// The type of the CloudKit RecordZone
    typealias RecordZone

    /// The type of the CloudKit Record
    typealias Record

    /// The type of the CloudKit Subscription
    typealias Subscription

    /// The type of the CloudKit RecordSavePolicy
    typealias RecordSavePolicy

    /// The type of the CloudKit DiscoveredUserInfo
    typealias DiscoveredUserInfo

    /// The type of the CloudKit Query
    typealias Query

    /// The type of the CloudKit QueryCursor
    typealias QueryCursor

    /// The type of the CloudKit RecordZoneID
    typealias RecordZoneID: Hashable

    /// The type of the CloudKit NotificationID
    typealias NotificationID: Hashable

    /// The type of the CloudKit RecordID
    typealias RecordID: Hashable

    /// - returns the CloudKit Container
    var container: Container? { get set }
}

/**

 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Database Operation types.

 */
public protocol CKDatabaseOperationType: CKOperationType {

    /// The type of the CloudKit Database
    typealias Database

    /// - returns: the CloudKit Database
    var database: Database? { get set }
}

/**

 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Operation's which return the previous sever change
 token.

 */
public protocol CKPreviousServerChangeToken: CKOperationType {

    /// - returns: the previous sever change token
    var previousServerChangeToken: ServerChangeToken? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CloudKit Operation's which return a results limit.

 */
public protocol CKResultsLimit: CKOperationType {

    /// - returns: the results limit
    var resultsLimit: Int { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CloudKit Operation's which return a flag for more coming.

 */
public protocol CKMoreComing: CKOperationType {

    /// - returns: whether there are more results on the server
    var moreComing: Bool { get }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CloudKit Operation's which have desired keys.

 */
public protocol CKDesiredKeys: CKOperationType {

    /// - returns: the desired keys to fetch or fetched.
    var desiredKeys: [String]? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CloudKit batched operation types.

 */
public protocol CKBatchedOperationType: CKResultsLimit, CKMoreComing { }

/**

 A generic protocol which exposes the properties used by
 Apple's CloudKit fetched operation types.

 */
public typealias CKFetchOperationType = protocol<CKPreviousServerChangeToken, CKBatchedOperationType>

/**

 A generic protocol which exposes the properties used by
 Apple's CKDiscoverAllContactsOperation.

 */
public protocol CKDiscoverAllContactsOperationType: CKOperationType {

    /// - returns: the completion block used for discovering all contacts.
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKDiscoverUserInfosOperation.

 */
public protocol CKDiscoverUserInfosOperationType: CKOperationType {

    /// - returns: the email addresses used in discovery
    var emailAddresses: [String]? { get set }

    /// - returns: the user record IDs
    var userRecordIDs: [RecordID]? { get set }

    /// - returns: the completion block used for discovering user infos
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKFetchNotificationChangesOperation.

 */
public protocol CKFetchNotificationChangesOperationType: CKFetchOperationType {

    /// - returns: the block invoked when there are notification changes.
    var notificationChangedBlock: ((Notification) -> Void)? { get set }

    /// - returns: the completion block used for notification changes.
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKMarkNotificationsReadOperation.

 */
public protocol CKMarkNotificationsReadOperationType: CKOperationType {

    /// - returns: the notification IDs
    var notificationIDs: [NotificationID] { get set }

    /// - returns: the completion block used when marking notifications
    var markNotificationsReadCompletionBlock: (([NotificationID]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKModifyBadgeOperation.

 */
public protocol CKModifyBadgeOperationType: CKOperationType {

    /// - returns: the badge value
    var badgeValue: Int { get set }

    /// - returns: the completion block used
    var modifyBadgeCompletionBlock: ((NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKFetchRecordChangesOperation.

 */
public protocol CKFetchRecordChangesOperationType: CKDatabaseOperationType, CKFetchOperationType, CKDesiredKeys {

    /// - returns: the record zone ID whcih will fetch changes
    var recordZoneID: RecordZoneID { get set }

    /// - returns: a block for when a record is changed
    var recordChangedBlock: ((Record) -> Void)? { get set }

    /// - returns: a block for when a record with ID
    var recordWithIDWasDeletedBlock: ((RecordID) -> Void)? { get set }

    /// - returns: the completion for fetching records
    var fetchRecordChangesCompletionBlock: ((ServerChangeToken?, NSData?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKFetchRecordZonesOperation.

 */
public protocol CKFetchRecordZonesOperationType: CKDatabaseOperationType {

    /// - returns: the record zone IDs which will be fetched
    var recordZoneIDs: [RecordZoneID]? { get set }

    /// - returns: the completion block for fetching record zones
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKFetchRecordsOperation.

 */
public protocol CKFetchRecordsOperationType: CKDatabaseOperationType, CKDesiredKeys {

    /// - returns: the record IDs
    var recordIDs: [RecordID]? { get set }

    /// - returns: a per record progress block
    var perRecordProgressBlock: ((RecordID, Double) -> Void)? { get set }

    /// - returns: a per record completion block
    var perRecordCompletionBlock: ((Record?, RecordID?, NSError?) -> Void)? { get set }

    /// - returns: the fetch record completion block
    var fetchRecordsCompletionBlock: (([RecordID: Record]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKFetchSubscriptionsOperation.

 */
public protocol CKFetchSubscriptionsOperationType: CKDatabaseOperationType {

    /// - returns: the subscription IDs
    var subscriptionIDs: [String]? { get set }

    /// - returns: the fetch subscription completion block
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKModifyRecordZonesOperation.

 */
public protocol CKModifyRecordZonesOperationType: CKDatabaseOperationType {

    /// - returns: the record zones to save
    var recordZonesToSave: [RecordZone]? { get set }

    /// - returns: the record zone IDs to delete
    var recordZoneIDsToDelete: [RecordZoneID]? { get set }

    /// - returns: the modify record zones completion block
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKModifyRecordsOperation.

 */
public protocol CKModifyRecordsOperationType: CKDatabaseOperationType {

    /// - returns: the records to save
    var recordsToSave: [Record]? { get set }

    /// - returns: the record IDs to delete
    var recordIDsToDelete: [RecordID]? { get set }

    /// - returns: the save policy
    var savePolicy: RecordSavePolicy { get set }

    /// - returns: the client change token data
    var clientChangeTokenData: NSData? { get set }

    /// - returns: a flag for atomic changes
    var atomic: Bool { get set }

    /// - returns: a per record progress block
    var perRecordProgressBlock: ((Record, Double) -> Void)? { get set }

    /// - returns: a per record completion block
    var perRecordCompletionBlock: ((Record?, NSError?) -> Void)? { get set }

    /// - returns: the modify records completion block
    var modifyRecordsCompletionBlock: (([Record]?, [RecordID]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKModifySubscriptionsOperation.

 */
public protocol CKModifySubscriptionsOperationType: CKDatabaseOperationType {

    /// - returns: the subscriptions to save
    var subscriptionsToSave: [Subscription]? { get set }

    /// - returns: the subscriptions IDs to delete
    var subscriptionIDsToDelete: [String]? { get set }

    /// - returns: the modify subscription completion block
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, NSError?) -> Void)? { get set }
}

/**

 A generic protocol which exposes the properties used by
 Apple's CKQueryOperation.

 */
public protocol CKQueryOperationType: CKDatabaseOperationType, CKResultsLimit, CKDesiredKeys {

    /// - returns: the query to execute
    var query: Query? { get set }

    /// - returns: the query cursor
    var cursor: QueryCursor? { get set }

    /// - returns: the zone ID
    var zoneID: RecordZoneID? { get set }

    /// - returns: a record fetched block
    var recordFetchedBlock: ((Record) -> Void)? { get set }

    /// - returns: the query completion block
    var queryCompletionBlock: ((QueryCursor?, NSError?) -> Void)? { get set }
}

/**

 An extension to make CKOperation to conform to the
 CKOperationType.

 */
extension CKOperation: CKOperationType {

    /// The Container is a CKContainer
    public typealias Container = CKContainer

    /// The ServerChangeToken is a CKServerChangeToken
    public typealias ServerChangeToken = CKServerChangeToken

    /// The DiscoveredUserInfo is a CKDiscoveredUserInfo
    public typealias DiscoveredUserInfo = CKDiscoveredUserInfo

    /// The RecordZone is a CKRecordZone
    public typealias RecordZone = CKRecordZone

    /// The RecordZoneID is a CKRecordZoneID
    public typealias RecordZoneID = CKRecordZoneID

    /// The Notification is a CKNotification
    public typealias Notification = CKNotification

    /// The NotificationID is a CKNotificationID
    public typealias NotificationID = CKNotificationID

    /// The Record is a CKRecord
    public typealias Record = CKRecord

    /// The RecordID is a CKRecordID
    public typealias RecordID = CKRecordID

    /// The Subscription is a CKSubscription
    public typealias Subscription = CKSubscription

    /// The RecordSavePolicy is a CKRecordSavePolicy
    public typealias RecordSavePolicy = CKRecordSavePolicy

    /// The Query is a CKQuery
    public typealias Query = CKQuery

    /// The QueryCursor is a CKQueryCursor
    public typealias QueryCursor = CKQueryCursor
}

/**

 An extension to make CKDatabaseOperation to conform to the
 CKDatabaseOperationType.

 */
extension CKDatabaseOperation: CKDatabaseOperationType {

    /// The Database is a CKDatabase
    public typealias Database = CKDatabase
}

/// Extension to have CKDiscoverAllContactsOperation conform to CKDiscoverAllContactsOperationType
#if !os(tvOS)
extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationType { }
#endif

/// Extension to have CKDiscoverUserInfosOperation conform to CKDiscoverUserInfosOperationType
extension CKDiscoverUserInfosOperation: CKDiscoverUserInfosOperationType { }

/// Extension to have CKFetchNotificationChangesOperation conform to CKFetchNotificationChangesOperationType
extension CKFetchNotificationChangesOperation: CKFetchNotificationChangesOperationType   { }

/// Extension to have CKMarkNotificationsReadOperation conform to CKMarkNotificationsReadOperationType
extension CKMarkNotificationsReadOperation: CKMarkNotificationsReadOperationType { }

/// Extension to have CKModifyBadgeOperation conform to CKModifyBadgeOperationType
extension CKModifyBadgeOperation: CKModifyBadgeOperationType { }

/// Extension to have CKFetchRecordChangesOperation conform to CKFetchRecordChangesOperationType
extension CKFetchRecordChangesOperation: CKFetchRecordChangesOperationType { }

/// Extension to have CKFetchRecordZonesOperation conform to CKFetchRecordZonesOperationType
extension CKFetchRecordZonesOperation: CKFetchRecordZonesOperationType { }

/// Extension to have CKFetchRecordsOperation conform to CKFetchRecordsOperationType
extension CKFetchRecordsOperation: CKFetchRecordsOperationType { }

/// Extension to have CKFetchSubscriptionsOperation conform to CKFetchSubscriptionsOperationType
extension CKFetchSubscriptionsOperation: CKFetchSubscriptionsOperationType { }

/// Extension to have CKModifyRecordZonesOperation conform to CKModifyRecordZonesOperationType
extension CKModifyRecordZonesOperation: CKModifyRecordZonesOperationType { }

/// Extension to have CKModifyRecordsOperation conform to CKModifyRecordsOperationType
extension CKModifyRecordsOperation: CKModifyRecordsOperationType { }

/// Extension to have CKModifySubscriptionsOperation conform to CKModifySubscriptionsOperationType
extension CKModifySubscriptionsOperation: CKModifySubscriptionsOperationType { }

/// Extension to have CKQueryOperation conform to CKQueryOperationType
extension CKQueryOperation: CKQueryOperationType { }


// MARK: - OPRCKOperation

public class OPRCKOperation<T where T: NSOperation, T: CKOperationType>: ReachableOperation<T> {

    convenience init(operation op: T) {
        self.init(operation: op, connectivity: .AnyConnectionKind, reachability: ReachabilityManager(DeviceReachability()))
    }

    override init(operation op: T, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType) {
        super.init(operation: op, connectivity: connectivity, reachability: reachability)
        name = "OPRCKOperation<\(T.self)>"
    }
}

// MARK: - Cloud Kit Error Recovery

public class CloudKitRecovery<T where T: NSOperation, T: CKOperationType> {
    public typealias V = OPRCKOperation<T>

    public typealias ErrorResponse = (delay: Delay?, configure: V -> Void)
    public typealias Handler = (error: NSError, log: LoggerType, suggested: ErrorResponse) -> ErrorResponse?

    typealias Payload = (Delay?, V)

    var defaultHandlers: [CKErrorCode: Handler]
    var customHandlers: [CKErrorCode: Handler]

    init() {
        defaultHandlers = [:]
        customHandlers = [:]
        addDefaultHandlers()
    }

    internal func recoverWithInfo(info: RetryFailureInfo<V>, payload: Payload) -> ErrorResponse? {

        guard let (code, error) = cloudKitErrorsFromInfo(info) else { return .None }

        // We take the payload, if not nil, and return the delay, and configuration block
        let suggestion: ErrorResponse = (payload.0, info.configure )
        var response: ErrorResponse? = .None

        response = defaultHandlers[code]?(error: error, log: info.log, suggested: suggestion)
        response = customHandlers[code]?(error: error, log: info.log, suggested: response ?? suggestion)

        return response

        // 5. Consider how we might pass the result of the default into the custom
    }

    func addDefaultHandlers() {

        let exit: Handler = { error, log, _ in
            log.fatal("Exiting due to CloudKit Error: \(error)")
            return .None
        }

        let retry: Handler = { error, log, suggestion in
            if let interval = (error.userInfo[CKErrorRetryAfterKey] as? NSNumber).map({ $0.doubleValue }) {
                return (Delay.By(interval), suggestion.configure)
            }
            return suggestion
        }

        setDefaultHandlerForCode(.InternalError, handler: exit)
        setDefaultHandlerForCode(.MissingEntitlement, handler: exit)
        setDefaultHandlerForCode(.InvalidArguments, handler: exit)
        setDefaultHandlerForCode(.ServerRejectedRequest, handler: exit)
        setDefaultHandlerForCode(.AssetFileNotFound, handler: exit)
        setDefaultHandlerForCode(.IncompatibleVersion, handler: exit)
        setDefaultHandlerForCode(.ConstraintViolation, handler: exit)
        setDefaultHandlerForCode(.BadDatabase, handler: exit)
        setDefaultHandlerForCode(.QuotaExceeded, handler: exit)
        setDefaultHandlerForCode(.OperationCancelled, handler: exit)

        setDefaultHandlerForCode(.NetworkUnavailable, handler: retry)
        setDefaultHandlerForCode(.NetworkFailure, handler: retry)
        setDefaultHandlerForCode(.ServiceUnavailable, handler: retry)
        setDefaultHandlerForCode(.RequestRateLimited, handler: retry)
        setDefaultHandlerForCode(.AssetFileModified, handler: retry)
        setDefaultHandlerForCode(.BatchRequestFailed, handler: retry)
        setDefaultHandlerForCode(.ZoneBusy, handler: retry)
    }

    func setDefaultHandlerForCode(code: CKErrorCode, handler: Handler) {
        defaultHandlers.updateValue(handler, forKey: code)
    }

    func setCustomHandlerForCode(code: CKErrorCode, handler: Handler) {
        customHandlers.updateValue(handler, forKey: code)
    }

    internal func cloudKitErrorsFromInfo(info: RetryFailureInfo<OPRCKOperation<T>>) -> (code: CKErrorCode, error: NSError)? {
        let mapped: [(CKErrorCode, NSError)] = info.errors.flatMap { error in
            let error = error as NSError
            if error.domain == CKErrorDomain, let code = CKErrorCode(rawValue: error.code) {
                return (code, error)
            }
            return .None
        }
        return mapped.first
    }
}

// MARK: - CloudKitOperation

/**
 # CloudKitOperation

 CloudKitOperation is a generic operation which can be used to configure and schedule
 the execution of Apple's CKOperation subclasses.

 ## Generics

 CloudKitOperation is generic over the type of the CKOperation. See Apple's documentation
 on their CloudKit NSOperation classes.

 ## Initialization

 CloudKitOperation is initialized with a block which should return an instance of the
 required operation. Note that some CKOperation subclasses have static methods to
 return standard instances. Given Swift's treatment of trailing closure arguments, this
 means that the following is a standard initialization pattern:

 ```swift
 let operation = CloudKitOperation { CKFetchRecordZonesOperation.fetchAllRecordZonesOperation() }
 ```

 This works because, the initializer only takes a trailing closure. The closure receives no arguments
 and is only one line, so the return is not needed.

 ## Configuration

 Most CKOperation subclasses need various properties setting before they are added to a queue. Sometimes
 these can be done via their initializers. However, it is also possible to set the properties directly.
 This can be done directly onto the CloudKitOperation. For example, given the above:

 ```swift
 let container = CKContainer.defaultContainer()
 operation.container = container
 operation.database = container.privateCloudDatabase
 ```

 This will set the container and the database through the CloudKitOperation into the wrapped CKOperation
 instance.

 ## Completion

 All CKOperation subclasses have a completion block which should be set. This completion block receives
 the "results" of the operation, and an `NSError` argument. However, CloudKitOperation features its own
 semi-automatic error handling system. Therefore, the only completion block needed is one which receives
 the "results". Essentially, all that is needed is to manage the happy path of the operation. For all
 CKOperation subclasses, this can be configured directly on the CloudKitOperation instance, using a
 pattern of `setOperationKindCompletionBlock { }`. For example, given the above:

```swift
 operation.setFetchRecordZonesCompletionBlock { zonesByID in
    // Do something with the zonesByID
 }
```

Note, that for the automatic error handling to kick in, the happy path must be set (as above).

 ### Error Handling

 When the completion block is set as above, any errors receives from the CKOperation subclass are
 intercepted, and instead of the provided block being executed, the operation finsihes with an error.

 However, CloudKitOperation is a subclass of RetryOperation, which is actually a GroupOperation subclass,
 and when a child operation finishes with an error, RetryOperation will consult its error handler, and
 attempt to retry the operation.

 In the case of CloudKitOperation, the error handler, which is configured internally has automatic
 support for many common error kinds. When the CKOperation receives an error, the CKErrorCode is extracted,
 and the handler consults a CloudKitRecovery instance to check for a particular way to handle that error
 code. In some cases, this will result in a tuple being returned. The tuple is an optional Delay, and
 a new instance of the CKOperation class.

 This is why the initializer takes a block which returns an instance of the CKOperation subclass, rather
 than just an instance directly. In addition, any configuration set on the operation is captured and
 applied again to new instances of the CKOperation subclass.

 The delay is used to automatically respect any wait periods returned in the CloudKit NSError object. If
 none are given, a random time delay between 0.1 and 1.0 seconds is used.

 If the error recovery does not have a handler, or the handler returns nil (no tuple), the CloudKitOperation
 will finish (with the errors).

 ### Custom Error Handling

 To provide bespoke error handling, further configure the CloudKitOperation by calling setErrorHandlerForCode.
 For example:

 ```swift
 operation.setErrorHandlerForCode(.PartialFailure) { error, log, suggested in
    return suggested
 }
 ```

 Note that the error handler receives the received error, a logger object, and the suggested tuple, which
 could be modified before being returned. Alternatively, return nil to not retry.

*/
public final class CloudKitOperation<T where T: NSOperation, T: CKOperationType>: RetryOperation<OPRCKOperation<T>> {

    public typealias ErrorHandler = CloudKitRecovery<T>.Handler

    let recovery: CloudKitRecovery<T>

    var operation: T {
        return current.operation
    }

    public convenience init(_ body: () -> T?) {
        self.init(generator: anyGenerator(body), connectivity: .AnyConnectionKind, reachability: ReachabilityManager(DeviceReachability()))
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
            guard let (delay, configure) = _recovery.recoverWithInfo(info, payload: payload) else { return .None }
            let (_, operation) = payload
            configure(operation)
            return (delay, operation)
        }

        recovery = _recovery
        super.init(delay: delay, generator: generator, retry: handler)
        name = "CloudKitOperation<\(T.self)>"
    }

    public func setErrorHandlerForCode(code: CKErrorCode, handler: ErrorHandler) {
        recovery.setCustomHandlerForCode(code, handler: handler)
    }

    override func childOperation(child: NSOperation, didFinishWithErrors errors: [ErrorType]) {
        if !(child is OPRCKOperation<T>) {
            super.childOperation(child, didFinishWithErrors: errors)
        }
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
        self.init(generator: anyGenerator(body), enableBatchProcessing: enable, connectivity: .AnyConnectionKind, reachability: ReachabilityManager(DeviceReachability()))
    }

    convenience init(enableBatchProcessing enable: Bool = true, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: SystemReachabilityType, _ body: () -> T?) {
        self.init(generator: anyGenerator(body), enableBatchProcessing: enable, connectivity: connectivity, reachability: reachability)
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

    public override func willFinishOperation(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty, let cloudKitOperation = operation as? CloudKitOperation<T> {
            generator.more = enableBatchProcessing && cloudKitOperation.current.moreComing
        }
        super.willFinishOperation(operation, withErrors: errors)
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

    var database: T.Database? {
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

// MARK: - CKPreviousServerChangeToken

extension OPRCKOperation where T: CKPreviousServerChangeToken {

    var previousServerChangeToken: T.ServerChangeToken? {
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

// MARK: - CKResultsLimit

extension OPRCKOperation where T: CKResultsLimit {

    var resultsLimit: Int {
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

// MARK: - CKMoreComing

extension OPRCKOperation where T: CKMoreComing {

    var moreComing: Bool {
        return operation.moreComing
    }
}

extension CloudKitOperation where T: CKMoreComing {

    /// - returns: a flag to indicate whether there are more results on the server
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

    /// - returns: the desired keys
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
    public var atomic: Bool {
        get { return operation.atomic }
        set {
            operation.atomic = newValue
            addConfigureBlock { $0.atomic = newValue }
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

    var recordFetchedBlock: CloudKitOperation<T>.QueryRecordFetchedBlock? {
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






