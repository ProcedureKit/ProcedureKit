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
        log = Logger()
        XCTAssertEqual(log.severity, LogManager.severity)
    }

    func test__init__enabled_defaults_to_global_enabled() {
        log = Logger()
        XCTAssertTrue(log.enabled)
    }

    func test__meta_uses_last_path_component() {
        log = Logger()
        let meta = log.meta("this/is/a/file.swift", function: "the_function", line: 100)
        XCTAssertEqual(meta, "[file.swift the_function:100], ")
    }

    func test__meta_uses_last_path_component_with_operation_name() {
        log = Logger()
        log.operationName = "MyOperation"
        let meta = log.meta("this/is/a/file.swift", function: "the_function", line: 100)
        XCTAssertEqual(meta, "[file.swift the_function:100], MyOperation: ")
    }
}
