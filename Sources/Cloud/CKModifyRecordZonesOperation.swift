//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKModifyRecordZonesOperation.
public protocol CKModifyRecordZonesOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the record zones to save
    var recordZonesToSave: [RecordZone]? { get set }

    /// - returns: the record zone IDs to delete
    var recordZoneIDsToDelete: [RecordZoneID]? { get set }

    /// - returns: the modify record zones completion block
    var modifyRecordZonesCompletionBlock: (([RecordZone]?, [RecordZoneID]?, Error?) -> Void)? { get set }
}
