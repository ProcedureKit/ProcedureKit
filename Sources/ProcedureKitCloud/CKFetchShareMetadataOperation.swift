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

/// A generic protocol which exposes the properties used by Apple's CKFetchShareMetadataOperation.
public protocol CKFetchShareMetadataOperationProtocol: CKOperationProtocol {

    /// The type of the shareURLs property
    associatedtype ShareURLsPropertyType

    /// - returns: the share URLs
    var shareURLs: ShareURLsPropertyType { get set }

    /// - returns: whether to fetch the share root record
    var shouldFetchRootRecord: Bool { get set }

    /// - returns: the share root record desired keys
    var rootRecordDesiredKeys: [String]? { get set }

    /// - returns: the per share metadata block
    var perShareMetadataBlock: ((URL, ShareMetadata?, Error?) -> Void)? { get set }

    /// - returns: the fetch share metadata completion block
    var fetchShareMetadataCompletionBlock: ((Error?) -> Void)? { get set }
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKFetchShareMetadataOperation: CKFetchShareMetadataOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}

extension CKProcedure where T: CKFetchShareMetadataOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var shareURLs: T.ShareURLsPropertyType {
        get { return operation.shareURLs }
        set { operation.shareURLs = newValue }
    }

    public var shouldFetchRootRecord: Bool {
        get { return operation.shouldFetchRootRecord }
        set { operation.shouldFetchRootRecord = newValue }
    }

    public var rootRecordDesiredKeys: [String]? {
        get { return operation.rootRecordDesiredKeys }
        set { operation.rootRecordDesiredKeys = newValue }
    }

    public var perShareMetadataBlock: CloudKitProcedure<T>.FetchShareMetadataPerShareMetadataBlock? {
        get { return operation.perShareMetadataBlock }
        set { operation.perShareMetadataBlock = newValue }
    }

    func setFetchShareMetadataCompletionBlock(_ block: @escaping CloudKitProcedure<T>.FetchShareMetadataCompletionBlock) {
        operation.fetchShareMetadataCompletionBlock = { [weak self] error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: PKCKError(underlyingError: error))
            }
            else {
                block()
            }
        }
    }
}

extension CloudKitProcedure where T: CKFetchShareMetadataOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKFetchShareMetadataOperationType>
    public typealias FetchShareMetadataPerShareMetadataBlock = (URL, T.ShareMetadata?, Error?) -> Void

    /// A typealias for the block types used by CloudKitOperation<CKFetchShareMetadataOperationType>
    public typealias FetchShareMetadataCompletionBlock = () -> Void

    /// - returns: the share URLs
    public var shareURLs: T.ShareURLsPropertyType {
        get { return current.shareURLs }
        set {
            current.shareURLs = newValue
            appendConfigureBlock { $0.shareURLs = newValue }
        }
    }

    /// - returns: whether to fetch the share root record
    public var shouldFetchRootRecord: Bool {
        get { return current.shouldFetchRootRecord }
        set {
            current.shouldFetchRootRecord = newValue
            appendConfigureBlock { $0.shouldFetchRootRecord = newValue }
        }
    }

    /// - returns: the share root record desired keys
    public var rootRecordDesiredKeys: [String]? {
        get { return current.rootRecordDesiredKeys }
        set {
            current.rootRecordDesiredKeys = newValue
            appendConfigureBlock { $0.rootRecordDesiredKeys = newValue }
        }
    }

    /// - returns: the per share metadata block
    public var perShareMetadataBlock: FetchShareMetadataPerShareMetadataBlock? {
        get { return current.perShareMetadataBlock }
        set {
            current.perShareMetadataBlock = newValue
            appendConfigureBlock { $0.perShareMetadataBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: a FetchShareMetadataCompletionBlock block
     */
    public func setFetchShareMetadataCompletionBlock(block: @escaping FetchShareMetadataCompletionBlock) {
        appendConfigureBlock { $0.setFetchShareMetadataCompletionBlock(block) }
    }
}
