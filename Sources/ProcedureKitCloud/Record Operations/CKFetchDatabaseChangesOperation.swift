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

/// A generic protocol which exposes the properties used by Apple's CloudKit Operation's which have a flag to fetch all changes.
public protocol CKFetchAllChanges: CKOperationProtocol {

    /// - returns: whether there are more results on the server
    var fetchAllChanges: Bool { get set }
}

extension CKProcedure where T: CKFetchAllChanges {

    var fetchAllChanges: Bool {
        get { return operation.fetchAllChanges }
        set { operation.fetchAllChanges = newValue }
    }
}

extension CloudKitProcedure where T: CKFetchAllChanges {

    /// - returns: the previous server change token
    public var fetchAllChanges: Bool {
        get { return current.fetchAllChanges }
        set {
            current.fetchAllChanges = newValue
            appendConfigureBlock { $0.fetchAllChanges = newValue }
        }
    }
}

/// A generic protocol which exposes the properties used by Apple's CKFetchDatabaseChangesOperationType.
public protocol CKFetchDatabaseChangesOperationProtocol: CKDatabaseOperationProtocol, CKFetchAllChanges, CKPreviousServerChangeToken, CKResultsLimit {

    /// - returns: a block for when a the changeToken is updated
    var changeTokenUpdatedBlock: ((ServerChangeToken) -> Void)? { get set }

    /// - returns: a block for when a recordZone was changed
    var recordZoneWithIDChangedBlock: ((RecordZoneID) -> Void)? { get set }

    /// - returns: a block for when a recordZone was deleted
    var recordZoneWithIDWasDeletedBlock: ((RecordZoneID) -> Void)? { get set }

    /// - returns: the completion for fetching database changes
    var fetchDatabaseChangesCompletionBlock: ((ServerChangeToken?, Bool, Error?) -> Void)? { get set }
}

public struct FetchDatabaseChangesError<ServerChangeToken>: CloudKitError {
    public let underlyingError: Error
    public let token: ServerChangeToken?
    public let moreComing: Bool
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKFetchDatabaseChangesOperation: CKFetchDatabaseChangesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = FetchDatabaseChangesError<ServerChangeToken>
}

extension CKProcedure where T: CKFetchDatabaseChangesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var recordZoneWithIDChangedBlock: CloudKitProcedure<T>.FetchDatabaseChangesRecordZoneWithIDChangedBlock? {
        get { return operation.recordZoneWithIDChangedBlock }
        set { operation.recordZoneWithIDChangedBlock = newValue }
    }

    public var recordZoneWithIDWasDeletedBlock: CloudKitProcedure<T>.FetchDatabaseChangesRecordZoneWithIDWasDeletedBlock? {
        get { return operation.recordZoneWithIDWasDeletedBlock }
        set { operation.recordZoneWithIDWasDeletedBlock = newValue }
    }

    public var changeTokenUpdatedBlock: CloudKitProcedure<T>.FetchDatabaseChangesChangeTokenUpdatedBlock? {
        get { return operation.changeTokenUpdatedBlock }
        set { operation.changeTokenUpdatedBlock = newValue }
    }

    func setFetchDatabaseChangesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchDatabaseChangesCompletionBlock) {
        operation.fetchDatabaseChangesCompletionBlock = { [weak self] (serverChangeToken, moreComing, error) in
            if let strongSelf = self, let error = error {
                strongSelf.setErrorOnce(FetchDatabaseChangesError(underlyingError: error, token: serverChangeToken, moreComing: moreComing))
            }
            else {
                block(serverChangeToken, moreComing)
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchDatabaseChangesOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKFetchDatabaseChangesOperationType>
    public typealias FetchDatabaseChangesRecordZoneWithIDChangedBlock = (T.RecordZoneID) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchDatabaseChangesOperationType>
    public typealias FetchDatabaseChangesRecordZoneWithIDWasDeletedBlock = (T.RecordZoneID) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchDatabaseChangesOperationType>
    public typealias FetchDatabaseChangesChangeTokenUpdatedBlock = (T.ServerChangeToken) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchDatabaseChangesOperationType>
    public typealias FetchDatabaseChangesCompletionBlock = (T.ServerChangeToken?, Bool) -> Void

    /// - returns: a block for when a record is changed
    public var recordZoneWithIDChangedBlock: FetchDatabaseChangesRecordZoneWithIDChangedBlock? {
        get { return current.recordZoneWithIDChangedBlock }
        set {
            current.recordZoneWithIDChangedBlock = newValue
            appendConfigureBlock { $0.recordZoneWithIDChangedBlock = newValue }
        }
    }

    /// - returns: a block for when a recordID is deleted (receives the recordID and the recordType)
    public var recordZoneWithIDWasDeletedBlock: FetchDatabaseChangesRecordZoneWithIDWasDeletedBlock? {
        get { return current.recordZoneWithIDWasDeletedBlock }
        set {
            current.recordZoneWithIDWasDeletedBlock = newValue
            appendConfigureBlock { $0.recordZoneWithIDWasDeletedBlock = newValue }
        }
    }

    /// - returns: a block for when a recordZone changeToken update is sent
    public var changeTokenUpdatedBlock: FetchDatabaseChangesChangeTokenUpdatedBlock? {
        get { return current.changeTokenUpdatedBlock }
        set {
            current.changeTokenUpdatedBlock = newValue
            appendConfigureBlock { $0.changeTokenUpdatedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchDatabaseChangesCompletionBlock block
     */
    public func setFetchDatabaseChangesCompletionBlock(block: @escaping FetchDatabaseChangesCompletionBlock) {
        appendConfigureBlock { $0.setFetchDatabaseChangesCompletionBlock(block) }
    }
}
