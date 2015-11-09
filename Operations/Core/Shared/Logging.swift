//
//  Logging.swift
//  Operations
//
//  Created by Daniel Thorpe on 09/11/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation

public enum LogLevel: Int, Comparable {
    case Verbose = 0, Info, Warning, Fatal
}

public protocol LoggerType {

    var threshold: LogLevel { get set }

    init(threshold: LogLevel, info: () -> String?)

    func log(message: String, level: LogLevel, file: String, function: String, line: Int)
}

public extension LoggerType {

    func verbose(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        log(message, level: .Verbose, file: file, function: function, line: line)
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

struct DefaultLogger: LoggerType {

    let queue = Queue.Initiated.serial("me.danthorpe.Operations.DefaultLogger")
    let info: () -> String?

    var threshold: LogLevel

    init(threshold: LogLevel = .Warning, info: () -> String? = { return .None }) {
        self.threshold = threshold
        self.info = info
    }

    func log(message: String, level: LogLevel, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__) {
        #if DEBUG
            if level >= threshold {
                let prefix: String

                switch level {
                case .Verbose:
                    let filename = (file as NSString).lastPathComponent
                    let verboseInfo = "[\(filename).\(function):\(line)]"
                    prefix = info().map { "\(verboseInfo):\($0)" } ?? verboseInfo
                default:
                    prefix = info() ?? ""
                }
                dispatch_async(queue) {
                    print("\(prefix) \(message)")
                }
            }
        #endif
    }
}

public extension Operation {

    var log: LoggerType {
        return self.dynamicType.sharedLogger
    }
}

extension NSOperation {

    public var operationName: String {
        return name ?? "\(self)"
    }
}

public func <(lhs: LogLevel, rhs: LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}


