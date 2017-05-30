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

/// A generic protocol which exposes the properties used by Apple's CKFetchNotificationChangesOperation.
public protocol CKFetchNotificationChangesOperationProtocol: CKFetchOperation {

    /// - returns: the block invoked when there are notification changes.
    var notificationChangedBlock: ((Notification) -> Void)? { get set }

    /// - returns: the completion block used for notification changes.
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, Error?) -> Void)? { get set }
}

public struct FetchNotificationChangesError<ServerChangeToken>: CloudKitError {
    public let underlyingError: Error
    public let token: ServerChangeToken?
}

extension CKFetchNotificationChangesOperation: CKFetchNotificationChangesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = FetchNotificationChangesError<ServerChangeToken>
}

extension CKProcedure where T: CKFetchNotificationChangesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var notificationChangedBlock: CloudKitProcedure<T>.FetchNotificationChangesChangedBlock? {
        get { return operation.notificationChangedBlock }
        set { operation.notificationChangedBlock = newValue }
    }

    func setFetchNotificationChangesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchNotificationChangesCompletionBlock) {

        operation.fetchNotificationChangesCompletionBlock = { [weak self] token, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: FetchNotificationChangesError(underlyingError: error, token: token))
            }
            else {
                block(token)
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchNotificationChangesOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKFetchNotificationChangesOperation>
    public typealias FetchNotificationChangesChangedBlock = (T.Notification) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchNotificationChangesOperation>
    public typealias FetchNotificationChangesCompletionBlock = (T.ServerChangeToken?) -> Void

    /// - returns: the notification changed block
    public var notificationChangedBlock: FetchNotificationChangesChangedBlock? {
        get { return current.notificationChangedBlock }
        set {
            current.notificationChangedBlock = newValue
            appendConfigureBlock { $0.notificationChangedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchNotificationChangesCompletionBlock block
     */
    public func setFetchNotificationChangesCompletionBlock(block: @escaping FetchNotificationChangesCompletionBlock) {
        appendConfigureBlock { $0.setFetchNotificationChangesCompletionBlock(block) }
    }
}
