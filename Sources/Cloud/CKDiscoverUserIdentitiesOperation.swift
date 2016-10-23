//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKDiscoverUserIdentitiesOperation.
public protocol CKDiscoverUserIdentitiesOperationProtocol: CKOperationProtocol {

    /// - returns: the user identity lookup info used in discovery
    var userIdentityLookupInfos: [UserIdentityLookupInfo] { get set }

    /// - returns: the block used to return discovered user identities
    var userIdentityDiscoveredBlock: ((UserIdentity, UserIdentityLookupInfo) -> Void)? { get set }

    /// - returns: the completion block used for discovering user identities
    var discoverUserIdentitiesCompletionBlock: ((Error?) -> Void)? { get set }
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKDiscoverUserIdentitiesOperation: CKDiscoverUserIdentitiesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}

extension CKProcedure where T: CKDiscoverUserIdentitiesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var userIdentityLookupInfos: [T.UserIdentityLookupInfo] {
        get { return operation.userIdentityLookupInfos }
        set { operation.userIdentityLookupInfos = newValue }
    }

    public var userIdentityDiscoveredBlock: CloudKitProcedure<T>.DiscoverUserIdentitiesUserIdentityDiscoveredBlock? {
        get { return operation.userIdentityDiscoveredBlock }
        set { operation.userIdentityDiscoveredBlock = newValue }
    }

    func setDiscoverUserIdentitiesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.DiscoverUserIdentitiesCompletionBlock) {
        operation.discoverUserIdentitiesCompletionBlock = { [weak self] error in
            if let strongSelf = self, let error = error {
                strongSelf.append(fatalError: PKCKError(underlyingError: error))
            }
            else {
                block()
            }
        }
    }
}

extension CloudKitProcedure where T: CKDiscoverUserIdentitiesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    /// A typealias for the block type used by CloudKitOperation<CKDiscoverUserIdentitiesOperationType>
    public typealias DiscoverUserIdentitiesUserIdentityDiscoveredBlock = (T.UserIdentity, T.UserIdentityLookupInfo) -> Void

    /// A typealias for the block type used by CloudKitOperation<CKDiscoverUserIdentitiesOperationType>
    public typealias DiscoverUserIdentitiesCompletionBlock = () -> Void

    /// - returns: the user identity lookup info used in discovery
    public var userIdentityLookupInfos: [T.UserIdentityLookupInfo] {
        get { return current.userIdentityLookupInfos }
        set {
            current.userIdentityLookupInfos = newValue
            appendConfigureBlock { $0.userIdentityLookupInfos = newValue }
        }
    }

    /// - returns: the block used to return discovered user identities
    public var userIdentityDiscoveredBlock: DiscoverUserIdentitiesUserIdentityDiscoveredBlock? {
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

     - parameter block: a DiscoverUserIdentitiesCompletionBlock block
     */
    public func setDiscoverUserIdentitiesCompletionBlock(block: @escaping DiscoverUserIdentitiesCompletionBlock) {
        appendConfigureBlock { $0.setDiscoverUserIdentitiesCompletionBlock(block) }
    }
}
