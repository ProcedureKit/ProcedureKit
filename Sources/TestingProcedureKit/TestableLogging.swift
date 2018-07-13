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
        synchronise { _entries.append(entry) }
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
