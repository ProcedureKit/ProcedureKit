//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CloudKit

/// An error protocol for CloudKit errors.
public protocol CloudKitError: Error {

    /// - returns: the original NSError received from CloudKit
    var underlyingError: NSError { get }

    /// - returns: an operation Delay, used to indicate how long to wait until retry
    var retryAfterDelay: Delay? { get }
}

/// Public extensions to extract useful error information
public extension CloudKitError {

    /// - returns: the CKErrorCode if possible
    var code: CKError.Code? {
        return CKError.Code(rawValue: underlyingError.code)
    }

    /// - returns: an optional Delay, if the underlying error's user info contains CKErrorRetryAfterKey
    var retryAfterDelay: Delay? {
        return (underlyingError.userInfo[CKErrorRetryAfterKey] as? NSNumber).map { .by($0.doubleValue) }
    }
}

// MARK: - Batch Errors

/// An error protocol for batch modifying operations
public protocol CloudKitBatchModifyError: CloudKitError {
    associatedtype Save
    associatedtype Delete

    var saved: [Save]? { get }
    var deleted: [Delete]? { get }
}

/// An error protocol for batch processing operations
public protocol CloudKitBatchProcessError: CloudKitError {
    associatedtype Process

    var processed: [Process]? { get }
}

// MARK: - Concrete types

public struct PKCKError: CloudKitError {

    public let underlyingError: NSError

    init(error: NSError) {
        underlyingError = error
    }
}
