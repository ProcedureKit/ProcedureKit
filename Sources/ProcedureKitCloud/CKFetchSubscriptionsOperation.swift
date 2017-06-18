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

/// A generic protocol which exposes the properties used by Apple's CKFetchSubscriptionsOperation.
public protocol CKFetchSubscriptionsOperationProtocol: CKDatabaseOperationProtocol {

    /// - returns: the subscription IDs
    var subscriptionIDs: [String]? { get set }

    /// - returns: the fetch subscription completion block
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, Error?) -> Void)? { get set }
}

public struct FetchSubscriptionsError<Subscription>: CloudKitError {

    public let underlyingError: Error
    public let subscriptionsByID: [String: Subscription]?
}

extension CKFetchSubscriptionsOperation: CKFetchSubscriptionsOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = FetchSubscriptionsError<Subscription>
}

extension CKProcedure where T: CKFetchSubscriptionsOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var subscriptionIDs: [String]? {
        get { return operation.subscriptionIDs }
        set { operation.subscriptionIDs = newValue }
    }

    func setFetchSubscriptionCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchSubscriptionCompletionBlock) {
        operation.fetchSubscriptionCompletionBlock = { [weak self] subscriptionsByID, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: FetchSubscriptionsError(underlyingError: error, subscriptionsByID: subscriptionsByID))
            }
            else {
                block(subscriptionsByID)
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchSubscriptionsOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKFetchSubscriptionsOperation>
    public typealias FetchSubscriptionCompletionBlock = ([String: T.Subscription]?) -> Void

    /// - returns: the subscription IDs
    public var subscriptionIDs: [String]? {
        get { return current.subscriptionIDs }
        set {
            current.subscriptionIDs = newValue
            appendConfigureBlock { $0.subscriptionIDs = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchSubscriptionCompletionBlock block
     */
    public func setFetchSubscriptionCompletionBlock(block: @escaping FetchSubscriptionCompletionBlock) {
        appendConfigureBlock { $0.setFetchSubscriptionCompletionBlock(block) }
    }
}

#endif
