//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKModifyRecordsOperation.
public protocol CKModifyRecordsOperationProtocol: CKDatabaseOperationProtocol {

    /// The type of the perRecordCompletionBlock property
    associatedtype PerRecordCompletionBlockType

    /// - returns: the records to save
    var recordsToSave: [Record]? { get set }

    /// - returns: the record IDs to delete
    var recordIDsToDelete: [RecordID]? { get set }

    /// - returns: the save policy
    var savePolicy: RecordSavePolicy { get set }

    /// - returns: the client change token data
    var clientChangeTokenData: Data? { get set }

    /// - returns: a flag for atomic changes
    var isAtomic: Bool { get set }

    /// - returns: a per record progress block
    var perRecordProgressBlock: ((Record, Double) -> Void)? { get set }

    /// - returns: a per record completion block
    var perRecordCompletionBlock: PerRecordCompletionBlockType { get set }

    /// - returns: the modify records completion block
    var modifyRecordsCompletionBlock: (([Record]?, [RecordID]?, Error?) -> Void)? { get set }
}

public struct ModifyRecordsError<Record, RecordID>: CloudKitError, CloudKitBatchModifyError {

    public let underlyingError: Error
    public let saved: [Record]?
    public let deleted: [RecordID]?
}

extension CKModifyRecordsOperation: CKModifyRecordsOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = ModifyRecordsError<Record, RecordID>
}

extension CKProcedure where T: CKModifyRecordsOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var recordsToSave: [T.Record]? {
        get { return operation.recordsToSave }
        set { operation.recordsToSave = newValue }
    }

    public var recordIDsToDelete: [T.RecordID]? {
        get { return operation.recordIDsToDelete }
        set { operation.recordIDsToDelete = newValue }
    }

    public var savePolicy: T.RecordSavePolicy {
        get { return operation.savePolicy }
        set { operation.savePolicy = newValue }
    }

    public var clientChangeTokenData: Data? {
        get { return operation.clientChangeTokenData }
        set { operation.clientChangeTokenData = newValue }
    }

    public var isAtomic: Bool {
        get { return operation.isAtomic }
        set { operation.isAtomic = newValue }
    }

    public var perRecordProgressBlock: CloudKitProcedure<T>.ModifyRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    public var perRecordCompletionBlock: CloudKitProcedure<T>.ModifyRecordsPerRecordCompletionBlock {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    func setModifyRecordsCompletionBlock(_ block: @escaping CloudKitProcedure<T>.ModifyRecordsCompletionBlock) {
        operation.modifyRecordsCompletionBlock = { [weak self] saved, deleted, error in
            if let strongSelf = self, let error = error {
                strongSelf.setErrorOnce(ModifyRecordsError(underlyingError: error, saved: saved, deleted: deleted))
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

extension CloudKitProcedure where T: CKModifyRecordsOperationProtocol {

    internal typealias ModifyRecordsPerRecordProgress = (T.Record, Double)
    internal typealias ModifyRecordsPerRecordCompletion = (T.Record?, Error?)
    internal typealias ModifyRecordsCompletion = ([T.Record]?, [T.RecordID]?)

    /// A typealias for the block types used by CloudKitOperation<CKModifyRecordsOperation>
    public typealias ModifyRecordsPerRecordProgressBlock = (T.Record, Double) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKModifyRecordsOperation>
    public typealias ModifyRecordsPerRecordCompletionBlock = T.PerRecordCompletionBlockType

    /// A typealias for the block types used by CloudKitOperation<CKModifyRecordsOperation>
    public typealias ModifyRecordsCompletionBlock = ([T.Record]?, [T.RecordID]?) -> Void

    /// - returns: the records to save
    public var recordsToSave: [T.Record]? {
        get { return current.recordsToSave }
        set {
            current.recordsToSave = newValue
            appendConfigureBlock { $0.recordsToSave = newValue }
        }
    }

    /// - returns: the record IDs to delete
    public var recordIDsToDelete: [T.RecordID]? {
        get { return current.recordIDsToDelete }
        set {
            current.recordIDsToDelete = newValue
            appendConfigureBlock { $0.recordIDsToDelete = newValue }
        }
    }

    /// - returns: the save policy
    public var savePolicy: T.RecordSavePolicy {
        get { return current.savePolicy }
        set {
            current.savePolicy = newValue
            appendConfigureBlock { $0.savePolicy = newValue }
        }
    }

    /// - returns: the client change token data
    public var clientChangeTokenData: Data? {
        get { return current.clientChangeTokenData }
        set {
            current.clientChangeTokenData = newValue
            appendConfigureBlock { $0.clientChangeTokenData = newValue }
        }
    }

    /// - returns: a flag to indicate atomicity
    public var isAtomic: Bool {
        get { return current.isAtomic }
        set {
            current.isAtomic = newValue
            appendConfigureBlock { $0.isAtomic = newValue }
        }
    }

    /// - returns: a block for per record progress
    public var perRecordProgressBlock: ModifyRecordsPerRecordProgressBlock? {
        get { return current.perRecordProgressBlock }
        set {
            current.perRecordProgressBlock = newValue
            appendConfigureBlock { $0.perRecordProgressBlock = newValue }
        }
    }

    /// - returns: a block for per record completion
    public var perRecordCompletionBlock: ModifyRecordsPerRecordCompletionBlock {
        get { return current.perRecordCompletionBlock }
        set {
            current.perRecordCompletionBlock = newValue
            appendConfigureBlock { $0.perRecordCompletionBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a ModifyRecordsCompletionBlock block
     */
    public func setModifyRecordsCompletionBlock(block: @escaping ModifyRecordsCompletionBlock) {
        appendConfigureBlock { $0.setModifyRecordsCompletionBlock(block) }
    }
}
