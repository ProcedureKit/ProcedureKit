//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
@testable import ProcedureKit
import TestingProcedureKit

class LoggingTestCase: ProcedureKitTestCase {

    static let defaultEnabled = Log.enabled
    static let defaultSeverity = Log.severity

    override func setUp() {
        super.setUp()
        TestableLogSettings.writer = TestableLogWriter()
        TestableLogSettings.formatter = TestableLogFormatter()
    }

    override func tearDown() {
        Log.enabled = LoggingTestCase.defaultEnabled
        Log.severity = LoggingTestCase.defaultSeverity
        super.tearDown()
    }
}

class LogEntryPayloadTests: LoggingTestCase {

    func test__trace_description() {
        let payload: Log.Entry.Payload = .trace
        XCTAssertEqual(payload.description, "")
    }

    func test__message_description() {
        let payload: Log.Entry.Payload = .message("Hello World")
        XCTAssertEqual(payload.description, "Hello World")
    }

    func test__value_description() {
        let payload: Log.Entry.Payload = .value("Hello World")
        XCTAssertEqual(payload.description, "Hello World")
    }

    func test__value_nil_description() {
        let payload: Log.Entry.Payload = .value(nil)
        XCTAssertEqual(payload.description, "<nil-value>")
    }
}

class LogChannelTests: LoggingTestCase {

    var channel: Log.Channel<TestableLogSettings>!

    override func setUp() {
        super.setUp()
        channel = Log.Channel<TestableLogSettings>()
    }

    override func tearDown() {
        channel = nil
        super.tearDown()
    }

    func test__channel_enabled_initialized_from_settings() {
        channel = Log.Channel<TestableLogSettings>()
        XCTAssertEqual(channel.enabled, TestableLogSettings.enabled)
        XCTAssertTrue(channel.enabled)
    }

    func test__channel_enabled_initialized_from_init() {
        channel = Log.Channel<TestableLogSettings>(enabled: false)
        XCTAssertNotEqual(channel.enabled, TestableLogSettings.enabled)
        XCTAssertFalse(channel.enabled)
    }

    func test__channel_severity_initialized_from_settings() {
        channel = Log.Channel<TestableLogSettings>()
        XCTAssertEqual(channel.severity, TestableLogSettings.severity)
        XCTAssertEqual(channel.severity, .verbose)
    }

    func test__channel_severity_initialized_from_init() {
        channel = Log.Channel<TestableLogSettings>(severity: .debug)
        XCTAssertNotEqual(channel.severity, TestableLogSettings.severity)
        XCTAssertEqual(channel.severity, .debug)
    }

}
