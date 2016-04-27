//
//  CloudKitError.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/04/2016.
//
//

import Foundation
import CloudKit

public protocol CloudKitErrorType: ErrorType {

    var originalError: NSError { get }

    var retryAfterDelay: Delay? { get }
}

extension NSError: CloudKitErrorType {

    public var originalError: NSError {
        return self
    }

    public var retryAfterDelay: Delay? {
        return (userInfo[CKErrorRetryAfterKey] as? NSNumber).map { Delay.By($0.doubleValue) }
    }
}
