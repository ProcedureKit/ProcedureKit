//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordChangesOperation.
public protocol CKFetchRecordChangesOperationProtocol: CKDatabaseOperationProtocol, CKFetchOperation, CKDesiredKeys {

    /// The type of the recordZoneID property
    associatedtype RecordZoneIDPropertyType

    /// - returns: the record zone ID whcih will fetch changes
    var recordZoneID: RecordZoneIDPropertyType { get set }

    /// - returns: a block for when a record is changed
    var recordChangedBlock: ((Record) -> Void)? { get set }

    /// - returns: a block for when a record with ID
    var recordWithIDWasDeletedBlock: ((RecordID) -> Void)? { get set }

    /// - returns: the completion for fetching records
    var fetchRecordChangesCompletionBlock: ((ServerChangeToken?, Data?, Error?) -> Void)? { get set }
}

public struct FetchRecordChangesError<ServerChangeToken>: CloudKitError {

    public let underlyingError: Error
    public let token: ServerChangeToken?
    public let data: Data?
}

@available(iOS, introduced: 8.0, deprecated: 10.0, message: "Use CKFetchRecordZoneChangesOperation instead")
@available(OSX, introduced: 10.10, deprecated: 10.12, message: "Use CKFetchRecordZoneChangesOperation instead")
@available(tvOS, introduced: 8.0, deprecated: 10.0, message: "Use CKFetchRecordZoneChangesOperation instead")
@available(watchOS, introduced: 2.0, deprecated: 3.0, message: "Use CKFetchRecordZoneChangesOperation instead")
extension CKFetchRecordChangesOperation: CKFetchRecordChangesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = FetchRecordChangesError<ServerChangeToken>
}

extension CKProcedure where T: CKFetchRecordChangesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var recordZoneID: T.RecordZoneIDPropertyType {
        get { return operation.recordZoneID }
        set { operation.recordZoneID = newValue }
    }

    public var recordChangedBlock: CloudKitProcedure<T>.FetchRecordChangesRecordChangedBlock? {
        get { return operation.recordChangedBlock }
        set { operation.recordChangedBlock = newValue }
    }

    public var recordWithIDWasDeletedBlock: CloudKitProcedure<T>.FetchRecordChangesRecordDeletedBlock? {
        get { return operation.recordWithIDWasDeletedBlock }
        set { operation.recordWithIDWasDeletedBlock = newValue }
    }

    func setFetchRecordChangesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchRecordChangesCompletionBlock) {
        operation.fetchRecordChangesCompletionBlock = { [weak self] token, data, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: FetchRecordChangesError(underlyingError: error, token: token, data: data))
            }
            else {
                block(token, data)
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchRecordChangesOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordChangesOperation>
    public typealias FetchRecordChangesRecordChangedBlock = (T.Record) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordChangesOperation>
    public typealias FetchRecordChangesRecordDeletedBlock = (T.RecordID) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordChangesOperation>
    public typealias FetchRecordChangesCompletionBlock = (T.ServerChangeToken?, Data?) -> Void

    /// - returns: the record zone ID
    public var recordZoneID: T.RecordZoneIDPropertyType {
        get { return current.recordZoneID }
        set {
            current.recordZoneID = newValue
            appendConfigureBlock { $0.recordZoneID = newValue }
        }
    }

    /// - returns: a block for when a record changes
    public var recordChangedBlock: FetchRecordChangesRecordChangedBlock? {
        get { return current.recordChangedBlock }
        set {
            current.recordChangedBlock = newValue
            appendConfigureBlock { $0.recordChangedBlock = newValue }
        }
    }

    /// - returns: a block for when a record with ID is deleted
    public var recordWithIDWasDeletedBlock: FetchRecordChangesRecordDeletedBlock? {
        get { return current.recordWithIDWasDeletedBlock }
        set {
            current.recordWithIDWasDeletedBlock = newValue
            appendConfigureBlock { $0.recordWithIDWasDeletedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchRecordChangesCompletionBlock block
     */
    public func setFetchRecordChangesCompletionBlock(block: @escaping FetchRecordChangesCompletionBlock) {
        appendConfigureBlock { $0.setFetchRecordChangesCompletionBlock(block) }
    }
}
