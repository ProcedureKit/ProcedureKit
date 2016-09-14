//
//  CloudKitInterface.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/03/2016.
//
//

import Foundation
import CloudKit

// swiftlint:disable file_length

/**
 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Operation types.
 */
public protocol CKOperationType: class {

    /// The type of the CloudKit Container
    associatedtype Container

    /// The type of the CloudKit ServerChangeToken
    associatedtype ServerChangeToken

    /// The type of the CloudKit Notification
    associatedtype Notification

    /// The type of the CloudKit RecordZone
    associatedtype RecordZone

    /// The type of the CloudKit Record
    associatedtype Record

    /// The type of the CloudKit Subscription
    associatedtype Subscription

    /// The type of the CloudKit RecordSavePolicy
    associatedtype RecordSavePolicy

    /// The type of the CloudKit DiscoveredUserInfo
    associatedtype DiscoveredUserInfo

    /// The type of the CloudKit Query
    associatedtype Query

    /// The type of the CloudKit QueryCursor
    associatedtype QueryCursor

    /// The type of the CloudKit RecordZoneID
    associatedtype RecordZoneID: Hashable

    /// The type of the CloudKit NotificationID
    associatedtype NotificationID: Hashable

    /// The type of the CloudKit RecordID
    associatedtype RecordID: Hashable

    /// - returns the CloudKit Container
    var container: Container? { get set }

    /// - returns whether to use cellular data access, if WiFi is unavailable (CKOperation default is true)
    var allowsCellularAccess: Bool { get set }

    /// - returns a unique identifier for a long-lived CKOperation
    @available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
    var operationID: String { get }

    /// - returns whether the operation is long-lived
    @available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
    var longLived: Bool { get set }

    /// The type of the CKOperation longLivedOperationWasPersistedBlock
    associatedtype CKOperationLongLivedOperationWasPersistedBlock

    #if swift(>=3.0) // TEMPORARY FIX: Swift 2.3 compiler crash
        // The Swift 2.3 compiler (as of Xcode 8 beta 4) crashes with a fatal error caused by
        // the following declaration & the extension CKOperation: CKOperationType { }
        // The Swift 3.0 compiler has no issue. As of now, no workaround is available besides using Swift 3.0.
        //
        /// - returns the block to execute when the server starts storing callbacks for this long-lived CKOperation
        @available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
        var longLivedOperationWasPersistedBlock: CKOperationLongLivedOperationWasPersistedBlock { get set }
    #endif

    /// If non-zero, overrides the timeout interval for any network requests issued by this operation.
    /// See NSURLSessionConfiguration.timeoutIntervalForRequest
    @available(iOS 10.0, tvOS 10.0, OSX 10.12, watchOS 3.0, *)
    var timeoutIntervalForRequest: NSTimeInterval { get set }

    /// If non-zero, overrides the timeout interval for any network resources retrieved by this operation.
    /// See NSURLSessionConfiguration.timeoutIntervalForResource
    @available(iOS 10.0, tvOS 10.0, OSX 10.12, watchOS 3.0, *)
    var timeoutIntervalForResource: NSTimeInterval { get set }
}

/**
 A generic protocol which exposes the additional types used by
 Apple's new CloudKit Operation types in iOS 10 / macOS 10.12.
 */
public protocol CKOperation2Type: CKOperationType {
    /// The type of the CloudKit UserIdentity
    associatedtype UserIdentity

    /// The type of the CloudKit UserIdentityLookupInfo
    associatedtype UserIdentityLookupInfo

    /// The type of the CloudKit Share
    associatedtype Share

    /// The type of the CloudKit ShareMetadata
    associatedtype ShareMetadata

    /// The type of the CloudKit ShareParticipant
    associatedtype ShareParticipant
}

/**
 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Database Operation types.
 */
public protocol CKDatabaseOperationType: CKOperationType {

    /// The type of the CloudKit Database
    associatedtype Database

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

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which return a results limit.
public protocol CKResultsLimit: CKOperationType {

    /// - returns: the results limit
    var resultsLimit: Int { get set }
}

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which return a flag for more coming.
public protocol CKMoreComing: CKOperationType {

    /// - returns: whether there are more results on the server
    var moreComing: Bool { get }
}

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which have a flag to fetch all changes.
public protocol CKFetchAllChanges: CKOperationType {

    /// - returns: whether there are more results on the server
    var fetchAllChanges: Bool { get set }
}

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which have desired keys.
public protocol CKDesiredKeys: CKOperationType {

    /// - returns: the desired keys to fetch or fetched.
    var desiredKeys: [String]? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CloudKit batched operation types.
public protocol CKBatchedOperationType: CKResultsLimit, CKMoreComing { }

/// A generic protocol which exposes the properties used by Apple's CloudKit fetched operation types.
public typealias CKFetchOperationType = protocol<CKPreviousServerChangeToken, CKBatchedOperationType>

/// A generic protocol which exposes the properties used by Apple's CKDiscoverAllContactsOperation.
public protocol CKDiscoverAllContactsOperationType: CKOperationType {

    /// - returns: the completion block used for discovering all contacts.
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKAcceptSharesOperation.
public protocol CKAcceptSharesOperationType: CKOperation2Type {

    /// - returns: the share metadatas
    var shareMetadatas: [ShareMetadata] { get set }

    /// - returns: the block used to return accepted shares
    var perShareCompletionBlock: ((ShareMetadata, Share?, NSError?) -> Void)? { get set }

    /// - returns: the completion block used for accepting shares
    var acceptSharesCompletionBlock: ((NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKDiscoverAllUserIdentitiesOperation.
public protocol CKDiscoverAllUserIdentitiesOperationType: CKOperation2Type {

    /// - returns: a block for when a user identity is discovered
    var userIdentityDiscoveredBlock: ((UserIdentity) -> Void)? { get set }

    /// - returns: the completion block used for discovering all user identities
    var discoverAllUserIdentitiesCompletionBlock: ((NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKDiscoverUserInfosOperation.
public protocol CKDiscoverUserInfosOperationType: CKOperationType {

    /// - returns: the email addresses used in discovery
    var emailAddresses: [String]? { get set }

    /// - returns: the user record IDs
    var userRecordIDs: [RecordID]? { get set }

    /// - returns: the completion block used for discovering user infos
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKDiscoverUserIdentitiesOperation.
public protocol CKDiscoverUserIdentitiesOperationType: CKOperation2Type {

    /// - returns: the user identity lookup info used in discovery
    var userIdentityLookupInfos: [UserIdentityLookupInfo] { get set }

    /// - returns: the block used to return discovered user identities
    var userIdentityDiscoveredBlock: ((UserIdentity, UserIdentityLookupInfo) -> Void)? { get set }

    /// - returns: the completion block used for discovering user identities
    var discoverUserIdentitiesCompletionBlock: ((NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchNotificationChangesOperation.
public protocol CKFetchNotificationChangesOperationType: CKFetchOperationType {

    /// - returns: the block invoked when there are notification changes.
    var notificationChangedBlock: ((Notification) -> Void)? { get set }

    /// - returns: the completion block used for notification changes.
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKMarkNotificationsReadOperation.
public protocol CKMarkNotificationsReadOperationType: CKOperationType {

    /// - returns: the notification IDs
    var notificationIDs: [NotificationID] { get set }

    /// - returns: the completion block used when marking notifications
    var markNotificationsReadCompletionBlock: (([NotificationID]?, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKModifyBadgeOperation.
public protocol CKModifyBadgeOperationType: CKOperationType {

    /// - returns: the badge value
    var badgeValue: Int { get set }

    /// - returns: the completion block used
    var modifyBadgeCompletionBlock: ((NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchDatabaseChangesOperationType.
public protocol CKFetchDatabaseChangesOperationType: CKDatabaseOperationType, CKFetchAllChanges, CKPreviousServerChangeToken, CKResultsLimit {

    /// - returns: a block for when a the changeToken is updated
    var changeTokenUpdatedBlock: ((ServerChangeToken) -> Void)? { get set }

    /// - returns: a block for when a recordZone was changed
    var recordZoneWithIDChangedBlock: ((RecordZoneID) -> Void)? { get set }

    /// - returns: a block for when a recordZone was deleted
    var recordZoneWithIDWasDeletedBlock: ((RecordZoneID) -> Void)? { get set }

    /// - returns: the completion for fetching database changes
    var fetchDatabaseChangesCompletionBlock: ((ServerChangeToken?, Bool, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordChangesOperation.
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

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordZonesOperation.
public protocol CKFetchRecordZonesOperationType: CKDatabaseOperationType {

    /// - returns: the record zone IDs which will be fetched
    var recordZoneIDs: [RecordZoneID]? { get set }

    /// - returns: the completion block for fetching record zones
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordsOperation.
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

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordZoneChangesOperation.
public protocol CKFetchRecordZoneChangesOperationType: CKDatabaseOperationType, CKFetchAllChanges {

    /// The type of the CloudKit FetchRecordZoneChangesOptions
    associatedtype FetchRecordZoneChangesOptions

    /// - returns: the record zone IDs which will fetch changes
    var recordZoneIDs: [RecordZoneID] { get set }

    /// - returns: the per-record-zone options
    var optionsByRecordZoneID: [RecordZoneID : FetchRecordZoneChangesOptions]? { get set }

    /// - returns: a block for when a record is changed
    var recordChangedBlock: ((Record) -> Void)? { get set }

    /// - returns: a block for when a recordID is deleted (receives the recordID and the recordType)
    var recordWithIDWasDeletedBlock: ((RecordID, String) -> Void)? { get set }

    /// - returns: a block for when a recordZone changeToken update is sent
    var recordZoneChangeTokensUpdatedBlock: ((RecordZoneID, ServerChangeToken?, NSData?) -> Void)? { get set }

    /// - returns: a block for when a recordZone fetch is complete
    var recordZoneFetchCompletionBlock: ((RecordZoneID, ServerChangeToken?, NSData?, Bool, NSError?) -> Void)? { get set }

    /// - returns: the completion for fetching records (i.e. for the entire operation)
    var fetchRecordZoneChangesCompletionBlock: ((NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchShareMetadataOperation.
public protocol CKFetchShareMetadataOperationType: CKOperation2Type {

    /// - returns: the share URLs
    var shareURLs: [NSURL] { get set }

    /// - returns: whether to fetch the share root record
    var shouldFetchRootRecord: Bool { get set }

    /// - returns: the share root record desired keys
    var rootRecordDesiredKeys: [String]? { get set }

    /// - returns: the per share metadata block
    var perShareMetadataBlock: ((NSURL, ShareMetadata?, NSError?) -> Void)? { get set }

    /// - returns: the fetch share metadata completion block
    var fetchShareMetadataCompletionBlock: ((NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchShareParticipantsOperation.
public protocol CKFetchShareParticipantsOperationType: CKOperation2Type {

    /// - returns: the user identity lookup infos
    var userIdentityLookupInfos: [UserIdentityLookupInfo] { get set }

    /// - returns: the share participant fetched block
    var shareParticipantFetchedBlock: ((ShareParticipant) -> Void)? { get set }

    /// - returns: the fetch share participants completion block
    var fetchShareParticipantsCompletionBlock: ((NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchSubscriptionsOperation.
public protocol CKFetchSubscriptionsOperationType: CKDatabaseOperationType {

    /// - returns: the subscription IDs
    var subscriptionIDs: [String]? { get set }

    /// - returns: the fetch subscription completion block
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKModifyRecordZonesOperation.
public protocol CKModifyRecordZonesOperationType: CKDatabaseOperationType {

    /// - returns: the record zones to save
    var recordZonesToSave: [RecordZone]? { get set }

    /// - returns: the record zone IDs to delete
    var recordZoneIDsToDelete: [RecordZoneID]? { get set }

    /// - returns: the modify record zones completion block
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, NSError?) -> Void)? { get set }
}

// A generic protocol which exposes the properties used by Apple's CKModifyRecordsOperation.
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
    var isAtomic: Bool { get set }

    /// - returns: a per record progress block
    var perRecordProgressBlock: ((Record, Double) -> Void)? { get set }

    /// - returns: a per record completion block
    var perRecordCompletionBlock: ((Record?, NSError?) -> Void)? { get set }

    /// - returns: the modify records completion block
    var modifyRecordsCompletionBlock: (([Record]?, [RecordID]?, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKModifySubscriptionsOperation.
public protocol CKModifySubscriptionsOperationType: CKDatabaseOperationType {

    /// - returns: the subscriptions to save
    var subscriptionsToSave: [Subscription]? { get set }

    /// - returns: the subscriptions IDs to delete
    var subscriptionIDsToDelete: [String]? { get set }

    /// - returns: the modify subscription completion block
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, NSError?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKQueryOperation.
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


public protocol BatchProcessOperationType: CKOperationType {
    associatedtype Process
    associatedtype Error: CloudKitBatchProcessErrorType

    var toProcess: [Process]? { get set }
}

public protocol BatchModifyOperationType: CKOperationType {
    associatedtype Save
    associatedtype Delete
    associatedtype Error: CloudKitBatchModifyErrorType

    var toSave: [Save]? { get set }
    var toDelete: [Delete]? { get set }
}

/// An extension to make CKOperation to conform to the CKOperationType.
extension CKOperation: CKOperationType {

    /// The Container is a CKContainer
    public typealias Container = CKContainer

    /// The ServerChangeToken is a CKServerChangeToken
    public typealias ServerChangeToken = CKServerChangeToken

    /// The DiscoveredUserInfo is a CKDiscoveredUserInfo
    @available(iOS, introduced=8.0, deprecated=10.0, message="Replaced by CKUserIdentity")
    @available(OSX, introduced=10.10, deprecated=10.12, message="Replaced by CKUserIdentity")
    @available(tvOS, introduced=8.0, deprecated=10.0, message="Replaced by CKUserIdentity")
    @available(watchOS, introduced=2.0, deprecated=3.0, message="Replaced by CKUserIdentity")
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

    #if !os(watchOS)
        /// The Subscription is a CKSubscription
        public typealias Subscription = CKSubscription
    #else
        // CKSubscription is unsupported on watchOS
        public typealias Subscription = Void
    #endif

    /// The RecordSavePolicy is a CKRecordSavePolicy
    public typealias RecordSavePolicy = CKRecordSavePolicy

    /// The Query is a CKQuery
    public typealias Query = CKQuery

    /// The QueryCursor is a CKQueryCursor
    public typealias QueryCursor = CKQueryCursor

    /// The CKOperationLongLivedOperationWasPersistedBlock is () -> Void
    public typealias CKOperationLongLivedOperationWasPersistedBlock = () -> Void
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKOperation: CKOperation2Type {
    /// The UserIdentity is a CKUserIdentity
    public typealias UserIdentity = CKUserIdentity

    /// The UserIdentityLookupInfo is a CKUserIdentityLookupInfo
    public typealias UserIdentityLookupInfo = CKUserIdentityLookupInfo

    /// The Share is a CKShare
    public typealias Share = CKShare

    /// The ShareMetadata is a CKShareMetadata
    public typealias ShareMetadata = CKShareMetadata

    /// The ShareParticipant is a CKShareParticipant
    public typealias ShareParticipant = CKShareParticipant
}

extension CKDatabaseOperation: CKDatabaseOperationType {

    /// The Database is a CKDatabase
    public typealias Database = CKDatabase
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKAcceptSharesOperation: CKAcceptSharesOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = CloudKitError
}

/// Extension to have CKDiscoverAllContactsOperation conform to CKDiscoverAllContactsOperationType
#if !os(tvOS)
@available(iOS, introduced=8.0, deprecated=10.0, message="Use CKDiscoverAllUserIdentitiesOperation instead")
@available(OSX, introduced=10.10, deprecated=10.12, message="Use CKDiscoverAllUserIdentitiesOperation instead")
@available(watchOS, introduced=2.0, deprecated=3.0, message="Use CKDiscoverAllUserIdentitiesOperation instead")
extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = DiscoverAllContactsError<DiscoveredUserInfo>
}
#endif

#if !os(tvOS)
@available(iOS 10.0, OSX 10.12, watchOS 3.0, *)
extension CKDiscoverAllUserIdentitiesOperation: CKDiscoverAllUserIdentitiesOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = CloudKitError
}
#endif

@available(iOS, introduced=8.0, deprecated=10.0, message="Use CKDiscoverUserIdentitiesOperation instead")
@available(OSX, introduced=10.10, deprecated=10.12, message="Use CKDiscoverUserIdentitiesOperation instead")
@available(tvOS, introduced=8.0, deprecated=10.0, message="Use CKDiscoverUserIdentitiesOperation instead")
@available(watchOS, introduced=2.0, deprecated=3.0, message="Use CKDiscoverUserIdentitiesOperation instead")
extension CKDiscoverUserInfosOperation: CKDiscoverUserInfosOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = CloudKitError
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKDiscoverUserIdentitiesOperation: CKDiscoverUserIdentitiesOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = CloudKitError
}

extension CKFetchNotificationChangesOperation: CKFetchNotificationChangesOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = FetchNotificationChangesError<ServerChangeToken>
}

extension CKMarkNotificationsReadOperation: CKMarkNotificationsReadOperationType, AssociatedErrorType, BatchProcessOperationType {

    // The associated error type
    public typealias Error = MarkNotificationsReadError<NotificationID>

    public var toProcess: [CKNotificationID]? {
        get { return notificationIDs }
        set { notificationIDs = newValue ?? [] }
    }
}

extension CKModifyBadgeOperation: CKModifyBadgeOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = CloudKitError
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKFetchDatabaseChangesOperation: CKFetchDatabaseChangesOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = FetchDatabaseChangesError<ServerChangeToken>
}

@available(iOS, introduced=8.0, deprecated=10.0, message="Use CKFetchRecordZoneChangesOperation instead")
@available(OSX, introduced=10.10, deprecated=10.12, message="Use CKFetchRecordZoneChangesOperation instead")
@available(tvOS, introduced=8.0, deprecated=10.0, message="Use CKFetchRecordZoneChangesOperation instead")
@available(watchOS, introduced=2.0, deprecated=3.0, message="Use CKFetchRecordZoneChangesOperation instead")
extension CKFetchRecordChangesOperation: CKFetchRecordChangesOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = FetchRecordChangesError<ServerChangeToken>
}

extension CKFetchRecordZonesOperation: CKFetchRecordZonesOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = FetchRecordZonesError<RecordZone, RecordZoneID>
}

extension CKFetchRecordsOperation: CKFetchRecordsOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = FetchRecordsError<Record, RecordID>
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKFetchRecordZoneChangesOperation: CKFetchRecordZoneChangesOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = FetchRecordZoneChangesError

    /// The type of the CloudKit FetchRecordZoneChangesOptions
    public typealias FetchRecordZoneChangesOptions = CKFetchRecordZoneChangesOptions
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKFetchShareMetadataOperation: CKFetchShareMetadataOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = CloudKitError
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKFetchShareParticipantsOperation: CKFetchShareParticipantsOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = CloudKitError
}

#if !os(watchOS)
extension CKFetchSubscriptionsOperation: CKFetchSubscriptionsOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = FetchSubscriptionsError<Subscription>
}
#endif

extension CKModifyRecordZonesOperation: CKModifyRecordZonesOperationType, AssociatedErrorType, BatchModifyOperationType {

    // The associated error type
    public typealias Error = ModifyRecordZonesError<RecordZone, RecordZoneID>

    public var toSave: [RecordZone]? {
        get { return recordZonesToSave }
        set { recordZonesToSave = newValue }
    }

    public var toDelete: [RecordZoneID]? {
        get { return recordZoneIDsToDelete }
        set { recordZoneIDsToDelete = newValue }
    }
}

extension CKModifyRecordsOperation: CKModifyRecordsOperationType, AssociatedErrorType, BatchModifyOperationType {

    // The associated error type
    public typealias Error = ModifyRecordsError<Record, RecordID>

    public var toSave: [Record]? {
        get { return recordsToSave }
        set { recordsToSave = newValue }
    }

    public var toDelete: [RecordID]? {
        get { return recordIDsToDelete }
        set { recordIDsToDelete = newValue }
    }
}

#if !os(watchOS)
extension CKModifySubscriptionsOperation: CKModifySubscriptionsOperationType, AssociatedErrorType, BatchModifyOperationType {

    // The associated error type
    public typealias Error = ModifySubscriptionsError<Subscription, String>

    public var toSave: [Subscription]? {
        get { return subscriptionsToSave }
        set { subscriptionsToSave = newValue }
    }

    public var toDelete: [String]? {
        get { return subscriptionIDsToDelete }
        set { subscriptionIDsToDelete = newValue }
    }
}
#endif

extension CKQueryOperation: CKQueryOperationType, AssociatedErrorType {

    // The associated error type
    public typealias Error = QueryError<QueryCursor>
}

// swiftlint:enable file_length
