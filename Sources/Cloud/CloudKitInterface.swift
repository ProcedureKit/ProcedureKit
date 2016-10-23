//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

// swiftlint:disable file_length

/**
 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Operation types.
 */
public protocol CKOperationProtocol: class {

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

    /// - returns the block to execute when the server starts storing callbacks for this long-lived CKOperation
    @available(iOS 9.3, tvOS 9.3, OSX 10.12, watchOS 2.3, *)
    var longLivedOperationWasPersistedBlock: () -> Void { get set }

    /// If non-zero, overrides the timeout interval for any network requests issued by this operation.
    /// See NSURLSessionConfiguration.timeoutIntervalForRequest
    @available(iOS 10.0, tvOS 10.0, OSX 10.12, watchOS 3.0, *)
    var timeoutIntervalForRequest: TimeInterval { get set }

    /// If non-zero, overrides the timeout interval for any network resources retrieved by this operation.
    /// See NSURLSessionConfiguration.timeoutIntervalForResource
    @available(iOS 10.0, tvOS 10.0, OSX 10.12, watchOS 3.0, *)
    var timeoutIntervalForResource: TimeInterval { get set }
}

/**
 A generic protocol which exposes the types and properties used by
 Apple's CloudKit Database Operation types.
 */
public protocol CKDatabaseOperationProtocol: CKOperationProtocol {

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
public protocol CKPreviousServerChangeToken: CKOperationProtocol {

    /// - returns: the previous sever change token
    var previousServerChangeToken: ServerChangeToken? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which return a results limit.
public protocol CKResultsLimit: CKOperationProtocol {

    /// - returns: the results limit
    var resultsLimit: Int { get set }
}

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which return a flag for more coming.
public protocol CKMoreComing: CKOperationProtocol {

    /// - returns: whether there are more results on the server
    var moreComing: Bool { get }
}

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which have a flag to fetch all changes.
public protocol CKFetchAllChanges: CKOperationProtocol {

    /// - returns: whether there are more results on the server
    var fetchAllChanges: Bool { get set }
}

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which have desired keys.
public protocol CKDesiredKeys: CKOperationProtocol {

    /// - returns: the desired keys to fetch or fetched.
    var desiredKeys: [String]? { get set }
}

/// A protocol typealias which exposes the properties used by Apple's CloudKit batched operation types.
public typealias CKBatchedOperation = CKResultsLimit & CKMoreComing

/// A protocol typealias which exposes the properties used by Apple's CloudKit fetched operation types.
public typealias CKFetchOperation = CKPreviousServerChangeToken & CKBatchedOperation

/// A generic protocol which exposes the properties used by Apple's CKAcceptSharesOperation.
public protocol CKAcceptSharesOperationProtocol: CKOperationProtocol {

    /// - returns: the share metadatas
    var shareMetadatas: [ShareMetadata] { get set }

    /// - returns: the block used to return accepted shares
    var perShareCompletionBlock: ((ShareMetadata, Share?, Swift.Error?) -> Void)? { get set }

    /// - returns: the completion block used for accepting shares
    var acceptSharesCompletionBlock: ((Swift.Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKDiscoverAllContactsOperation.
public protocol CKDiscoverAllContactsOperationProtocol: CKOperationProtocol {

    /// - returns: the completion block used for discovering all contacts.
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKDiscoverAllUserIdentitiesOperation.
public protocol CKDiscoverAllUserIdentitiesOperationProtocol: CKOperationProtocol {

    /// - returns: a block for when a user identity is discovered
    var userIdentityDiscoveredBlock: ((UserIdentity) -> Void)? { get set }

    /// - returns: the completion block used for discovering all user identities
    var discoverAllUserIdentitiesCompletionBlock: ((Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKDiscoverUserInfosOperation.
public protocol CKDiscoverUserInfosOperationProtocol: CKOperationProtocol {

    /// - returns: the email addresses used in discovery
    var emailAddresses: [String]? { get set }

    /// - returns: the user record IDs
    var userRecordIDs: [RecordID]? { get set }

    /// - returns: the completion block used for discovering user infos
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKDiscoverUserIdentitiesOperation.
public protocol CKDiscoverUserIdentitiesOperationProtocol: CKOperationProtocol {

    /// - returns: the user identity lookup info used in discovery
    var userIdentityLookupInfos: [UserIdentityLookupInfo] { get set }

    /// - returns: the block used to return discovered user identities
    var userIdentityDiscoveredBlock: ((UserIdentity, UserIdentityLookupInfo) -> Void)? { get set }

    /// - returns: the completion block used for discovering user identities
    var discoverUserIdentitiesCompletionBlock: ((Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchNotificationChangesOperation.
public protocol CKFetchNotificationChangesOperationProtocol: CKFetchOperation {

    /// - returns: the block invoked when there are notification changes.
    var notificationChangedBlock: ((Notification) -> Void)? { get set }

    /// - returns: the completion block used for notification changes.
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKMarkNotificationsReadOperation.
public protocol CKMarkNotificationsReadOperationProtocol: CKOperationProtocol {

    /// - returns: the notification IDs
    var notificationIDs: [NotificationID] { get set }

    /// - returns: the completion block used when marking notifications
    var markNotificationsReadCompletionBlock: (([NotificationID]?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKModifyBadgeOperation.
public protocol CKModifyBadgeOperationProtocol: CKOperationProtocol {

    /// - returns: the badge value
    var badgeValue: Int { get set }

    /// - returns: the completion block used
    var modifyBadgeCompletionBlock: ((Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchDatabaseChangesOperationType.
public protocol CKFetchDatabaseChangesOperationProtocol: CKDatabaseOperationProtocol, CKFetchAllChanges, CKPreviousServerChangeToken, CKResultsLimit {

    /// - returns: a block for when a the changeToken is updated
    var changeTokenUpdatedBlock: ((ServerChangeToken) -> Void)? { get set }

    /// - returns: a block for when a recordZone was changed
    var recordZoneWithIDChangedBlock: ((RecordZoneID) -> Void)? { get set }

    /// - returns: a block for when a recordZone was deleted
    var recordZoneWithIDWasDeletedBlock: ((RecordZoneID) -> Void)? { get set }

    /// - returns: the completion for fetching database changes
    var fetchDatabaseChangesCompletionBlock: ((ServerChangeToken?, Bool, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordChangesOperation.
public protocol CKFetchRecordChangesOperationProtocol: CKDatabaseOperationProtocol, CKFetchOperation, CKDesiredKeys {

    /// - returns: the record zone ID whcih will fetch changes
    var recordZoneID: RecordZoneID { get set }

    /// - returns: a block for when a record is changed
    var recordChangedBlock: ((Record) -> Void)? { get set }

    /// - returns: a block for when a record with ID
    var recordWithIDWasDeletedBlock: ((RecordID) -> Void)? { get set }

    /// - returns: the completion for fetching records
    var fetchRecordChangesCompletionBlock: ((ServerChangeToken?, NSData?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordZonesOperation.
public protocol CKFetchRecordZonesOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the record zone IDs which will be fetched
    var recordZoneIDs: [RecordZoneID]? { get set }

    /// - returns: the completion block for fetching record zones
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordsOperation.
public protocol CKFetchRecordsOperationProtocol: CKDatabaseOperationProtocol, CKDesiredKeys {

    /// - returns: the record IDs
    var recordIDs: [RecordID]? { get set }

    /// - returns: a per record progress block
    var perRecordProgressBlock: ((RecordID, Double) -> Void)? { get set }

    /// - returns: a per record completion block
    var perRecordCompletionBlock: ((Record?, RecordID?, Error?) -> Void)? { get set }

    /// - returns: the fetch record completion block
    var fetchRecordsCompletionBlock: (([RecordID: Record]?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordZoneChangesOperation.
public protocol CKFetchRecordZoneChangesOperationProtocol: CKDatabaseOperationProtocol, CKFetchAllChanges {

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
    var recordZoneFetchCompletionBlock: ((RecordZoneID, ServerChangeToken?, NSData?, Bool, Error?) -> Void)? { get set }

    /// - returns: the completion for fetching records (i.e. for the entire operation)
    var fetchRecordZoneChangesCompletionBlock: ((Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchShareMetadataOperation.
public protocol CKFetchShareMetadataOperationProtocol: CKOperationProtocol {

    /// - returns: the share URLs
    var shareURLs: [NSURL] { get set }

    /// - returns: whether to fetch the share root record
    var shouldFetchRootRecord: Bool { get set }

    /// - returns: the share root record desired keys
    var rootRecordDesiredKeys: [String]? { get set }

    /// - returns: the per share metadata block
    var perShareMetadataBlock: ((NSURL, ShareMetadata?, Error?) -> Void)? { get set }

    /// - returns: the fetch share metadata completion block
    var fetchShareMetadataCompletionBlock: ((Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchShareParticipantsOperation.
public protocol CKFetchShareParticipantsOperationProtocol: CKOperationProtocol {

    /// - returns: the user identity lookup infos
    var userIdentityLookupInfos: [UserIdentityLookupInfo] { get set }

    /// - returns: the share participant fetched block
    var shareParticipantFetchedBlock: ((ShareParticipant) -> Void)? { get set }

    /// - returns: the fetch share participants completion block
    var fetchShareParticipantsCompletionBlock: ((Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchSubscriptionsOperation.
public protocol CKFetchSubscriptionsOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the subscription IDs
    var subscriptionIDs: [String]? { get set }

    /// - returns: the fetch subscription completion block
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKModifyRecordZonesOperation.
public protocol CKModifyRecordZonesOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the record zones to save
    var recordZonesToSave: [RecordZone]? { get set }

    /// - returns: the record zone IDs to delete
    var recordZoneIDsToDelete: [RecordZoneID]? { get set }

    /// - returns: the modify record zones completion block
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, Error?) -> Void)? { get set }
}

// A generic protocol which exposes the properties used by Apple's CKModifyRecordsOperation.
public protocol CKModifyRecordsOperationProtocol: CKDatabaseOperationProtocol {

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
    var perRecordCompletionBlock: ((Record?, Error?) -> Void)? { get set }

    /// - returns: the modify records completion block
    var modifyRecordsCompletionBlock: (([Record]?, [RecordID]?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKModifySubscriptionsOperation.
public protocol CKModifySubscriptionsOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the subscriptions to save
    var subscriptionsToSave: [Subscription]? { get set }

    /// - returns: the subscriptions IDs to delete
    var subscriptionIDsToDelete: [String]? { get set }

    /// - returns: the modify subscription completion block
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, Error?) -> Void)? { get set }
}

/// A generic protocol which exposes the properties used by Apple's CKQueryOperation.
public protocol CKQueryOperationProtocol: CKDatabaseOperationProtocol, CKResultsLimit, CKDesiredKeys {

    /// - returns: the query to execute
    var query: Query? { get set }

    /// - returns: the query cursor
    var cursor: QueryCursor? { get set }

    /// - returns: the zone ID
    var zoneID: RecordZoneID? { get set }

    /// - returns: a record fetched block
    var recordFetchedBlock: ((Record) -> Void)? { get set }

    /// - returns: the query completion block
    var queryCompletionBlock: ((QueryCursor?, Error?) -> Void)? { get set }
}

// swiftlint:enable file_length
