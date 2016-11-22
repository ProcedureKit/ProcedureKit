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

public struct ModifyRecordZonesError<RecordZone, RecordZoneID>: CloudKitError, CloudKitBatchModifyError {

    public let underlyingError: Error
    public let saved: [RecordZone]?
    public let deleted: [RecordZoneID]?
}

extension CKModifyRecordZonesOperation: CKModifyRecordZonesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = ModifyRecordZonesError<RecordZone, RecordZoneID>
}

extension CKProcedure where T: CKModifyRecordZonesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var recordZonesToSave: [T.RecordZone]? {
        get { return operation.recordZonesToSave }
        set { operation.recordZonesToSave = newValue }
    }

    public var recordZoneIDsToDelete: [T.RecordZoneID]? {
        get { return operation.recordZoneIDsToDelete }
        set { operation.recordZoneIDsToDelete = newValue }
    }

    func setModifyRecordZonesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.ModifyRecordZonesCompletionBlock) {
        operation.modifyRecordZonesCompletionBlock = { [weak self] saved, deleted, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(fatalError: ModifyRecordZonesError(underlyingError: error, saved: saved, deleted: deleted))
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

extension CloudKitProcedure where T: CKModifyRecordZonesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    internal typealias ModifyRecordZonesCompletion = ([T.RecordZone]?, [T.RecordZoneID]?)

    /// A typealias for the block types used by CloudKitOperation<CKModifyRecordZonesOperation>
    public typealias ModifyRecordZonesCompletionBlock = ([T.RecordZone]?, [T.RecordZoneID]?) -> Void

    /// - returns: the record zones to save
    public var recordZonesToSave: [T.RecordZone]? {
        get { return current.recordZonesToSave }
        set {
            current.recordZonesToSave = newValue
            appendConfigureBlock { $0.recordZonesToSave = newValue }
        }
    }

    /// - returns: the record zone IDs to delete
    public var recordZoneIDsToDelete: [T.RecordZoneID]? {
        get { return current.recordZoneIDsToDelete }
        set {
            current.recordZoneIDsToDelete = newValue
            appendConfigureBlock { $0.recordZoneIDsToDelete = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a ModifyRecordZonesCompletionBlock block
     */
    public func setModifyRecordZonesCompletionBlock(block: @escaping ModifyRecordZonesCompletionBlock) {
        appendConfigureBlock { $0.setModifyRecordZonesCompletionBlock(block) }
    }
}
