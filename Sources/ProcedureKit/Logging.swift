//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

/**
 Log Severity

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

// MARK: - Logger Block

/**
 A typealias for the argument to the logging block.
 */
public typealias LoggerInfo = (message: String, severity: LogSeverity, file: String, function: String, line: Int)

/**
 A typealias for a logging block. This is an easy way
 to pipe the message string into another logging system.
 */
public typealias LoggerBlockType = (LoggerInfo) -> Void

// MARK: - Log Manager

/**
 LogManagerProtocol

 This interface defines the protocol of a log manager, which is a
 singleton to control the global log settings.
 */
public protocol LogManagerProtocol {

    /// - returns: a bool to indicate if logging is enabled globally
    static var enabled: Bool { get set }

    /// - returns: the global LogSeverity
    static var severity: LogSeverity { get set }

    /// - returns: the global logger block type
    static var logger: LoggerBlockType { get set }

    /// - returns: all of the LogManagerProtocol values (as a tuple)
    static var allValues: (enabled: Bool, severity: LogSeverity, logger: LoggerBlockType) { get }
}

/**
 LogManager

 The log manager is responsible for holding the shared state required
 for the logger.
 */
public class LogManager: LogManagerProtocol {

    static func metadata(for file: String, function: String, line: Int) -> String {
        guard !file.contains("ProcedureKit") else { return "" }
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

    /**
     # Global acquire all LogManager values
     Acquire all LogManager values with a single lock acquisition.
     */
    public static var allValues: (enabled: Bool, severity: LogSeverity, logger: LoggerBlockType) {
        get { return sharedInstance.allValues }
    }

    static var sharedInstance = LogManager()

    static var queue: DispatchQueue {
        return sharedInstance.queue
    }

    let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.Logger", qos: .utility)

    var enabled: Bool {
        get { return stateLock.withCriticalScope { _enabled } }
        set { stateLock.withCriticalScope { _enabled = newValue } }
    }

    var severity: LogSeverity {
        get { return stateLock.withCriticalScope { _severity } }
        set { stateLock.withCriticalScope { _severity = newValue } }
    }

    var logger: LoggerBlockType {
        get { return stateLock.withCriticalScope { _logger } }
        set { stateLock.withCriticalScope { _logger = newValue } }
    }

    var enabledAndSeverity: (enabled: Bool, severity: LogSeverity) {
        get {
            return stateLock.withCriticalScope { (enabled: _enabled, severity: _severity) }
        }
    }

    var allValues: (enabled: Bool, severity: LogSeverity, logger: LoggerBlockType) {
        get {
            return stateLock.withCriticalScope { (enabled: _enabled, severity: _severity, logger: _logger) }
        }
    }

    init() {
        _enabled = true
        _severity = .warning
        _logger = { (info) in
            let (message, _, file, function, line) = info
            print("\(LogManager.metadata(for: file, function: function, line: line))\(message)")
        }
    }

    /// Private protected properties
    private let stateLock = PThreadMutex()
    private var _severity: LogSeverity
    private var _enabled: Bool
    private var _logger: LoggerBlockType
}

// MARK: - Logging

/**
 LoggerProtocol

 This is the protocol interface to different logger objects.
 ProcedureKit provides `Logger` a class which conforms to
 `LoggerProtocol`.
 */
public protocol LoggerProtocol {

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
    func log(message: @autoclosure () -> String, severity: LogSeverity, file: String, function: String, line: Int)
}

public extension LoggerProtocol {

    /// Access the minimum `LogSeverity` severity.
    internal var minimumLogSeverity: LogSeverity {
        return min(LogManager.severity, severity)
    }

    internal func messageWithOperationName(_ message: String) -> String {
        let name = operationName.map { "\($0): " } ?? ""
        return "\(name)\(message)"
    }

    /**
     Default log function

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
    func log(message: @autoclosure () -> String, severity: LogSeverity, file: String = #file, function: String = #function, line: Int = #line) {
        guard enabled && severity >= self.severity else { return }
        let _message = messageWithOperationName(message())
        LogManager.queue.async { [logger = self.logger] in
            logger(LoggerInfo(message: _message, severity: severity, file: file, function: function, line: line))
        }
    }

    /**
     Send a .verbose log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func verbose(message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, severity: .verbose, file: file, function: function, line: line)
    }

    /**
     Send a .notice log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func notice(message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, severity: .notice, file: file, function: function, line: line)
    }

    /**
     Send a .info log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func info(message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, severity: .info, file: file, function: function, line: line)
    }

    /**
     Send a .warning log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func warning(message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, severity: .warning, file: file, function: function, line: line)
    }

    /**
     Send a .fatal log message.

     - parameter message: a `String`, the message to log.
     - parameter file: a `String`, containing the file (make it default to #file)
     - parameter function: a `String`, containing the function (make it default to #function)
     - parameter line: a `Int`, containing the line number (make it default to #line)
     */
    func fatal(message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message: message, severity: .fatal, file: file, function: function, line: line)
    }
}

internal struct LoggerContext: LoggerProtocol {

    public var severity: LogSeverity

    public var enabled: Bool

    public var logger: LoggerBlockType

    public var operationName: String?

    public init(parent: LoggerProtocol, operationName name: String) {
        severity = parent.severity
        enabled = parent.enabled
        logger = parent.logger
        operationName = name
    }
}

public struct _Logger<M: LogManagerProtocol>: LoggerProtocol {

    typealias Manager = M

    public var severity: LogSeverity

    public var enabled: Bool

    public var logger: LoggerBlockType

    public var operationName: String?

    // break out the different inits to speed-up obtaining the current values from the Manager
    // (i.e. to only require a single lock)

    public init() {
        let managerValues = Manager.allValues
        self.severity = managerValues.severity
        self.enabled = managerValues.enabled
        self.logger = managerValues.logger
    }

    public init(severity: LogSeverity) {
        let managerValues = Manager.allValues
        self.severity = severity
        self.enabled = managerValues.enabled
        self.logger = managerValues.logger
    }

    public init(severity: LogSeverity, enabled: Bool) {
        let managerValues = Manager.allValues
        self.severity = severity
        self.enabled = enabled
        self.logger = managerValues.logger
    }

    public init(severity: LogSeverity, logger: @escaping LoggerBlockType) {
        self.severity = severity
        self.enabled = Manager.enabled
        self.logger = logger
    }

    public init(severity: LogSeverity, enabled: Bool, logger: @escaping LoggerBlockType) {
        self.severity = severity
        self.enabled = enabled
        self.logger = logger
    }

    public init(enabled: Bool) {
        let managerValues = Manager.allValues
        self.severity = managerValues.severity
        self.enabled = enabled
        self.logger = managerValues.logger
    }

    public init(enabled: Bool, logger: @escaping LoggerBlockType) {
        let managerValues = Manager.allValues
        self.severity = managerValues.severity
        self.enabled = enabled
        self.logger = logger
    }

    public init(logger: @escaping LoggerBlockType) {
        let managerValues = Manager.allValues
        self.severity = managerValues.severity
        self.enabled = managerValues.enabled
        self.logger = logger
    }
}

public typealias Logger = _Logger<LogManager>
