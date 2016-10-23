//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

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

public struct FetchRecordsError<Record, RecordID: Hashable>: CloudKitError {

    public let underlyingError: Error
    public let recordsByID: [RecordID: Record]?
}

extension CKFetchRecordsOperation: CKFetchRecordsOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = FetchRecordsError<Record, RecordID>
}
