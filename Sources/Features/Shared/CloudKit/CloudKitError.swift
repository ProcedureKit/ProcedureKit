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
public protocol CloudKitErrorType: ErrorType {

    /// - returns: the original NSError received from CloudKit
    var error: NSError { get }

    /// - returns: an operation Delay, used to indicate how long to wait until retry
    var retryAfterDelay: Delay? { get }
}

public extension CloudKitErrorType {

    var retryAfterDelay: Delay? {
        return (error.userInfo[CKErrorRetryAfterKey] as? NSNumber).map { Delay.By($0.doubleValue) }
    }
}

extension NSError: CloudKitErrorType {

    public var error: NSError {
        return self
    }
}
