//
//  LoggingTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 10/11/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class LoggerTests: XCTestCase {

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
        let op = OldBlockOperation()
        op.name = "A Block"
        XCTAssertEqual(op.operationName, "A Block")
    }

    func test__operation_name_with_name_not_set() {
        let op = OldBlockOperation()
        op.name = nil
        XCTAssertTrue(op.operationName.contains("Unnamed Procedure"))
    }

    func test__meta_uses_last_path_component() {
        let meta = LogManager.metadataForFile("this/is/a/file.swift", function: "the_function", line: 100)
        XCTAssertEqual(meta, "[file.swift the_function:100], ")
    }

    func test__meta_uses_last_path_component_with_operation_name() {
        log = Logger()
        log.operationName = "MyOperation"
        let message = log.messageWithOperationName("a message")
        XCTAssertEqual(message, "MyOperation: a message")
    }
}

class RunAllTheLoggersTests: XCTestCase {

    var log: Logger!

    override func tearDown() {
        log = nil
        super.tearDown()
    }

    func test__verbose() {
        log = Logger(severity: .verbose) { message, severity, _, _, _ in
            XCTAssertEqual(severity, LogSeverity.verbose)
            XCTAssertEqual(message, "Hello World")
        }
        log.verbose("Hello World")
    }

    func test__notice() {
        log = Logger(severity: .verbose) { message, severity, _, _, _ in
            XCTAssertEqual(severity, LogSeverity.notice)
            XCTAssertEqual(message, "Hello World")
        }
        log.notice("Hello World")
    }

    func test__info() {
        log = Logger(severity: .verbose) { message, severity, _, _, _ in
            XCTAssertEqual(severity, LogSeverity.info)
            XCTAssertEqual(message, "Hello World")
        }
        log.info("Hello World")
    }

    func test__warning() {
        log = Logger(severity: .verbose) { message, severity, _, _, _ in
            XCTAssertEqual(severity, LogSeverity.warning)
            XCTAssertEqual(message, "Hello World")
        }
        log.warning("Hello World")
    }

    func test__fatal() {
        log = Logger(severity: .verbose) { message, severity, _, _, _ in
            XCTAssertEqual(severity, LogSeverity.fatal)
            XCTAssertEqual(message, "Hello World")
        }
        log.fatal("Hello World")
    }


}
