//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if !os(watchOS)

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKModifySubscriptionsOperation.
public protocol CKModifySubscriptionsOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the subscriptions to save
    var subscriptionsToSave: [Subscription]? { get set }

    /// - returns: the subscriptions IDs to delete
    var subscriptionIDsToDelete: [String]? { get set }

    /// - returns: the modify subscription completion block
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, Error?) -> Void)? { get set }
}

public struct ModifySubscriptionsError<Subscription, SubscriptionID>: CloudKitError, CloudKitBatchModifyError {

    public let underlyingError: Error
    public let saved: [Subscription]?
    public let deleted: [SubscriptionID]?
}

extension CKModifySubscriptionsOperation: CKModifySubscriptionsOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = ModifySubscriptionsError<Subscription, String>
}

extension CKProcedure where T: CKModifySubscriptionsOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var subscriptionsToSave: [T.Subscription]? {
        get { return operation.subscriptionsToSave }
        set { operation.subscriptionsToSave = newValue }
    }

    public var subscriptionIDsToDelete: [String]? {
        get { return operation.subscriptionIDsToDelete }
        set { operation.subscriptionIDsToDelete = newValue }
    }

    func setModifySubscriptionsCompletionBlock(_ block: @escaping CloudKitProcedure<T>.ModifySubscriptionsCompletionBlock) {
        operation.modifySubscriptionsCompletionBlock = { [weak self] saved, deleted, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: ModifySubscriptionsError(underlyingError: error, saved: saved, deleted: deleted))
            }
            else {
                block(saved, deleted)
            }
        }
    }
}

extension CloudKitProcedure where T: CKModifySubscriptionsOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKModifySubscriptionsOperation>
    public typealias ModifySubscriptionsCompletionBlock = ([T.Subscription]?, [String]?) -> Void

    /// - returns: the subscriptions to save
    public var subscriptionsToSave: [T.Subscription]? {
        get { return current.subscriptionsToSave }
        set {
            current.subscriptionsToSave = newValue
            appendConfigureBlock { $0.subscriptionsToSave = newValue }
        }
    }

    /// - returns: the subscription IDs to delete
    public var subscriptionIDsToDelete: [String]? {
        get { return current.subscriptionIDsToDelete }
        set {
            current.subscriptionIDsToDelete = newValue
            appendConfigureBlock { $0.subscriptionIDsToDelete = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a ModifySubscriptionsCompletionBlock block
     */
    public func setModifySubscriptionsCompletionBlock(block: @escaping ModifySubscriptionsCompletionBlock) {
        appendConfigureBlock { $0.setModifySubscriptionsCompletionBlock(block) }
    }
}

#endif
