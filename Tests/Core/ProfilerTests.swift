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

    let created = CFAbsoluteTimeGetCurrent() as NSTimeInterval
    var elapsed: NSTimeInterval!
    var now: NSTimeInterval!
    var identity: OperationIdentity!
    var result: PendingResult!

    override func setUp() {
        super.setUp()
        elapsed = 10.0
        now = created + 10.0
        identity = OperationIdentity(identifier: "Hello World", name: .None)
        result = PendingResult(created: created, identity: .Pending, attached: .Pending, started: .Pending, cancelled: .Pending, finished: .Pending, children: [])
    }

    override func tearDown() {
        result = nil
        identity = nil
        super.tearDown()
    }

    func test_identifier__with_pending_identity() {
        XCTAssertEqual(result.identifier, "Pending Result Identifier")
    }

    func test_identifier__with_identity() {
        result = result.setIdentity(identity)
        XCTAssertEqual(result.identifier, "Hello World")
    }

    func test_pending__with_pending_identity() {
        XCTAssertTrue(result.pending)
    }

    func test_pending__with_identity() {
        XCTAssertTrue(result.setIdentity(identity).pending)
    }

    func test_pending__with_identity_attached_started() {
        XCTAssertTrue(result.setIdentity(identity).attach().start().pending)
    }

    func test_pending__with_identity_attached_started_cancelled() {
        XCTAssertFalse(result.setIdentity(identity).attach().start().cancel().pending)
    }

    func test_pending__with_identity_attached_started_finished() {
        XCTAssertFalse(result.setIdentity(identity).attach().start().finish().pending)
    }

    func test_set_identity__when_already_set() {
        result = result.setIdentity(identity).setIdentity(OperationIdentity(identifier: "Goodbye!", name: .None))
        XCTAssertEqual(result.identifier, "Hello World")
    }

    func test_attach__when_pending() {
        result = result.attach(now)
        XCTAssertEqual(result.attached.value, elapsed)
    }

    func test_attach__when_already_set() {
        result = result.attach()
        XCTAssertNotEqual(result.attached, PendingValue<NSTimeInterval>.Pending)
        XCTAssertEqual(result.attached, result.attach(0.0).attached)
    }

    func test_start__when_pending() {
        result = result.start(now)
        XCTAssertEqual(result.started.value, elapsed)
    }

    func test_start__when_already_set() {
        result = result.start()
        XCTAssertNotEqual(result.started, PendingValue<NSTimeInterval>.Pending)
        XCTAssertEqual(result.started, result.start(0.0).started)
    }

    func test_cancel__when_pending() {
        result = result.cancel(now)
        XCTAssertEqual(result.cancelled.value, elapsed)
    }

    func test_cancel__when_already_set() {
        result = result.cancel()
        XCTAssertNotEqual(result.cancelled, PendingValue<NSTimeInterval>.Pending)
        XCTAssertEqual(result.cancelled, result.cancel(0.0).cancelled)
    }

    func test_finish__when_pending() {
        result = result.finish(now)
        XCTAssertEqual(result.finished.value, elapsed)
    }

    func test_finish__when_already_set() {
        result = result.finish()
        XCTAssertNotEqual(result.finished, PendingValue<NSTimeInterval>.Pending)
        XCTAssertEqual(result.finished, result.finish(0.0).finished)
    }

}