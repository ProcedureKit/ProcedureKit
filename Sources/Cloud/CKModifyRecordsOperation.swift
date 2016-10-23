//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKModifyRecordsOperation.
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
