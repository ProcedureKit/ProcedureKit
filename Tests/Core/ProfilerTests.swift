//
//  ProfilerTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/03/2016.
//
//

import XCTest
@testable import Operations

class TestableProfileReporter: OperationProfilerReporter {
    var didProfileResult: ProfileResult? = .None

    func finishedProfilingWithResult(result: ProfileResult) {
        didProfileResult = result
    }
}

class ProfilerTests: OperationTests {

    var reporter: TestableProfileReporter!

    override func setUp() {
        super.setUp()
        reporter = TestableProfileReporter()
    }

    override func tearDown() {
        reporter = nil
        super.tearDown()
    }
}


class PendingResultTests: XCTestCase {

    var result: PendingResult! = nil

    override func setUp() {
        super.setUp()
        result = PendingResult(created: CFAbsoluteTimeGetCurrent() as NSTimeInterval, identity: .Pending, attached: .Pending, started: .Pending, cancelled: .Pending, finished: .Pending, children: [])
    }

    override func tearDown() {
        result = nil
        super.tearDown()
    }

    func test_identifier_with_pending_identity() {
        XCTAssertEqual(result.identifier, "Pending Result Identifier")
    }

    func test_identifier_with_identity() {
        result = result.setIdentity(OperationIdentity(identifier: "Hello World", name: .None))
        XCTAssertEqual(result.identifier, "Hello World")
    }
}