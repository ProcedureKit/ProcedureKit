//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if !os(tvOS)

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKDiscoverAllUserIdentitiesOperation.
public protocol CKDiscoverAllUserIdentitiesOperationProtocol: CKOperationProtocol {

    /// - returns: a block for when a user identity is discovered
    var userIdentityDiscoveredBlock: ((UserIdentity) -> Void)? { get set }

    /// - returns: the completion block used for discovering all user identities
    var discoverAllUserIdentitiesCompletionBlock: ((Error?) -> Void)? { get set }
}

@available(iOS 10.0, OSX 10.12, watchOS 3.0, *)
extension CKDiscoverAllUserIdentitiesOperation: CKDiscoverAllUserIdentitiesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}

extension CKProcedure where T: CKDiscoverAllUserIdentitiesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var userIdentityDiscoveredBlock: CloudKitProcedure<T>.DiscoverAllUserIdentitiesUserIdentityDiscoveredBlock? {
        get { return operation.userIdentityDiscoveredBlock }
        set { operation.userIdentityDiscoveredBlock = newValue }
    }

    func setDiscoverAllUserIdentitiesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.DiscoverAllUserIdentitiesCompletionBlock) {
        operation.discoverAllUserIdentitiesCompletionBlock = { [weak self] error in
            if let strongSelf = self, let error = error {
                strongSelf.setErrorOnce(PKCKError(underlyingError: error))
            }
            else {
                block()
            }
        }
    }
}

extension CloudKitProcedure where T: CKDiscoverAllUserIdentitiesOperationProtocol {

    /// A typealias for the block type used by CloudKitOperation<CKDiscoverAllUserIdentitiesOperationType>
    public typealias DiscoverAllUserIdentitiesUserIdentityDiscoveredBlock = (T.UserIdentity) -> Void

    /// A typealias for the block type used by CloudKitOperation<CKDiscoverAllUserIdentitiesOperationType>
    public typealias DiscoverAllUserIdentitiesCompletionBlock = () -> Void

    /// - returns: a block for when a recordZone changeToken update is sent
    public var userIdentityDiscoveredBlock: DiscoverAllUserIdentitiesUserIdentityDiscoveredBlock? {
        get { return current.userIdentityDiscoveredBlock }
        set {
            current.userIdentityDiscoveredBlock = newValue
            appendConfigureBlock { $0.userIdentityDiscoveredBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a DiscoverAllContactsCompletionBlock block
     */
    public func setDiscoverAllUserIdentitiesCompletionBlock(block: @escaping DiscoverAllUserIdentitiesCompletionBlock) {
        appendConfigureBlock { $0.setDiscoverAllUserIdentitiesCompletionBlock(block) }
    }
}

#endif
