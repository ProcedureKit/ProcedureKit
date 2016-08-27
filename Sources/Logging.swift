//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

// MARK: - Logging

/**
 # Log Severity
 The log severity of the message, ranging from .Verbose
 through to .Fatal.

 The severity of a message is one side of an equality, the other
 being the minimum between either the global severity or the
 severity of an instance logger. If the message severity
 is greater than the minimum severity the message string will
 be sent to the logger's block.
 */
@objc public enum LogSeverity: Int, Comparable {

    public static func < (lhs: LogSeverity, rhs: LogSeverity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    /// Chatty
    case verbose = 0

    /// Public Service Announcements
    case notice

    /// Info Bulletin
    case info

    /// Careful, Errors Occurring
    case warning

    /// Everything Is On Fire
    case fatal
}
