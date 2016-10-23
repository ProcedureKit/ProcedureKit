//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

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
