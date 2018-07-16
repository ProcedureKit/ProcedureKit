//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
@testable import ProcedureKit
import TestingProcedureKit

class LogEntryTests: LoggingTestCase {

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

    func test__appendFormattedMetadata() {
        let appended = entry
            .append(formattedMetadata: "Foo")
            .append(formattedMetadata: nil)
            .append(formattedMetadata: "")
            .append(formattedMetadata: "   ")
            .append(formattedMetadata: "Bar")
        XCTAssertEqual(appended.formattedMetadata, "Foo Bar")
        guard case let .message(text) = entry.payload else {
            XCTFail("Entry did not have a message payload"); return
        }
        XCTAssertEqual(text, "Hello World")
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

    func test__channel_shouldWrite_false_when_log_settings_disabled() {
        Log.enabled = false
        XCTAssertFalse(channel.shouldWrite(severity: .fatal))
    }

    func test__channel_shouldWrite_false_when_channel_disabled() {
        channel.enabled = false
        XCTAssertFalse(channel.shouldWrite(severity: .fatal))
    }

    func test__channel_shouldWrite_false_when_severity_less_than_channel_severity() {
        channel.severity = .fatal
        XCTAssertFalse(channel.shouldWrite(severity: .warning))
    }

    func test__channel_shouldWrite_false_when_severity_less_than_global_severity() {
        Log.severity = .warning
        XCTAssertFalse(channel.shouldWrite(severity: .info))
    }

    func test__writer_receives_log_entry_with_trace() {
        guard let writer = TestableLogSettings.writer as? TestableLogWriter else {
            XCTFail("Did not have a testable log writer"); return
        }
        XCTAssertEqual(writer.entries.count, 0)
        channel.trace()
        XCTAssertEqual(writer.entries.count, 1)
        guard let payload = writer.entries.first?.payload, case .trace = payload else {
            XCTFail("Entry did not have a trace payload"); return
        }
    }

    func test__writer_does_not_receive_log_entry_with_trace_when_disabled() {
        guard let writer = TestableLogSettings.writer as? TestableLogWriter else {
            XCTFail("Did not have a testable log writer"); return
        }
        channel.enabled = false
        channel.trace()
        XCTAssertEqual(writer.entries.count, 0)
    }

    func test__writer_receives_log_entry_with_message() {
        guard let writer = TestableLogSettings.writer as? TestableLogWriter else {
            XCTFail("Did not have a testable log writer"); return
        }
        XCTAssertEqual(writer.entries.count, 0)
        channel.message("Hello World")
        XCTAssertEqual(writer.entries.count, 1)
        guard let payload = writer.entries.first?.payload, case let .message(text) = payload else {
            XCTFail("Entry did not have a message payload"); return
        }
        XCTAssertEqual(text, "Hello World")
    }

    func test__writer_does_not_receive_log_entry_with_message_when_disabled() {
        guard let writer = TestableLogSettings.writer as? TestableLogWriter else {
            XCTFail("Did not have a testable log writer"); return
        }
        channel.enabled = false
        channel.message("Hello World")
        XCTAssertEqual(writer.entries.count, 0)
    }


    func test__writer_receives_log_entry_with_value() {
        guard let writer = TestableLogSettings.writer as? TestableLogWriter else {
            XCTFail("Did not have a testable log writer"); return
        }
        XCTAssertEqual(writer.entries.count, 0)
        channel.value("Hello World")
        XCTAssertEqual(writer.entries.count, 1)
        guard let payload = writer.entries.first?.payload, case let .value(value) = payload, let text = value as? String else {
            XCTFail("Entry did not have a message payload"); return
        }
        XCTAssertEqual(text, "Hello World")
    }

    func test__writer_does_not_receive_log_entry_with_value_when_disabled() {
        guard let writer = TestableLogSettings.writer as? TestableLogWriter else {
            XCTFail("Did not have a testable log writer"); return
        }
        channel.enabled = false
        channel.value("Hello World")
        XCTAssertEqual(writer.entries.count, 0)
    }
}

class LogChannelsTests: LoggingTestCase {

    var channels: Log.Channels<TestableLogSettings>!

    override func setUp() {
        super.setUp()
        channels = Log.Channels<TestableLogSettings>()
    }

    override func tearDown() {
        channels = nil
        super.tearDown()
    }

    func test__setting_enabled_sets_all_channels() {
        channels.enabled = false
        XCTAssertFalse(channels.verbose.enabled)
        XCTAssertFalse(channels.info.enabled)
        XCTAssertFalse(channels.event.enabled)
        XCTAssertFalse(channels.debug.enabled)
        XCTAssertFalse(channels.warning.enabled)
        XCTAssertFalse(channels.fatal.enabled)
        channels.enabled = true
        XCTAssertTrue(channels.verbose.enabled)
        XCTAssertTrue(channels.info.enabled)
        XCTAssertTrue(channels.event.enabled)
        XCTAssertTrue(channels.debug.enabled)
        XCTAssertTrue(channels.warning.enabled)
        XCTAssertTrue(channels.fatal.enabled)
    }

    func test__setting_writer() {
        let writer = TestableLogWriter()
        channels.writer = writer
        channels.debug.message("Hello World")
        XCTAssertEqual(writer.entries.count, 1)
        guard let payload = writer.entries.first?.payload, case let .message(text) = payload else {
            XCTFail("Entry did not have a message payload"); return
        }
        XCTAssertEqual(text, "Hello World")
    }

    func test__getting_current_channel() {
        channels.severity = .verbose
        XCTAssertEqual(channels.current.severity, .verbose)
        channels.severity = .info
        XCTAssertEqual(channels.current.severity, .info)
        channels.severity = .event
        XCTAssertEqual(channels.current.severity, .event)
        channels.severity = .debug
        XCTAssertEqual(channels.current.severity, .debug)
        channels.severity = .warning
        XCTAssertEqual(channels.current.severity, .warning)
        channels.severity = .fatal
        XCTAssertEqual(channels.current.severity, .fatal)
    }
}

