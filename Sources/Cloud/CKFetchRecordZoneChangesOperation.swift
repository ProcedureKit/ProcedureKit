//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

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
