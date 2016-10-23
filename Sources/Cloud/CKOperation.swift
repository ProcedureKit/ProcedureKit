//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// An extension to make CKOperation to conform to the CKOperationProtocol.
extension CKOperation: CKOperationProtocol {

    /// The Container is a CKContainer
    public typealias Container = CKContainer

    /// The ServerChangeToken is a CKServerChangeToken
    public typealias ServerChangeToken = CKServerChangeToken

    /// The DiscoveredUserInfo is a CKDiscoveredUserInfo
    @available(iOS, introduced: 8.0, deprecated: 10.0, message: "Replaced by CKUserIdentity")
    @available(OSX, introduced: 10.10, deprecated: 10.12, message: "Replaced by CKUserIdentity")
    @available(tvOS, introduced: 8.0, deprecated: 10.0, message: "Replaced by CKUserIdentity")
    @available(watchOS, introduced: 2.0, deprecated: 3.0, message: "Replaced by CKUserIdentity")
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

    /// The UserIdentity is a CKUserIdentity
    @available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
    public typealias UserIdentity = CKUserIdentity

    /// The UserIdentityLookupInfo is a CKUserIdentityLookupInfo
    @available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
    public typealias UserIdentityLookupInfo = CKUserIdentityLookupInfo

    /// The Share is a CKShare
    @available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
    public typealias Share = CKShare

    /// The ShareMetadata is a CKShareMetadata
    @available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
    public typealias ShareMetadata = CKShareMetadata

    /// The ShareParticipant is a CKShareParticipant
    @available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
    public typealias ShareParticipant = CKShareParticipant

    /// The CKOperationLongLivedOperationWasPersistedBlock is () -> Void
    public typealias CKOperationLongLivedOperationWasPersistedBlock = () -> Void
}
