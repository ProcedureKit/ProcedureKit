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

extension CKProcedure where T: CKModifyBadgeOperationProtocol, T: AssociatedErrorProtocol, T.AssociatedError: CloudKitError {

    public var badgeValue: Int {
        get { return operation.badgeValue }
        set { operation.badgeValue = newValue }
    }

    func setModifyBadgeCompletionBlock(_ block: @escaping CloudKitProcedure<T>.ModifyBadgeCompletionBlock) {
        operation.modifyBadgeCompletionBlock = { [weak self] error in
            if let strongSelf = self, let error = error {
                strongSelf.append(error: PKCKError(underlyingError: error))
            }
            else {
                block()
            }
        }
    }
}

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
