//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

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
                strongSelf.append(fatalError: FetchDatabaseChangesError(underlyingError: error, token: serverChangeToken, moreComing: moreComing))
            }
            else {
                block(serverChangeToken, moreComing)
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchDatabaseChangesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

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
