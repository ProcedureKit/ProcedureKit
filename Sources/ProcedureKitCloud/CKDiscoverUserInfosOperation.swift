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

/// A generic protocol which exposes the properties used by Apple's CKDiscoverUserInfosOperation.
public protocol CKDiscoverUserInfosOperationProtocol: CKOperationProtocol {

    /// - returns: the email addresses used in discovery
    var emailAddresses: [String]? { get set }

    /// - returns: the user record IDs
    var userRecordIDs: [RecordID]? { get set }

    /// - returns: the completion block used for discovering user infos
    var discoverUserInfosCompletionBlock: (([String: DiscoveredUserInfo]?, [RecordID: DiscoveredUserInfo]?, Error?) -> Void)? { get set }
}

public struct DiscoverUserInfosError<RecordID: Hashable, DiscoveredUserInfo>: CloudKitError {
    public let underlyingError: Error
    public let userInfoByEmail: [String: DiscoveredUserInfo]?
    public let userInfoByRecordID: [RecordID: DiscoveredUserInfo]?
}

@available(iOS, introduced: 8.0, deprecated: 10.0, message: "Use CKDiscoverUserIdentitiesOperation instead")
@available(OSX, introduced: 10.10, deprecated: 10.12, message: "Use CKDiscoverUserIdentitiesOperation instead")
@available(tvOS, introduced: 8.0, deprecated: 10.0, message: "Use CKDiscoverUserIdentitiesOperation instead")
@available(watchOS, introduced: 2.0, deprecated: 3.0, message: "Use CKDiscoverUserIdentitiesOperation instead")
extension CKDiscoverUserInfosOperation: CKDiscoverUserInfosOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = DiscoverUserInfosError<RecordID, DiscoveredUserInfo>
}

extension CKProcedure where T: CKDiscoverUserInfosOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var emailAddresses: [String]? {
        get { return operation.emailAddresses }
        set { operation.emailAddresses = newValue }
    }

    public var userRecordIDs: [T.RecordID]? {
        get { return operation.userRecordIDs }
        set { operation.userRecordIDs = newValue }
    }

    func setDiscoverUserInfosCompletionBlock(_ block: @escaping CloudKitProcedure<T>.DiscoverUserInfosCompletionBlock) {
        operation.discoverUserInfosCompletionBlock = { [weak self] userInfoByEmail, userInfoByRecordID, error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: DiscoverUserInfosError(underlyingError: error, userInfoByEmail: userInfoByEmail, userInfoByRecordID: userInfoByRecordID))
            }
            else {
                block(userInfoByEmail, userInfoByRecordID)
            }
        }
    }
}

extension CloudKitProcedure where T: CKDiscoverUserInfosOperationProtocol {

    /// A typealias for the block type used by CloudKitOperation<CKDiscoverUserInfosOperation>
    public typealias DiscoverUserInfosCompletionBlock = ([String: T.DiscoveredUserInfo]?, [T.RecordID: T.DiscoveredUserInfo]?) -> Void

    /// - returns: get or set the email addresses
    public var emailAddresses: [String]? {
        get { return current.emailAddresses }
        set {
            current.emailAddresses = newValue
            appendConfigureBlock { $0.emailAddresses = newValue }
        }
    }

    /// - returns: get or set the user records IDs
    public var userRecordIDs: [T.RecordID]? {
        get { return current.userRecordIDs }
        set {
            current.userRecordIDs = newValue
            appendConfigureBlock { $0.userRecordIDs = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a DiscoverUserInfosCompletionBlock block
     */
    public func setDiscoverUserInfosCompletionBlock(block: @escaping DiscoverUserInfosCompletionBlock) {
        appendConfigureBlock { $0.setDiscoverUserInfosCompletionBlock(block) }
    }
}
