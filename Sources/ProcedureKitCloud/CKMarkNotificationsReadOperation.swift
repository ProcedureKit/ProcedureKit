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

/// A generic protocol which exposes the properties used by Apple's CKMarkNotificationsReadOperation.
public protocol CKMarkNotificationsReadOperationProtocol: CKOperationProtocol {

    /// The type of the notificationIDs property
    associatedtype NotificationIDsPropertyType

    /// - returns: the notification IDs
    var notificationIDs: NotificationIDsPropertyType { get set }

    /// - returns: the completion block used when marking notifications
    var markNotificationsReadCompletionBlock: (([NotificationID]?, Error?) -> Void)? { get set }
}

public struct MarkNotificationsReadError<NotificationID>: CloudKitError {

    public let underlyingError: Error
    public let marked: [NotificationID]?
}

extension CKMarkNotificationsReadOperation: CKMarkNotificationsReadOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = MarkNotificationsReadError<NotificationID>
}

extension CKProcedure where T: CKMarkNotificationsReadOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var notificationIDs: T.NotificationIDsPropertyType {
        get { return operation.notificationIDs }
        set { operation.notificationIDs = newValue }
    }

    func setMarkNotificationsReadCompletionBlock(_ block: @escaping CloudKitProcedure<T>.MarkNotificationsReadCompletionBlock) {
        operation.markNotificationsReadCompletionBlock = { [weak self] notificationIDs, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: MarkNotificationsReadError(underlyingError: error, marked: notificationIDs))
            }
            else {
                block(notificationIDs)
            }
        }
    }
}

extension CloudKitProcedure where T: CKMarkNotificationsReadOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKMarkNotificationsReadOperation>
    public typealias MarkNotificationsReadCompletionBlock = ([T.NotificationID]?) -> Void

    /// - returns: the notification IDs
    public var notificationIDs: T.NotificationIDsPropertyType {
        get { return current.notificationIDs }
        set {
            current.notificationIDs = newValue
            appendConfigureBlock { $0.notificationIDs = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a MarkNotificationReadCompletionBlock block
     */
    public func setMarkNotificationsReadCompletionBlock(block: @escaping MarkNotificationsReadCompletionBlock) {
        appendConfigureBlock { $0.setMarkNotificationsReadCompletionBlock(block) }
    }
}
