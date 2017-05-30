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

/// A generic protocol which exposes the properties used by Apple's CKFetchRecordZonesOperation.
public protocol CKFetchRecordZonesOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the record zone IDs which will be fetched
    var recordZoneIDs: [RecordZoneID]? { get set }

    /// - returns: the completion block for fetching record zones
    var fetchRecordZonesCompletionBlock: (([RecordZoneID: RecordZone]?, Error?) -> Void)? { get set }
}

public struct FetchRecordZonesError<RecordZone, RecordZoneID: Hashable>: CloudKitError {

    public let underlyingError: Error
    public let zonesByID: [RecordZoneID: RecordZone]?
}

extension CKFetchRecordZonesOperation: CKFetchRecordZonesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = FetchRecordZonesError<RecordZone, RecordZoneID>
}

extension CKProcedure where T: CKFetchRecordZonesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var recordZoneIDs: [T.RecordZoneID]? {
        get { return operation.recordZoneIDs }
        set { operation.recordZoneIDs = newValue }
    }

    func setFetchRecordZonesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchRecordZonesCompletionBlock) {
        operation.fetchRecordZonesCompletionBlock = { [weak self] zonesByID, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: FetchRecordZonesError(underlyingError: error, zonesByID: zonesByID))
            }
            else {
                block(zonesByID)
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchRecordZonesOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKFetchRecordZonesOperation>
    public typealias FetchRecordZonesCompletionBlock = ([T.RecordZoneID: T.RecordZone]?) -> Void

    /// - returns: the record zone IDs
    public var recordZoneIDs: [T.RecordZoneID]? {
        get { return current.recordZoneIDs }
        set {
            current.recordZoneIDs = newValue
            appendConfigureBlock { $0.recordZoneIDs = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchRecordZonesCompletionBlock block
     */
    public func setFetchRecordZonesCompletionBlock(block: @escaping FetchRecordZonesCompletionBlock) {
        appendConfigureBlock { $0.setFetchRecordZonesCompletionBlock(block) }
    }
}
