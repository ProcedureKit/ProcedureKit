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

extension CKProcedure where T: CKFetchRecordsOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var recordIDs: [T.RecordID]? {
        get { return operation.recordIDs }
        set { operation.recordIDs = newValue }
    }

    public var perRecordProgressBlock: CloudKitProcedure<T>.FetchRecordsPerRecordProgressBlock? {
        get { return operation.perRecordProgressBlock }
        set { operation.perRecordProgressBlock = newValue }
    }

    public var perRecordCompletionBlock: CloudKitProcedure<T>.FetchRecordsPerRecordCompletionBlock? {
        get { return operation.perRecordCompletionBlock }
        set { operation.perRecordCompletionBlock = newValue }
    }

    func setFetchRecordsCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchRecordsCompletionBlock) {
        operation.fetchRecordsCompletionBlock = { [weak self] recordsByID, error in
            if let strongSelf = self, let error = error {
                strongSelf.setErrorOnce(FetchRecordsError(underlyingError: error, recordsByID: recordsByID))
            }
            else {
                block(recordsByID)
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchRecordsOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordsOperation>
    public typealias FetchRecordsPerRecordProgressBlock = (T.RecordID, Double) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordsOperation>
    public typealias FetchRecordsPerRecordCompletionBlock = (T.Record?, T.RecordID?, Error?) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordsOperation>
    public typealias FetchRecordsCompletionBlock = ([T.RecordID: T.Record]?) -> Void

    /// - returns: the record IDs
    public var recordIDs: [T.RecordID]? {
        get { return current.recordIDs }
        set {
            current.recordIDs = newValue
            appendConfigureBlock { $0.recordIDs = newValue }
        }
    }

    /// - returns: a block for the record progress
    public var perRecordProgressBlock: FetchRecordsPerRecordProgressBlock? {
        get { return current.perRecordProgressBlock }
        set {
            current.perRecordProgressBlock = newValue
            appendConfigureBlock { $0.perRecordProgressBlock = newValue }
        }
    }

    /// - returns: a block for the record completion
    public var perRecordCompletionBlock: FetchRecordsPerRecordCompletionBlock? {
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

     - parameter block: a FetchRecordsCompletionBlock block
     */
    public func setFetchRecordsCompletionBlock(block: @escaping FetchRecordsCompletionBlock) {
        appendConfigureBlock { $0.setFetchRecordsCompletionBlock(block) }
    }
}

