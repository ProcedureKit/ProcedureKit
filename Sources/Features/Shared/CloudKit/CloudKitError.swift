//
//  CloudKitError.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/04/2016.
//
//

import Foundation
import CloudKit

/// An error type for CloudKit errors.
public protocol CloudKitErrorType: ErrorProtocol {

    /// - returns: the original NSError received from CloudKit
    var underlyingError: NSError { get }

    /// - returns: an operation Delay, used to indicate how long to wait until retry
    var retryAfterDelay: Delay? { get }
}

public extension CloudKitErrorType {

    var code: CKErrorCode? {
        return CKErrorCode(rawValue: underlyingError.code)
    }

    var retryAfterDelay: Delay? {
        return (underlyingError.userInfo[CKErrorRetryAfterKey] as? NSNumber).map { Delay.by($0.doubleValue) }
    }
}

public struct CloudKitError: CloudKitErrorType {

    public let underlyingError: NSError

    init(error: NSError) {
        underlyingError = error
    }
}
