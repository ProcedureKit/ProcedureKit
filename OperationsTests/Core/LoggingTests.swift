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
        LogManager.globalLogSeverity = .Info
        log = Logger()
        XCTAssertEqual(log.severity, LogSeverity.Info)
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
