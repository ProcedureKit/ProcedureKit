//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch
import os

internal struct CurrentProcessInfo {

    static var name: String {
        return shared.name
    }

    static var ID: Int32 {
        return shared.ID
    }

    private static let shared = CurrentProcessInfo()

    private let name: String
    private let ID: Int32

    private init() {
        let process = ProcessInfo.processInfo
        name = process.processName
        ID = process.processIdentifier
    }
}

public class Log {

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

    public struct Entry: CustomStringConvertible {

        public enum Payload: CustomStringConvertible {

            case trace
            case message(String)
            case value(Any?)

            public var description: String {
                switch self {
                case .trace:
                    return ""
                case .message(let text):
                    return text
                case .value(let value):
                    if let value = value {
                        return "\(value)"
                    }
                    return "<nil-value>"
                }
            }
        }

        public let payload: Payload

        public let formattedMetadata: String?

        public let severity: Severity

        public let file: String

        public let function: String

        public let line: Int

        public let threadID: UInt64

        public let timestamp: Date

        public let processName: String

        public let processID: Int32

        public var description: String {
            guard let metadata = formattedMetadata else {
                return payload.description
            }
            return "\(metadata) \(payload.description)"
        }

        public var message: String? {
            switch payload {
            case let .message(message):
                return message
            default:
                return nil
            }
        }

        public init(payload: Payload, formattedMetadata: String? = nil, severity: Log.Severity, file: String, function: String, line: Int, threadID: UInt64, timestamp: Date = Date()) {
            self.payload = payload
            self.formattedMetadata = formattedMetadata
            self.severity = severity
            self.file = file
            self.function = function
            self.line = line
            self.threadID = threadID
            self.timestamp = timestamp
            self.processName = CurrentProcessInfo.name
            self.processID = CurrentProcessInfo.ID
        }

        func append(formattedMetadata newFormattedMetadata: String?) -> Log.Entry {
            guard let newFormattedMetadata = newFormattedMetadata?.trimmingCharacters(in: .whitespacesAndNewlines) else { return self }
            guard false == newFormattedMetadata.isEmpty else { return self }

            let new: String
            if let old = formattedMetadata, !old.isEmpty {
                new = "\(old) \(newFormattedMetadata)"
            }
            else {
                new = newFormattedMetadata
            }
            return Log.Entry(payload: payload, formattedMetadata: new, severity: severity, file: file, function: function, line: line, threadID: threadID, timestamp: timestamp)
        }
    }

    // MARK: - Static Properties

    internal static var shared: LogChannel = Log.Channel<Log>(enabled: true, severity: .info, writer: Log.Writers.standard, formatter: Log.Formatters.standard)

    // MARK: - Instance Properties

    private let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.Logger", qos: .utility)

    private let stateLock = PThreadMutex()

    private init() { }
}

public protocol LogSettings {

    static var enabled: Bool { get set }

    static var severity: Log.Severity { get set }

    static var channel: LogChannel { get set }

    static var writer: LogWriter { get set }

    static var formatter: LogFormatter { get set }
}

public protocol LogWriter {

    func write(entry: Log.Entry)
}

public protocol LogFormatter {

    func format(entry: Log.Entry) -> Log.Entry
}

public protocol LogChannel {

    var enabled: Bool { get set }

    var severity: Log.Severity { get set }

    var writer: LogWriter { get set }

    var formatter: LogFormatter { get set }
}

public protocol LogChannels {

    var verbose: LogChannel { get }

    var info: LogChannel { get }

    var event: LogChannel { get }

    var debug: LogChannel { get }

    var warning: LogChannel { get }

    var fatal: LogChannel { get }

    var current: LogChannel { get }
}

public typealias ProcedureLog = LogChannels & LogChannel

// MARK: - Protocol Exensions

public extension LogChannel {

    func shouldWrite(severity: Log.Severity) -> Bool {
        return enabled && Log.enabled && (self.severity >= Log.severity) && (severity >= self.severity)
    }

    func write(entry: Log.Entry) {
        writer.write(entry: formatter.format(entry: entry))
    }

    func trace(_ file: String = #file, function: String = #function, line: Int = #line) {
        guard shouldWrite(severity: severity) else { return }
        var threadID: UInt64 = 0
        pthread_threadid_np(nil, &threadID)
        let entry = Log.Entry(payload: .trace, severity: severity, file: file, function: function, line: line, threadID: threadID)
        write(entry: entry)
    }

    func message(_ msg: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        guard shouldWrite(severity: severity) else { return }
        var threadID: UInt64 = 0
        pthread_threadid_np(nil, &threadID)
        let entry = Log.Entry(payload: .message(msg()), severity: severity, file: file, function: function, line: line, threadID: threadID)
        write(entry: entry)
    }

    func value(_ value: @autoclosure () -> Any?, file: String = #file, function: String = #function, line: Int = #line) {
        guard shouldWrite(severity: severity) else { return }
        var threadID: UInt64 = 0
        pthread_threadid_np(nil, &threadID)
        let entry = Log.Entry(payload: .value(value()), severity: severity, file: file, function: function, line: line, threadID: threadID)
        write(entry: entry)
    }
}

public extension LogChannels {

    var channels: [LogChannel] {
        return [verbose, info, event, debug, warning, fatal]
    }
}

// MARK: - Protocol Conformance

extension Log: LogSettings {

    public static var channel: LogChannel {
        get { return shared }
        set { shared = newValue }
    }

    public static var enabled: Bool {
        get { return channel.enabled }
        set { channel.enabled = newValue }
    }

    public static var severity: Severity {
        get { return channel.severity }
        set { channel.severity = newValue }
    }

    public static var writer: LogWriter {
        get { return channel.writer }
        set { channel.writer = newValue }
    }

    public static var formatter: LogFormatter {
        get { return channel.formatter }
        set { channel.formatter = newValue }
    }

    @available(iOS 10.0, iOSApplicationExtension 10.0, tvOS 10.0, tvOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *)
    public static func setWriterUsingOSLog(_ log: OSLog) {
        writer = Log.Writers.OSLogWriter(log: log)
    }

}

// MARK: - Log Channel

public extension Log {

    class Channel<Settings: LogSettings>: LogChannel {

        private let stateLock = PThreadMutex()

        private var _enabled: Bool
        private var _severity: Severity
        private var _writer: LogWriter
        private var _formatter: LogFormatter

        public init(enabled: Bool = Settings.enabled, severity: Log.Severity = Settings.severity, writer: LogWriter = Settings.writer, formatter: LogFormatter = Settings.formatter) {
            _enabled = enabled
            _severity = severity
            _writer = writer
            _formatter = formatter
        }

        @discardableResult
        private func synchronise<T>(block: () -> T) -> T {
            return stateLock.withCriticalScope(block: block)
        }

        public var enabled: Bool {
            get { return synchronise { _enabled } }
            set { synchronise { _enabled = newValue } }
        }

        public var severity: Severity {
            get { return synchronise { _severity } }
            set { synchronise { _severity = newValue } }
        }

        public var writer: LogWriter {
            get { return synchronise { _writer } }
            set { synchronise { _writer = newValue } }
        }

        public var formatter: LogFormatter {
            get { return synchronise { _formatter } }
            set { synchronise { _formatter = newValue } }
        }
    }
}

// MARK: - Log Channels

extension Log {

    public class Channels<Settings: LogSettings>: Log.Channel<Settings>, LogChannels {

        public private(set) var verbose: LogChannel

        public private(set) var info: LogChannel

        public private(set) var event: LogChannel

        public private(set) var debug: LogChannel

        public private(set) var warning: LogChannel

        public private(set) var fatal: LogChannel

        public var current: LogChannel {
            switch severity {
            case .verbose: return verbose
            case .info: return info
            case .event: return event
            case .debug: return debug
            case .warning: return warning
            case .fatal: return fatal
            }
        }

        public override var enabled: Bool {
            didSet {
                for var channel in channels {
                    channel.enabled = enabled
                }
            }
        }

        public override var writer: LogWriter {
            didSet {
                for var channel in channels {
                    channel.writer = writer
                }
            }
        }

        public override var formatter: LogFormatter {
            didSet {
                for var channel in channels {
                    channel.formatter = formatter
                }
            }
        }

        override public init(enabled: Bool = Settings.enabled, severity: Log.Severity = Settings.severity, writer: LogWriter = Settings.writer, formatter: LogFormatter = Settings.formatter) {
            verbose = Log.Channel<Settings>(enabled: enabled, severity: .verbose, writer: writer, formatter: formatter)
            info = Log.Channel<Settings>(enabled: enabled, severity: .info, writer: writer, formatter: formatter)
            event = Log.Channel<Settings>(enabled: enabled, severity: .event, writer: writer, formatter: formatter)
            debug = Log.Channel<Settings>(enabled: enabled, severity: .debug, writer: writer, formatter: formatter)
            warning = Log.Channel<Settings>(enabled: enabled, severity: .warning, writer: writer, formatter: formatter)
            fatal = Log.Channel<Settings>(enabled: enabled, severity: .fatal, writer: writer, formatter: formatter)
            super.init(enabled: enabled, severity: severity, writer: writer, formatter: formatter)
        }
    }
}

// MARK: - Log Writers

public extension Log {

    struct Writers {

        public static let standard: LogWriter = {
            if #available(iOS 10.0, iOSApplicationExtension 10.0, tvOS 10.0, tvOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *) {
                return OSLogWriter(log: .procedure)
            }
            else {
                return PrintLogWriter()
            }
        }()

        public static let system: LogWriter = {
            if #available(iOS 10.0, iOSApplicationExtension 10.0, tvOS 10.0, tvOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *) {
                return Log.Writers.OSLogWriter(log: .procedure)
            }
            else {
                return Log.Writers.PrintLogWriter()
            }
        }()
    }
}

// MARK: - Log Formatters

public extension Log {

    struct Formatters {

        public static let standard: LogFormatter = Concatenating([SeverityFormatter(), CallsiteFormatter()])

        public static func makeProcedureLogFormatter(operationName name: String) -> LogFormatter {
            return Log.Formatters.Concatenating([
                Log.Formatters.CallsiteFormatter(),
                Log.Formatters.SeverityFormatter(),
                Log.Formatters.StaticStringFormatter(name)])
        }
    }
}

public extension Log.Formatters {

    class Concatenating: LogFormatter {

        public let formatters: [LogFormatter]

        public init(_ formatters: [LogFormatter]) {
            self.formatters = formatters
        }

        public func format(entry: Log.Entry) -> Log.Entry {
            return formatters.reduce(entry) { $1.format(entry: $0) }
        }
    }

    class SeverityFormatter: LogFormatter {

        public func format(entry: Log.Entry) -> Log.Entry {
            return entry.append(formattedMetadata: entry.severity.description)
        }
    }

    class StaticStringFormatter: LogFormatter {

        public let text: String

        public init(_ text: String) {
            self.text = text
        }

        public func format(entry: Log.Entry) -> Log.Entry {
            return entry.append(formattedMetadata: text)
        }
    }

    class CallsiteFormatter: LogFormatter {

        public func format(entry: Log.Entry) -> Log.Entry {
            guard false == entry.file.contains("ProcedureKit") else { return entry }
            let filename = (entry.file as NSString).pathComponents.last ?? "redacted"
            return entry.append(formattedMetadata: "\(filename):\(entry.line)")
        }
    }

}

extension Log.Severity: CustomStringConvertible {

    public var description: String {
        switch self {
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




// MARK: - Log Writer


// MARK: - OSLog Writer

@available(iOS 10.0, iOSApplicationExtension 10.0, tvOS 10.0, tvOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *)
public extension Log.Severity {

    var logType: OSLogType {
        switch self {
        case .verbose, .debug:
            return .debug
        case .info, .event:
            return .info
        case .warning:
            return .default
        case .fatal:
            return .error
        }
    }
}

extension Log.Writers {

    @available(iOS 10.0, iOSApplicationExtension 10.0, tvOS 10.0, tvOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *)
    public class OSLogWriter: LogWriter {

        public let log: OSLog

        public init(log: OSLog) {
            self.log = log
        }

        public func write(entry: Log.Entry) {
            os_log("%{public}@", log: log, type: entry.severity.logType, entry.description)
        }
    }
}

@available(iOS 10.0, iOSApplicationExtension 10.0, tvOS 10.0, tvOSApplicationExtension 10.0, OSX 10.12, OSXApplicationExtension 10.12, *)
internal extension OSLog {

    static let procedure = OSLog(subsystem: "run.kit.procedure", category: "ProcedureKit")
}

// MARK: - Print Log Writer
extension Log.Writers {

    public class PrintLogWriter: LogWriter {

        public func write(entry: Log.Entry) {
            print(entry)
        }
    }
}

extension Log.Writers {

    public class Redirecting: LogWriter {

        public let writers: [LogWriter]

        public init(writers: [LogWriter]) {
            self.writers = writers
        }

        public func write(entry: Log.Entry) {
            writers.forEach { $0.write(entry: entry) }
        }
    }
}

// MARK: - Procedure Log


// MARK: - Deprecations

public extension LogChannel {

    @available(*, deprecated, renamed: "info.message", message: "The .notice severity has been deprecated use .info, .event or .debug instead")
    func notice(message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        self.message(message(), file: file, function: function, line: line)
    }
}

