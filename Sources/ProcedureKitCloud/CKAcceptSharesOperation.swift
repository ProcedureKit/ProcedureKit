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

/// A generic protocol which exposes the properties used by Apple's CKAcceptSharesOperation.
public protocol CKAcceptSharesOperationProtocol: CKOperationProtocol {

    /// The type of the shareMetadatas property
    associatedtype ShareMetadatasPropertyType

    /// - returns: the share metadatas
    var shareMetadatas: ShareMetadatasPropertyType { get set }

    /// - returns: the block used to return accepted shares
    var perShareCompletionBlock: ((ShareMetadata, Share?, Swift.Error?) -> Void)? { get set }

    /// - returns: the completion block used for accepting shares
    var acceptSharesCompletionBlock: ((Swift.Error?) -> Void)? { get set }
}

@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension CKAcceptSharesOperation: CKAcceptSharesOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}

extension CKProcedure where T: CKAcceptSharesOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var shareMetadatas: T.ShareMetadatasPropertyType {
        get { return operation.shareMetadatas }
        set { operation.shareMetadatas = newValue }
    }

    public var perShareCompletionBlock: CloudKitProcedure<T>.AcceptSharesPerShareCompletionBlock? {
        get { return operation.perShareCompletionBlock }
        set { operation.perShareCompletionBlock = newValue }
    }

    func setAcceptSharesCompletionBlock(_ block: @escaping CloudKitProcedure<T>.AcceptSharesCompletionBlock) {
        operation.acceptSharesCompletionBlock = { [weak self] error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: PKCKError(underlyingError: error))
            }
            else {
                block()
            }
        }
    }
}

extension CloudKitProcedure where T: CKAcceptSharesOperationProtocol {

    /// A typealias for the block type used by CloudKitOperation<CKAcceptSharesOperationType>
    public typealias AcceptSharesPerShareCompletionBlock = (T.ShareMetadata, T.Share?, Error?) -> Void

    /// A typealias for the block type used by CloudKitOperation<CKAcceptSharesOperationType>
    public typealias AcceptSharesCompletionBlock = () -> Void

    /// - returns: the share metadatas
    public var shareMetadatas: T.ShareMetadatasPropertyType {
        get { return current.shareMetadatas }
        set {
            current.shareMetadatas = newValue
            appendConfigureBlock { $0.shareMetadatas = newValue }
        }
    }

    /// - returns: the block used to return accepted shares
    public var perShareCompletionBlock: AcceptSharesPerShareCompletionBlock? {
        get { return current.perShareCompletionBlock }
        set {
            current.perShareCompletionBlock = newValue
            appendConfigureBlock { $0.perShareCompletionBlock = newValue }
        }
    }

    /**
     Before adding the CloudKitOperation instance to a queue, set a completion block
     to collect the results in the successful case. Setting this completion block also
     ensures that error handling gets triggered.

     - parameter block: an AcceptSharesCompletionBlock block
     */
    public func setAcceptSharesCompletionBlock(block: @escaping AcceptSharesCompletionBlock) {
        appendConfigureBlock { $0.setAcceptSharesCompletionBlock(block) }
    }
}
