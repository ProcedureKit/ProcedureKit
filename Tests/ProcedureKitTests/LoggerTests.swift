//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
@testable import ProcedureKit
import TestingProcedureKit

class LoggingTests: ProcedureKitTestCase {

    static let defaultLogManager = LogManager.sharedInstance

    override func tearDown() {
        LogManager.enabled = LoggingTests.defaultLogManager.enabled
        LogManager.severity = LoggingTests.defaultLogManager.severity
        LogManager.logger = LoggingTests.defaultLogManager.logger
        super.tearDown()
    }
}

class LoggerTests: LoggingTests {

    var severity: LogSeverity!
    var log: Logger!

    override func setUp() {
        super.setUp()
        severity = .notice
        log = Logger(severity: severity)
    }

    override func tearDown() {
        log = nil
        super.tearDown()
    }

    func test__init__severity_is_set() {
        XCTAssertEqual(log.severity, severity)
    }

    func test__init__severity_defaults_to_global_severity() {
        log = Logger()
        XCTAssertEqual(log.severity, LogManager.severity)
    }

    func test__init__enabled_defaults_to_global_enabled() {
        log = Logger()
        XCTAssertTrue(log.enabled)
    }

    func test__operation_name_with_name_set() {
        let op = BlockOperation()
        op.name = "A Block"
        XCTAssertEqual(op.operationName, "A Block")
    }

    func test__operation_name_with_name_not_set() {
        let op = BlockOperation()
        op.name = nil
        XCTAssertTrue(op.operationName.contains("Unnamed Operation"))
    }

    func test__meta_uses_last_path_component() {
        let meta = LogManager.metadata(for: "this/is/a/file.swift", function: "the_function", line: 100)
        XCTAssertEqual(meta, "[file.swift the_function:100], ")
    }

    func test__meta_uses_last_path_component_with_operation_name() {
        log = Logger()
        log.operationName = "MyOperation"
        let message = log.messageWithOperationName("a message")
        XCTAssertEqual(message, "MyOperation: a message")
    }
}

class LogManagerTests: LoggingTests {

    func test__severity() {
        LogManager.severity = .info
        XCTAssertEqual(LogManager.severity, .info)
    }

    func test__custom_logger() {
        var receivedMessage: String? = nil
        var receivedSeverity: LogSeverity? = nil
        LogManager.logger = { (info) in
            let (message, severity, _, _, _) = info
            receivedMessage = message
            receivedSeverity = severity
        }
        LogManager.logger(("Hello World!", .fatal, #file, #function, #line))
        XCTAssertEqual(receivedMessage ?? "Uh Oh", "Hello World!")
        XCTAssertEqual(receivedSeverity ?? .verbose, .fatal)
    }
}

class RunAllTheLoggersTests: XCTestCase {

    var log: Logger!

    override func tearDown() {
        log = nil
        super.tearDown()
    }

    func test__verbose() {
        log = Logger(severity: .verbose) { (info) in
            let (message, severity, _, _, _) = info
            XCTAssertEqual(severity, LogSeverity.verbose)
            XCTAssertEqual(message, "Hello World")
        }
        log.verbose(message: "Hello World")
    }

    func test__notice() {
        log = Logger(severity: .verbose) { (info) in
            let (message, severity, _, _, _) = info
            XCTAssertEqual(severity, LogSeverity.notice)
            XCTAssertEqual(message, "Hello World")
        }
        log.notice(message: "Hello World")
    }

    func test__info() {
        log = Logger(severity: .verbose) { (info) in
            let (message, severity, _, _, _) = info
            XCTAssertEqual(severity, LogSeverity.info)
            XCTAssertEqual(message, "Hello World")
        }
        log.info(message: "Hello World")
    }

    func test__warning() {
        log = Logger(severity: .verbose) { (info) in
            let (message, severity, _, _, _) = info
            XCTAssertEqual(severity, LogSeverity.warning)
            XCTAssertEqual(message, "Hello World")
        }
        log.warning(message: "Hello World")
    }

    func test__fatal() {
        log = Logger(severity: .verbose) { (info) in
            let (message, severity, _, _, _) = info
            XCTAssertEqual(severity, LogSeverity.fatal)
            XCTAssertEqual(message, "Hello World")
        }
        log.fatal(message: "Hello World")
    }
}

