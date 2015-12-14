//
//  LoggingTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 10/11/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestableLogManager: LogManager {

    let expectation: XCTestExpectation
    let expectedMessage: String

    var receivedMessage: String? = .None

    init(expectation: XCTestExpectation, message: String) {
        self.expectation = expectation
        self.expectedMessage = message
    }

    func log(message: String) {
        receivedMessage = message
        expectation.fulfill()
    }
}

class LoggerTests: XCTestCase {

    var severity: LogSeverity!
    var log: Logger!

    override func setUp() {
        super.setUp()
        severity = .Notice
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
        LogManager.severity = .Info
        log = Logger()
        XCTAssertEqual(log.severity, LogSeverity.Info)
    }

    func test__meta_uses_last_path_component() {
        log = Logger()
        let meta = log.meta("this/is/a/file.swift", function: "the_function", line: 100)
        XCTAssertEqual(meta, "[file.swift the_function:100], ")
    }

    func test__disabled_logger_no_message_received() {
        let logger = LogManager.logger
        var messageReceived: String? = .None
        LogManager.logger = { message in
            messageReceived = message
        }
        LogManager.enabled = false
        let log = Logger()
        log.fatal("hello")
        LogManager.logger = logger
        XCTAssertNil(messageReceived)
    }
}

class LogManagerTests: XCTestCase {

    func test__shared_logger__is_set() {
        let logger = LogManager.logger
        LogManager.logger = { message in
            XCTAssertEqual(message, "hello")
        }
        let log = Logger()
        log.fatal("hello")
        LogManager.logger = logger
    }
}
