//
//  Logging.swift
//  Operations
//
//  Created by Daniel Thorpe on 09/11/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
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
public enum LogSeverity: Int, Comparable {

    /// Chatty
    case Verbose = 0

    /// Public Service Announcements
    case Notice

    /// Info Bulletin
    case Info

    /// Careful, Errors Occurring
    case Warning

    /// Everything Is On Fire
    case Fatal
}

public typealias LoggerInfo = (message: String, severity: LogSeverity, file: String, function: String, line: Int)

/**
 A typealias for a logging block. This is an easy way
 to pipe the message string into another logging system.
*/
public typealias LoggerBlockType = LoggerInfo -> Void

/**
 # LoggerType
 This is the protocol interface to different logger objects.
 The framework provides `Logger` a class which conforms to
 `LoggerType`.
*/
public protocol LoggerType {

    /// Access the block which receives the message to log.
    var logger: LoggerBlockType { get set }

    /// Get/Set the instance log level severity
    var severity: LogSeverity { get set }

    /// Enabled/Disable the instance logger
    var enabled: Bool { get set }

    /// Get/Set the name of the operation.
    var operationName: String? { get set }

    /**
     The primary log function. The main job of this method
     is to format the message, and send it to its logger
     block, but only if the level is > the minimum severity.

     - parameter message: a `String`, the message to log.
     - parameter severity: a `LogSeverity`, the level of the message.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
    */
    func log(@autoclosure message: () -> String, severity: LogSeverity, file: String, function: String, line: Int)
}

internal extension LoggerType {

    /// Access the minimum `LogSeverity` severity.
    var minimumLogSeverity: LogSeverity {
        return min(LogManager.severity, severity)
    }
}

public extension LoggerType {

    func messageWithOperationName(message: String) -> String {
        let name = operationName.map { "\($0): " } ?? ""
        return "\(name)\(message)"
    }

    /**
     # Default log function
     The default implementation will create a prefix from the file,
     function and line info. Only the last path component of the
     file is used. If the file is from the Operations framework
     itself, the prefix is empty. The idea here is that log output
     looks like this:

         $ [MyCustomOperation.swift doTheThing:56], This is my log message

     for an operation which is custom to the consumers app.

     For logs from within Operation's operations, e.g. `UserLocation`
     it looks like this:

         User Location: did start
         User Location updated last location: <+51.30971096,-0.12562101> +/- 10.00m (speed 0.00 mps / course -1.00) @ 10/11/2015, 16:06:32 Greenwich Mean Time
         User Location: did finish with no errors.

     - parameter message: a `String`, the message to log.
     - parameter severity: a `LogSeverity`, the level of the message.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
    */
    func log(@autoclosure message: () -> String, severity: LogSeverity, file: String = #file, function: String = #function, line: Int = #line) {
        if LogManager.enabled && enabled && severity >= minimumLogSeverity {
            let _message = messageWithOperationName(message())
            dispatch_async(LogManager.queue) {
                self.logger(message: _message, severity: severity, file: file, function: function, line: line)
            }
        }
    }

    /**
     Send a .Verbose log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
    */
    func verbose(@autoclosure message: () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, severity: .Verbose, file: file, function: function, line: line)
    }

    /**
     Send a .Notice log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func notice(@autoclosure message: () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, severity: .Notice, file: file, function: function, line: line)
    }

    /**
     Send a .Info log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func info(@autoclosure message: () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, severity: .Info, file: file, function: function, line: line)
    }

    /**
     Send a .Warning log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func warning(@autoclosure message: () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, severity: .Warning, file: file, function: function, line: line)
    }

    /**
     Send a .Fatal log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func fatal(@autoclosure message: () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, severity: .Fatal, file: file, function: function, line: line)
    }
}

public protocol LogManagerType {

    static var enabled: Bool { get set }

    static var severity: LogSeverity { get set }

    static var logger: LoggerBlockType { get set }
}

/**
 This is a simple class which owns a logging block. It can be subclassed
 if customization is required, but it is probably easier to customise the
 logger block.
*/
class _Logger<Manager: LogManagerType>: LoggerType {

    /// - returns: the log severity of this logger instance.
    var severity: LogSeverity

    /// - returns: a `Bool` to enable/disable this logger instance. Defaults to true
    var enabled: Bool

    /// - returns: a `LoggerBlockType` which receives the message to log
    var logger: LoggerBlockType

    /// - returns: a String?, the name of the operation.
    var operationName: String? = .None

    /**
     Initialize a new `Logger` instance.

     - parameter logger: a `LoggerBlockType` block.
     - parameter severity: a `LogSeverity`.
     - parameter enabled: a `Bool`.
    */
    required init(severity: LogSeverity = Manager.severity, enabled: Bool = Manager.enabled, logger: LoggerBlockType = Manager.logger) {
        self.severity = severity
        self.enabled = enabled
        self.logger = logger
    }
}

typealias Logger = _Logger<LogManager>

/**
 # LogManager
 The log manager is responsible for holding the shared state required
 for the logger.
*/
public class LogManager: LogManagerType {

    static func metadataForFile(file: String, function: String, line: Int) -> String {
        guard !file.containsString("Operations") else {
            return ""
        }
        let filename = (file as NSString).lastPathComponent
        return "[\(filename) \(function):\(line)], "
    }

    /**
     # Enabled Operation logging
     Enable or Disable built in logger. Default is enabled.
     */
    public static var enabled: Bool {
        get { return sharedInstance.enabled }
        set { sharedInstance.enabled = newValue }
    }

    /**
     # Global Log Severity
     Adjust the global log level severity.
    */
    public static var severity: LogSeverity {
        get { return sharedInstance.severity }
        set { sharedInstance.severity = newValue }
    }

    /**
     # Global logger block
     Set a custom logger block.
    */
    public static var logger: LoggerBlockType {
        get { return sharedInstance.logger }
        set { sharedInstance.logger = newValue }
    }

    static var sharedInstance = LogManager()

    static var queue: dispatch_queue_t {
        return sharedInstance.queue
    }

    let queue = Queue.Utility.serial("me.danthorpe.Operations.Logger")
    var enabled: Bool = true
    var severity: LogSeverity = .Warning
    var logger: LoggerBlockType = { message, severity, file, function, line in
        print("\(LogManager.metadataForFile(file, function: function, line: line))\(message)")
    }
}

public extension NSOperation {

    /**
     Returns a non-optional `String` to use as the name
     of an Operation. If the `name` property is not
     set, this resorts to the class description.
    */
    var operationName: String {
        return name ?? "Unnamed Operation"
    }
}

public func < (lhs: LogSeverity, rhs: LogSeverity) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
