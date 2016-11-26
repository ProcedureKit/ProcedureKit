//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import CloudKit

/// An error protocol for CloudKit errors.
public protocol CloudKitError: Error {

    /// - returns: the original NSError received from CloudKit
    var underlyingError: Error { get }

    /// - returns: an operation Delay, used to indicate how long to wait until retry
    var retryAfterDelay: Delay? { get }
}

/// Public extensions to extract useful error information
public extension CloudKitError {

    internal var underlyingNSError: NSError {
        return underlyingError as NSError
    }

    /// - returns: the CKErrorCode if possible
    var code: CKError.Code? {
        return CKError.Code(rawValue: underlyingNSError.code)
    }

    /// - returns: an optional Delay, if the underlying error's user info contains CKErrorRetryAfterKey
    var retryAfterDelay: Delay? {
        return (underlyingNSError.userInfo[CKErrorRetryAfterKey] as? NSNumber).flatMap { .by($0.doubleValue) }
    }
}

// MARK: - Concrete types

public struct PKCKError: CloudKitError {
    public let underlyingError: Error
}
