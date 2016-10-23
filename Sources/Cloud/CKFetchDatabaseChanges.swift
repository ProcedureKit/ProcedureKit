//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

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
                strongSelf.append(fatalError: FetchNotificationChangesError(underlyingError: error, token: token))
            }
            else {
                block(token)
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchNotificationChangesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

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
