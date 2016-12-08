//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKFetchShareParticipantsOperation.
public protocol CKFetchShareParticipantsOperationProtocol: CKOperationProtocol {

    /// The type of the userIdentityLookupInfos property
    associatedtype UserIdentityLookupInfosPropertyType

    /// - returns: the user identity lookup infos
    var userIdentityLookupInfos: UserIdentityLookupInfosPropertyType { get set }

    /// - returns: the share participant fetched block
    var shareParticipantFetchedBlock: ((ShareParticipant) -> Void)? { get set }

    /// - returns: the fetch share participants completion block
    var fetchShareParticipantsCompletionBlock: ((Error?) -> Void)? { get set }
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKFetchShareParticipantsOperation: CKFetchShareParticipantsOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}

extension CKProcedure where T: CKFetchShareParticipantsOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var userIdentityLookupInfos: T.UserIdentityLookupInfosPropertyType {
        get { return operation.userIdentityLookupInfos }
        set { operation.userIdentityLookupInfos = newValue }
    }

    public var shareParticipantFetchedBlock: CloudKitProcedure<T>.FetchShareParticipantsParticipantFetchedBlock? {
        get { return operation.shareParticipantFetchedBlock }
        set { operation.shareParticipantFetchedBlock = newValue }
    }

    func setFetchShareParticipantsCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchShareParticipantsCompletionBlock) {
        operation.fetchShareParticipantsCompletionBlock = { [weak self] error in
            if let strongSelf = self, let error = error {
                strongSelf.append(fatalError: PKCKError(underlyingError: error))
            }
            else {
                block()
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchShareParticipantsOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    /// A typealias for the block types used by CloudKitOperation<CKFetchShareMetadataOperationType>
    public typealias FetchShareParticipantsParticipantFetchedBlock = (T.ShareParticipant) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchShareMetadataOperationType>
    public typealias FetchShareParticipantsCompletionBlock = (Void) -> Void

    /// - returns: the user identity lookup infos
    public var userIdentityLookupInfos: T.UserIdentityLookupInfosPropertyType {
        get { return current.userIdentityLookupInfos }
        set {
            current.userIdentityLookupInfos = newValue
            appendConfigureBlock { $0.userIdentityLookupInfos = newValue }
        }
    }

    /// - returns: the share participant fetched block
    public var shareParticipantFetchedBlock: FetchShareParticipantsParticipantFetchedBlock? {
        get { return current.shareParticipantFetchedBlock }
        set {
            current.shareParticipantFetchedBlock = newValue
            appendConfigureBlock { $0.shareParticipantFetchedBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchShareParticipantsCompletionBlock block
     */
    public func setFetchShareParticipantsCompletionBlock(block: @escaping FetchShareParticipantsCompletionBlock) {
        appendConfigureBlock { $0.setFetchShareParticipantsCompletionBlock(block) }
    }
}
