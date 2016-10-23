//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordZonesOperation.
public protocol CKFetchRecordZonesOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the record zone IDs which will be fetched
    var recordZoneIDs: [RecordZoneID]? { get set }

    /// - returns: the completion block for fetching record zones
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, Error?) -> Void)? { get set }
}
