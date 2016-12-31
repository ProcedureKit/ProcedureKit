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

    /// The type of the recordZoneIDs property
    associatedtype RecordZoneIDsPropertyType

    /// - returns: the record zone IDs which will fetch changes
    var recordZoneIDs: RecordZoneIDsPropertyType { get set }

    /// - returns: the per-record-zone options
    var optionsByRecordZoneID: [RecordZoneID : FetchRecordZoneChangesOptions]? { get set }

    /// - returns: a block for when a record is changed
    var recordChangedBlock: ((Record) -> Void)? { get set }

    /// - returns: a block for when a recordID is deleted (receives the recordID and the recordType)
    var recordWithIDWasDeletedBlock: ((RecordID, String) -> Void)? { get set }

    /// - returns: a block for when a recordZone changeToken update is sent
    var recordZoneChangeTokensUpdatedBlock: ((RecordZoneID, ServerChangeToken?, Data?) -> Void)? { get set }

    /// - returns: a block for when a recordZone fetch is complete
    var recordZoneFetchCompletionBlock: ((RecordZoneID, ServerChangeToken?, Data?, Bool, Error?) -> Void)? { get set }

    /// - returns: the completion for fetching records (i.e. for the entire operation)
    var fetchRecordZoneChangesCompletionBlock: ((Error?) -> Void)? { get set }
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKFetchRecordZoneChangesOperation: CKFetchRecordZoneChangesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError

    /// The type of the CloudKit FetchRecordZoneChangesOptions
    public typealias FetchRecordZoneChangesOptions = CKFetchRecordZoneChangesOptions
}

extension CKProcedure where T: CKFetchRecordZoneChangesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    /// - returns: the record zone IDs which will fetch changes
    public var recordZoneIDs: T.RecordZoneIDsPropertyType {
        get { return operation.recordZoneIDs }
        set { operation.recordZoneIDs = newValue }
    }

    /// - returns: the per-record-zone options
    public var optionsByRecordZoneID: [T.RecordZoneID : T.FetchRecordZoneChangesOptions]? {
        get { return operation.optionsByRecordZoneID }
        set { operation.optionsByRecordZoneID = newValue }
    }

    /// - returns: a block for when a record is changed
    public var recordChangedBlock: CloudKitProcedure<T>.FetchRecordZoneChangesRecordChangedBlock? {
        get { return operation.recordChangedBlock }
        set { operation.recordChangedBlock = newValue }
    }

    /// - returns: a block for when a recordID is deleted (receives the recordID and the recordType)
    public var recordWithIDWasDeletedBlock: CloudKitProcedure<T>.FetchRecordZoneChangesRecordWithIDWasDeletedBlock? {
        get { return operation.recordWithIDWasDeletedBlock }
        set { operation.recordWithIDWasDeletedBlock = newValue }
    }

    /// - returns: a block for when a recordZone changeToken update is sent
    public var recordZoneChangeTokensUpdatedBlock: CloudKitProcedure<T>.FetchRecordZoneChangesRecordZoneChangeTokensUpdatedBlock? {
        get { return operation.recordZoneChangeTokensUpdatedBlock }
        set { operation.recordZoneChangeTokensUpdatedBlock = newValue }
    }

    /// - returns: a block to execute when the fetch for a zone has completed
    public var recordZoneFetchCompletionBlock: CloudKitProcedure<T>.FetchRecordZoneChangesCompletionRecordZoneFetchCompletionBlock? {
        get { return operation.recordZoneFetchCompletionBlock }
        set { operation.recordZoneFetchCompletionBlock = newValue }
    }

    /// - returns: the completion for fetching records (i.e. for the entire operation)
    func setFetchRecordZoneChangesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchRecordZoneChangesCompletionBlock) {
        operation.fetchRecordZoneChangesCompletionBlock = { [weak self] error in
            if let strongSelf = self, let error = error {
                strongSelf.append(fatalError: PKCKError(underlyingError: error))
            }
            else {
                block()
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchRecordZoneChangesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordZoneChangesOperationType>
    public typealias FetchRecordZoneChangesRecordChangedBlock = (T.Record) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordZoneChangesOperationType>
    public typealias FetchRecordZoneChangesRecordWithIDWasDeletedBlock = (T.RecordID, String) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordZoneChangesOperationType>
    public typealias FetchRecordZoneChangesRecordZoneChangeTokensUpdatedBlock = (T.RecordZoneID, T.ServerChangeToken?, Data?) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordZoneChangesOperationType>
    public typealias FetchRecordZoneChangesCompletionRecordZoneFetchCompletionBlock = (T.RecordZoneID, T.ServerChangeToken?, Data?, Bool, Error?) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordZoneChangesOperationType>
    public typealias FetchRecordZoneChangesCompletionBlock = () -> Void

    /// - returns: the record zone IDs which will fetch changes
    public var recordZoneIDs: T.RecordZoneIDsPropertyType {
        get { return current.recordZoneIDs }
        set {
            current.recordZoneIDs = newValue
            appendConfigureBlock { $0.recordZoneIDs = newValue }
        }
    }

    /// - returns: the per-record-zone options
    public var optionsByRecordZoneID: [T.RecordZoneID : T.FetchRecordZoneChangesOptions]? {
        get { return current.optionsByRecordZoneID }
        set {
            current.optionsByRecordZoneID = newValue
            appendConfigureBlock { $0.optionsByRecordZoneID = newValue }
        }
    }

    /// - returns: a block for when a record is changed
    public var recordChangedBlock: FetchRecordZoneChangesRecordChangedBlock? {
        get { return current.recordChangedBlock }
        set {
            current.recordChangedBlock = newValue
            appendConfigureBlock { $0.recordChangedBlock = newValue }
        }
    }

    /// - returns: a block for when a recordID is deleted (receives the recordID and the recordType)
    public var recordWithIDWasDeletedBlock: FetchRecordZoneChangesRecordWithIDWasDeletedBlock? {
        get { return current.recordWithIDWasDeletedBlock }
        set {
            current.recordWithIDWasDeletedBlock = newValue
            appendConfigureBlock { $0.recordWithIDWasDeletedBlock = newValue }
        }
    }

    /// - returns: a block for when a recordZone changeToken update is sent
    public var recordZoneChangeTokensUpdatedBlock: FetchRecordZoneChangesRecordZoneChangeTokensUpdatedBlock? {
        get { return current.recordZoneChangeTokensUpdatedBlock }
        set {
            current.recordZoneChangeTokensUpdatedBlock = newValue
            appendConfigureBlock { $0.recordZoneChangeTokensUpdatedBlock = newValue }
        }
    }

    /// - returns: a block to execute when the fetch for a zone has completed
    public var recordZoneFetchCompletionBlock: FetchRecordZoneChangesCompletionRecordZoneFetchCompletionBlock? {
        get { return current.recordZoneFetchCompletionBlock }
        set {
            current.recordZoneFetchCompletionBlock = newValue
            appendConfigureBlock { $0.recordZoneFetchCompletionBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchRecordZoneChangesCompletionBlock block
     */
    public func setFetchRecordZoneChangesCompletionBlock(block: @escaping FetchRecordZoneChangesCompletionBlock) {
        appendConfigureBlock { $0.setFetchRecordZoneChangesCompletionBlock(block) }
    }
}
