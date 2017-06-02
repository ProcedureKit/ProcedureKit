//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if !os(tvOS)

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKDiscoverAllContactsOperation.
public protocol CKDiscoverAllContactsOperationProtocol: CKOperationProtocol {

    /// - returns: the completion block used for discovering all contacts.
    var discoverAllContactsCompletionBlock: (([DiscoveredUserInfo]?, Error?) -> Void)? { get set }
}

public struct DiscoverAllContactsError<DiscoveredUserInfo>: CloudKitError {
    public let underlyingError: Error
    public let userInfo: [DiscoveredUserInfo]?
}

/// Extension to have CKDiscoverAllContactsOperation conform to CKDiscoverAllContactsOperationType
@available(iOS, introduced: 8.0, deprecated: 10.0, message: "Use CKDiscoverAllUserIdentitiesOperation instead")
@available(OSX, introduced: 10.10, deprecated: 10.12, message: "Use CKDiscoverAllUserIdentitiesOperation instead")
@available(watchOS, introduced: 2.0, deprecated: 3.0, message: "Use CKDiscoverAllUserIdentitiesOperation instead")
extension CKDiscoverAllContactsOperation: CKDiscoverAllContactsOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = DiscoverAllContactsError<DiscoveredUserInfo>
}

extension CKProcedure where T: CKDiscoverAllContactsOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    func setDiscoverAllContactsCompletionBlock(_ block: @escaping CloudKitProcedure<T>.DiscoverAllContactsCompletionBlock) {
        operation.discoverAllContactsCompletionBlock = { [weak self] userInfos, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: DiscoverAllContactsError(underlyingError: error, userInfo: userInfos))
            }
            else {
                block(userInfos)
            }
        }
    }
}

extension CloudKitProcedure where T: CKDiscoverAllContactsOperationProtocol {

    /// A typealias for the block type used by CloudKitOperation<CKDiscoverAllContactsOperation>
    public typealias DiscoverAllContactsCompletionBlock = ([T.DiscoveredUserInfo]?) -> Void

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a DiscoverAllContactsCompletionBlock block
     */
    public func setDiscoverAllContactsCompletionBlock(block: @escaping DiscoverAllContactsCompletionBlock) {
        appendConfigureBlock { $0.setDiscoverAllContactsCompletionBlock(block) }
    }
}

#endif
