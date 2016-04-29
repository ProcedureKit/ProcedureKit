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

public struct ModifyRecordZonesError<RecordZone, RecordZoneID>: CloudKitErrorType {

    public let error: NSError
    public let saved: [RecordZone]?
    public let deleted: [RecordZoneID]?

    init(error: NSError, saved: [RecordZone]?, deleted: [RecordZoneID]?) {
        self.error = error
        self.saved = saved
        self.deleted = deleted
    }
}

public struct ModifyRecordsError<Record, RecordID>: CloudKitErrorType {

    public let error: NSError
    public let saved: [Record]?
    public let deleted: [RecordID]?

    init(error: NSError, saved: [Record]?, deleted: [RecordID]?) {
        self.error = error
        self.saved = saved
        self.deleted = deleted
    }
}
