//
//  Logging.swift
//  Operations
//
//  Created by Daniel Thorpe on 09/11/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation

public enum LogLevel: Int, Comparable {
    case Verbose = 0, Notice, Info, Warning, Fatal
}

public typealias LoggerBlockType = (message: String) -> Void

public protocol LoggerType {

    var logger: LoggerBlockType { get }

    var threshold: LogLevel { get set }

    init(threshold: LogLevel, logger: LoggerBlockType)

    func log(message: String, level: LogLevel, file: String, function: String, line: Int)
}

public extension LoggerType {

    func log(message: String, level: LogLevel, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        if level >= min(LogManager.threshold, threshold) {
            let prefix: String = {
                guard !file.containsString("Operations") else {
                    return ""
                }
                let filename = (file as NSString).lastPathComponent
                return "[\(filename) \(function):\(line)], "
            }()

            dispatch_async(LogManager.queue) {
                self.logger(message: "\(prefix)\(message)")
            }
        }
    }

    func verbose(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        log(message, level: .Verbose, file: file, function: function, line: line)
    }

    func notice(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        log(message, level: .Notice, file: file, function: function, line: line)
    }

    func info(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        log(message, level: .Info, file: file, function: function, line: line)
    }

    func warning(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        log(message, level: .Warning, file: file, function: function, line: line)
    }

    func fatal(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        log(message, level: .Fatal, file: file, function: function, line: line)
    }
}

public class LogManager {

    static var sharedInstance = LogManager()

    static var queue: dispatch_queue_t {
        return sharedInstance.queue
    }

    public static var threshold: LogLevel {
        get { return sharedInstance.threshold }
        set { sharedInstance.threshold = newValue }
    }

    public static func createLogger<Logger: LoggerType>(threshold: LogLevel = .Warning, logger: LoggerBlockType = { print($0) }) -> Logger {
        return Logger(threshold: threshold, logger: logger)
    }

    let queue = Queue.Utility.serial("me.danthorpe.Operations.Logger")
    var threshold: LogLevel = .Warning
}

public class Logger: LoggerType {

    public var threshold: LogLevel
    public let logger: LoggerBlockType

    public required init(threshold: LogLevel, logger: LoggerBlockType) {
        self.threshold = threshold
        self.logger = logger
    }
}

extension NSOperation {

    public var operationName: String {
        get {
            let _name = name ?? self.description
            guard !_name.containsString("BlockOperation") else {
                return "Unnamed Block Operation"
            }
            return _name
        }
    }
}

public func <(lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}


