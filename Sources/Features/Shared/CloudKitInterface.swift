//
//  CloudKitInterface.swift
//  Operations
//
//  Created by Daniel Thorpe on 05/03/2016.
//
//

import Foundation
import CloudKit

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

/// A generic protocol which exposes the properties used by Apple's CKDiscoverUserInfosOperation.
public protocol CKDiscoverUserInfosOperationType: CKOperationType {

    /// - returns: the email addresses used in discovery
    var emailAddresses: [String]? { get set }

    /// - returns: the user record IDs
    var userRecordIDs: [RecordID]? { get set }

    /// - returns: the completion block used for discovering user infos
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, NSError?) -> Void)? { get set }
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
    var atomic: Bool { get set }

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

/// An extension to make CKOperation to conform to the CKOperationType.
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

extension CKDatabaseOperation: CKDatabaseOperationType {
    /// The Database is a CKDatabase
    public typealias Database = CKDatabase
}

/// Extension to have CKDiscoverAllContactsOperation conform to CKDiscoverAllContactsOperationType
#if !os(tvOS)
extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationType { }
#endif

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
