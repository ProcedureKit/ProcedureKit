//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CloudKit

/// A generic protocol which exposes the properties used by Apple's CKModifyBadgeOperation.
public protocol CKModifyBadgeOperationProtocol: CKOperationProtocol {

    /// - returns: the badge value
    var badgeValue: Int { get set }

    /// - returns: the completion block used
    var modifyBadgeCompletionBlock: ((Error?) -> Void)? { get set }
}

extension CKModifyBadgeOperation: CKModifyBadgeOperationProtocol, AssociatedErrorProtocol {

    // The associated error type
    public typealias AssociatedError = PKCKError
}

@available(iOS, introduced: 8.0, deprecated: 11.0, message: "No longer supported, will cease working at some point in the future")
@available(OSX, introduced: 10.10, deprecated: 10.13, message: "No longer supported, will cease working at some point in the future")
@available(tvOS, introduced: 9.0, deprecated: 11.0, message: "No longer supported, will cease working at some point in the future")
@available(watchOS, introduced: 3.0, deprecated: 4.0, message: "No longer supported, will cease working at some point in the future")
extension CKProcedure where T: CKModifyBadgeOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var badgeValue: Int {
        get { return operation.badgeValue }
        set { operation.badgeValue = newValue }
    }

    func setModifyBadgeCompletionBlock(_ block: @escaping CloudKitProcedure<T>.ModifyBadgeCompletionBlock) {
        operation.modifyBadgeCompletionBlock = { [weak self] error in
            if let strongSelf = self, let error = error {
                strongSelf.setErrorOnce(PKCKError(underlyingError: error))
            }
            else {
                block()
            }
        }
    }
}

@available(iOS, introduced: 8.0, deprecated: 11.0, message: "No longer supported, will cease working at some point in the future")
@available(OSX, introduced: 10.10, deprecated: 10.13, message: "No longer supported, will cease working at some point in the future")
@available(tvOS, introduced: 9.0, deprecated: 11.0, message: "No longer supported, will cease working at some point in the future")
@available(watchOS, introduced: 3.0, deprecated: 4.0, message: "No longer supported, will cease working at some point in the future")
extension CloudKitProcedure where T: CKModifyBadgeOperationProtocol {

    /// A typealias for the block types used by CloudKitOperation<CKModifyBadgeOperation>
    public typealias ModifyBadgeCompletionBlock = () -> Void

    public var badgeValue: Int {
        get { return current.badgeValue }
        set {
            current.badgeValue = newValue
            appendConfigureBlock { $0.badgeValue = newValue }
        }
    }

    public func setModifyBadgeCompletionBlock(block: @escaping ModifyBadgeCompletionBlock) {
        appendConfigureBlock { $0.setModifyBadgeCompletionBlock(block) }
    }
}
