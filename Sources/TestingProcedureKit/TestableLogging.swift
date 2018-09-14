//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

public class TestableLogWriter: LogWriter {

    private let stateLock = PThreadMutex()
    private var _entries: [Log.Entry] = []

    public init() { }

    @discardableResult
    private func synchronise<T>(block: () -> T) -> T {
        return stateLock.withCriticalScope(block: block)
    }

    public var entries: [Log.Entry] {
        return synchronise { _entries }
    }

    public func write(entry: Log.Entry) {
        synchronise {
            _entries.append(entry)            
        }
    }
}

public class TestableLogFormatter: LogFormatter {

    private let stateLock = PThreadMutex()
    private var _entries: [Log.Entry] = []

    public init() { }

    @discardableResult
    private func synchronise<T>(block: () -> T) -> T {
        return stateLock.withCriticalScope(block: block)
    }

    public var entries: [Log.Entry] {
        return synchronise { _entries }
    }

    public func format(entry: Log.Entry) -> Log.Entry {
        return synchronise {
            _entries.append(entry)
            return entry
        }
    }
}

public class TestableLogSettings: LogSettings {

    private static var shared: LogChannel = Log.Channel<TestableLogSettings>(enabled: true, severity: .verbose, writer: TestableLogWriter(), formatter: TestableLogFormatter())

    public static var enabled: Bool {
        get { return shared.enabled }
        set { shared.enabled = newValue }
    }

    public static var severity: Log.Severity {
        get { return shared.severity }
        set { shared.severity = newValue }
    }

    public static var writer: LogWriter {
        get { return shared.writer }
        set { shared.writer = newValue }
    }

    public static var formatter: LogFormatter {
        get { return shared.formatter }
        set { shared.formatter = newValue }
    }
}

open class LoggingTestCase: ProcedureKitTestCase {

    open var entry: Log.Entry!

    override open func setUp() {
        super.setUp()
        Log.enabled = true
        Log.severity = .verbose
        TestableLogSettings.writer = TestableLogWriter()
        TestableLogSettings.formatter = TestableLogFormatter()
        entry = Log.Entry(payload: .message("Hello World"), severity: .debug, file: "the file", function: "the function", line: 100, threadID: 1000)
    }

    override open func tearDown() {
        Log.enabled = true
        Log.severity = .warning
        entry = nil
        super.tearDown()
    }
}

public extension ProcedureKitTestCase {

    func PKAssertProcedureLogContainsMessage<T: Procedure>(_ exp: @autoclosure () throws -> T, _ exp2: @autoclosure () throws -> String, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
        __XCTEvaluateAssertion(testCase: self, message, file: file, line: line) {

            let procedure = try exp()

            guard let writer = procedure.log.writer as? TestableLogWriter else {
                return .expectedFailure("\(procedure.procedureName) did not have a testable log writer.")
            }

            let loggedMessages: [String] = writer.entries.compactMap { $0.message }

            guard loggedMessages.count > 0 else {
                return .expectedFailure("\(procedure.procedureName) did not log any messages")
            }

            let text = try exp2()

            guard loggedMessages.contains(text) else {
                return .expectedFailure("\(procedure.procedureName) did not log the message: \(text)")
            }

            return .success
        }
    }
}

