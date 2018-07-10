//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch
import os

public typealias LogMessage = String

public protocol LogWriter {

    func writeLog(with attributes: Log.Attributes, message: LogMessage)
}

public protocol LogMessageAdaptor {

    func adapt(message: LogMessage, with attributes: Log.Attributes) -> LogMessage
}

public protocol LogMessageAdaptorAggregator {

    var adaptors: [LogMessageAdaptor] { get }
}

public extension LogMessageAdaptorAggregator {

    func concat(message: LogMessage, with attributes: Log.Attributes) -> LogMessage {
        return adaptors.reduce("") {
            let adapted = $1.adapt(message: message, with: attributes)
            if $0.isEmpty {
                return adapted
            }
            return "\($0) \(adapted)"
        }
    }
}

public protocol LoggerProtocol: LogWriter, LogMessageAdaptorAggregator {

    var enabled: Bool { get set }

    var severity: Log.Severity { get set }

    var writers: [LogWriter] { get }

    var adaptors: [LogMessageAdaptor] { get set }
}

public extension LoggerProtocol {


    func writeLog(with attributes: Log.Attributes, message: LogMessage) {

        guard shouldLogMessage(given: attributes) else { return }

        Log.queue.async { [writers = self.writers, concat = self.concat(message:with:)] in

            // Adapt the message
            let adapted: LogMessage = concat(message, attributes)

            // Send it to the writers
            for w in writers {
                w.writeLog(with: attributes, message: adapted)
            }
        }
    }

    func writeLog(with attributes: Log.Attributes, message: @autoclosure () -> String) {
        writeLog(with: attributes, message: message())
    }
}

public class Log {

    @objc(LogSeverity)
    public enum Severity: Int, Comparable {

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }

        /// Reserved for chatty ProcedureKit framework level logging
        case verbose = 0

        /// Used by ProcedureKit for lifecycle level logging
        /// in non-production builds. Available to framework users
        case info

        /// Reserved for user activity events
        case event

        /// Reserved for caveman debugging
        case debug

        /// Errors are happening, but maybe recoverable
        case warning

        /// Everything is on fire
        case fatal
    }

    public struct Attributes {

        let severity: Severity

        let file: String

        let function: String

        let line: Int
    }

    public enum AdaptorStyle {
        case prepend, append, before, after
    }

    public static let defaultWriters: [LogWriter] = {
        var writers: [LogWriter] = []

        if #available(iOS 10.0, iOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *) {
            writers.append(OSLogWriter())
        } else {
            writers.append(PrintLogWriter())
        }

        return writers
    }()

    public static let defaultMessageAdaptors: [LogMessageAdaptor] = {
        var adaptors: [LogMessageAdaptor] = []


        return adaptors
    }()

    internal static var shared = Log()

    internal static var queue: DispatchQueue {
        return shared.queue
    }

    private let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.Logger", qos: .utility)

    private let stateLock = PThreadMutex()

    @discardableResult
    fileprivate func synchronise<T>(block: () -> T) -> T {
        return stateLock.withCriticalScope(block: block)
    }

    private var _enabled: Bool = true
    private var _severity: Severity = .info
    private var _writers: [LogWriter]
    private var _adaptors: [LogMessageAdaptor]

    fileprivate var enabled: Bool {
        get { return synchronise { _enabled } }
        set { synchronise { _enabled = newValue } }
    }

    fileprivate var severity: Severity {
        get { return synchronise { _severity } }
        set { synchronise { _severity = newValue } }
    }

    fileprivate var writers: [LogWriter] {
        get { return synchronise { _writers } }
        set { synchronise { _writers = newValue } }
    }

    fileprivate var adaptors: [LogMessageAdaptor] {
        get { return synchronise { _adaptors } }
        set { synchronise { _adaptors = newValue } }
    }


    fileprivate init() {
        _writers = Log.defaultWriters
        _adaptors = Log.defaultMessageAdaptors
    }

    fileprivate func appendWriter(_ writer: LogWriter) {
        synchronise { _writers.append(writer) }
    }

    fileprivate func removeAllWriters() {
        synchronise { _writers.removeAll() }
    }

    fileprivate func setWriter(_ writer: LogWriter) {
        synchronise {
            _writers.removeAll()
            _writers.append(writer)
        }
    }
}

public protocol GlobalLogSettingsProtocol {

    static var enabled: Bool { get set }

    static var severity: Log.Severity { get set }

    static var writers: [LogWriter] { get }

    static var adaptors: [LogMessageAdaptor] { get }
}


// MARK: - Global Log Settings

extension Log: GlobalLogSettingsProtocol {

    public static var enabled: Bool {
        get { return shared.enabled }
        set { shared.enabled = newValue }
    }

    public static var severity: Log.Severity {
        get { return shared.severity }
        set { shared.severity = newValue }
    }

    public static var adaptors: [LogMessageAdaptor] {
        return shared.adaptors
    }

    public static var writers: [LogWriter] {
        return shared.writers
    }

    public static func appendWriter(_ writer: LogWriter) {
        shared.appendWriter(writer)
    }

    public static func removeAllWriters() {
        shared.removeAllWriters()
    }

    public static func setWriter(_ writer: LogWriter) {
        shared.setWriter(writer)
    }
}



// MARK: - ProcedureKitLogger

public class ProcedureKitLogger<Global: GlobalLogSettingsProtocol>: LoggerProtocol {

    public var enabled: Bool

    public var severity: Log.Severity

    public let writers: [LogWriter]

    public var adaptors: [LogMessageAdaptor]

    public init(enabled: Bool = Global.enabled, severity: Log.Severity = Global.severity, writers: [LogWriter] = Global.writers, adaptors: [LogMessageAdaptor] = Global.adaptors) {
        self.enabled = enabled
        self.severity = severity
        self.writers = writers
        self.adaptors = adaptors
    }
}

public typealias Logger = ProcedureKitLogger<Log>

// MARK: - OS Log Writer

@available(iOS 10.0, iOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *)
internal extension Log.Severity {

    var logType: OSLogType {
        switch self {
        case .warning, .fatal:
            return OSLogType.default
        case .debug:
            return OSLogType.debug
        default:
            return OSLogType.info
        }
    }
}

@available(iOS 10.0, iOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *)
internal extension OSLog {

    static let procedure = OSLog(subsystem: "run.kit.procedure", category: "ProcedureKit")
}

@available(iOS 10.0, iOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *)
internal class OSLogWriter: LogWriter {

    let log: OSLog

    init(log: OSLog = .procedure) {
        self.log = log
    }

    func writeLog(with attributes: Log.Attributes, message: LogMessage) {
        os_log("%{public}@", log: log, type: attributes.severity.logType, message)
    }
}

// MARK: - Print Log Writer

internal class PrintLogWriter: LogWriter {

    func writeLog(with attributes: Log.Attributes, message: LogMessage) {
        print(message)
    }
}

// MARK: - Adaptors

public extension Log {

    public struct MessageAdaptors {

        public class Aggregator: LogMessageAdaptorAggregator, LogMessageAdaptor {

            let style: Log.AdaptorStyle
            public let adaptors: [LogMessageAdaptor]

            public init(style: Log.AdaptorStyle, adaptors: [LogMessageAdaptor]) {
                self.style = style
                self.adaptors = adaptors
            }

            public func adapt(message: LogMessage, with attributes: Log.Attributes) -> LogMessage {

                let adaption: LogMessage = concat(message: message, with: attributes)

                switch style {
                case .prepend:
                    return "\(adaption) → \(message)"
                case .append:
                    return "\(message) → \(adaption)"
                case .before:
                    return "\(adaption)↴\n\(message)"
                case .after:
                    return "\(message)\n↳\(adaption)"
                }
            }
        }

        public class Severity: LogMessageAdaptor {

            public func adapt(message: LogMessage, with attributes: Log.Attributes) -> LogMessage {
                switch attributes.severity {
                case .verbose:
                    return "▪️"
                case .info:
                    return "🔷"
                case .event:
                    return "🔶"
                case .debug:
                    return "◽️"
                case .warning:
                    return "⚠️"
                case .fatal:
                    return "❌"
                }
            }
        }

        public class Literal: LogMessageAdaptor {
            let literal: String
            public init(_ literal: String) {
                self.literal = literal
            }

            public func adapt(message: LogMessage, with attributes: Log.Attributes) -> LogMessage {
                return literal
            }
        }
    }
}

internal extension LoggerProtocol {

    mutating func setDefaultAdaptors(withOperationName operationName: String) {

        let prependers: [LogMessageAdaptor] = [
            Log.MessageAdaptors.Severity() as LogMessageAdaptor,
            Log.MessageAdaptors.Literal(operationName) as LogMessageAdaptor
        ]

        adaptors = [
            Log.MessageAdaptors.Aggregator(style: .prepend, adaptors: prependers) as LogMessageAdaptor
        ]
    }
}

internal struct LoggerContext: LoggerProtocol {

    var enabled: Bool

    var severity: Log.Severity

    let writers: [LogWriter]

    var adaptors: [LogMessageAdaptor]

    let block: (Log.Attributes, LogMessage) -> Void

    init(parent: LoggerProtocol) {
        enabled = parent.enabled
        severity = parent.severity
        writers = parent.writers
        adaptors = parent.adaptors
        block = parent.writeLog(with:message:)
    }

    func writeLog(with attributes: Log.Attributes, message: LogMessage) {
        block(attributes, message)
    }
}


// MARK: - Convenience

public extension LoggerProtocol {

    func shouldLogMessage(given attributes: Log.Attributes) -> Bool {
        return enabled && attributes.severity >= self.severity
    }

    func verbose(file: String = #file, function: String = #function, line: Int = #line, message: @autoclosure () -> String) {
        writeLog(with: Log.Attributes(severity: .verbose, file: file, function: function, line: line), message: message)
    }

    func info(file: String = #file, function: String = #function, line: Int = #line, message: @autoclosure () -> String) {
        writeLog(with: Log.Attributes(severity: .info, file: file, function: function, line: line), message: message)
    }

    func event(file: String = #file, function: String = #function, line: Int = #line, message: @autoclosure () -> String) {
        writeLog(with: Log.Attributes(severity: .event, file: file, function: function, line: line), message: message)
    }

    func debug(file: String = #file, function: String = #function, line: Int = #line, message: @autoclosure () -> String) {
        writeLog(with: Log.Attributes(severity: .debug, file: file, function: function, line: line), message: message)
    }

    func warning(file: String = #file, function: String = #function, line: Int = #line, message: @autoclosure () -> String) {
        writeLog(with: Log.Attributes(severity: .warning, file: file, function: function, line: line), message: message)
    }

    func fatal(file: String = #file, function: String = #function, line: Int = #line, message: @autoclosure () -> String) {
        writeLog(with: Log.Attributes(severity: .fatal, file: file, function: function, line: line), message: message)
    }

}


// MARK: - Deprecations

public extension LoggerProtocol {

    @available(*, deprecated: 5.0.0, renamed: "info(message:)", message: "The .notice severity has been deprecated use .info, .event or .debug instead")
    func notice(message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        info(file: file, function: function, line: line, message: message)
    }
}

