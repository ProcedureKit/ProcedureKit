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

public struct QueryError<QueryCursor>: CloudKitError {

    public let underlyingError: Error
    public let cursor: QueryCursor?
}

extension CKQueryOperation: CKQueryOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = QueryError<QueryCursor>
}

extension CKProcedure where T: CKQueryOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var query: T.Query? {
        get { return operation.query }
        set { operation.query = newValue }
    }

    public var cursor: T.QueryCursor? {
        get { return operation.cursor }
        set { operation.cursor = newValue }
    }

    public var zoneID: T.RecordZoneID? {
        get { return operation.zoneID }
        set { operation.zoneID = newValue }
    }

    public var recordFetchedBlock: CloudKitProcedure<T>.QueryRecordFetchedBlock? {
        get { return operation.recordFetchedBlock }
        set { operation.recordFetchedBlock = newValue }
    }

    func setQueryCompletionBlock(_ block: @escaping CloudKitProcedure<T>.QueryCompletionBlock) {
        operation.queryCompletionBlock = { [weak self] cursor, error in
            if let strongSelf = self, let error = error {
                strongSelf.setErrorOnce(QueryError(underlyingError: error, cursor: cursor))
            }
            else {
                block(cursor)
            }
        }
    }
}

extension CloudKitProcedure where T: CKQueryOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKQueryOperation>
    public typealias QueryRecordFetchedBlock = (T.Record) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKQueryOperation>
    public typealias QueryCompletionBlock = (T.QueryCursor?) -> Void

    /// - returns: the query
    public var query: T.Query? {
        get { return current.query }
        set {
            current.query = newValue
            appendConfigureBlock { $0.query = newValue }
        }
    }

    /// - returns: the query cursor
    public var cursor: T.QueryCursor? {
        get { return current.cursor }
        set {
            current.cursor = newValue
            appendConfigureBlock { $0.cursor = newValue }
        }
    }

    /// - returns: the zone ID
    public var zoneID: T.RecordZoneID? {
        get { return current.zoneID }
        set {
            current.zoneID = newValue
            appendConfigureBlock { $0.zoneID = newValue }
        }
    }

    /// - returns: a block for each record fetched
    public var recordFetchedBlock: QueryRecordFetchedBlock? {
        get { return current.recordFetchedBlock }
        set {
            current.recordFetchedBlock = newValue
            appendConfigureBlock { $0.recordFetchedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a QueryCompletionBlock block
     */
    public func setQueryCompletionBlock(block: @escaping QueryCompletionBlock) {
        appendConfigureBlock { $0.setQueryCompletionBlock(block) }
    }
}
