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

class PendingValueTests: XCTestCase {

    func test__equality_pending() {
        XCTAssertEqual(PendingValue<Int>.Pending, PendingValue<Int>.Pending)
    }
}

class PendingResultTests: XCTestCase {

    let created = CFAbsoluteTimeGetCurrent() as NSTimeInterval
    var elapsed: NSTimeInterval!
    var now: NSTimeInterval!
    var child: ProfileResult!
    var identity: OperationIdentity!
    var result: PendingResult!

    override func setUp() {
        super.setUp()
        elapsed = 10.0
        now = created + 10.0
        child = ProfileResult(identity: OperationIdentity(identifier: "Child", name: .None), created: 0, attached: 1, started: 2, cancelled: .None, finished: 3, children: [])
        identity = OperationIdentity(identifier: "Hello World", name: .None)
        result = PendingResult(created: created, identity: .Pending, attached: .Pending, started: .Pending, cancelled: .Pending, finished: .Pending, children: [])
    }

    override func tearDown() {
        result = nil
        identity = nil
        super.tearDown()
    }

    func test__pending__with_pending_identity() {
        XCTAssertTrue(result.pending)
    }

    func test__pending__with_identity() {
        XCTAssertTrue(result.setIdentity(identity).pending)
    }

    func test__pending__with_identity_attached_started() {
        XCTAssertTrue(result.setIdentity(identity).attach().start().pending)
    }

    func test__pending__with_identity_attached_started_cancelled() {
        XCTAssertFalse(result.setIdentity(identity).attach().start().cancel().pending)
    }

    func test__pending__with_identity_attached_started_finished() {
        XCTAssertFalse(result.setIdentity(identity).attach().start().finish().pending)
    }

    func test__set_identity__when_already_set() {
        result = result.setIdentity(identity).setIdentity(OperationIdentity(identifier: "Goodbye!", name: .None))
        XCTAssertEqual(result.identity.value?.identifier, "Hello World")
    }

    func test__attach__when_pending() {
        result = result.attach(now)
        XCTAssertEqual(result.attached.value, elapsed)
    }

    func test__attach__when_already_set() {
        result = result.attach()
        XCTAssertNotEqual(result.attached, PendingValue<NSTimeInterval>.Pending)
        XCTAssertEqual(result.attached, result.attach(0.0).attached)
    }

    func test__start__when_pending() {
        result = result.start(now)
        XCTAssertEqual(result.started.value, elapsed)
    }

    func test__start__when_already_set() {
        result = result.start()
        XCTAssertNotEqual(result.started, PendingValue<NSTimeInterval>.Pending)
        XCTAssertEqual(result.started, result.start(0.0).started)
    }

    func test__cancel__when_pending() {
        result = result.cancel(now)
        XCTAssertEqual(result.cancelled.value, elapsed)
    }

    func test__cancel__when_already_set() {
        result = result.cancel()
        XCTAssertNotEqual(result.cancelled, PendingValue<NSTimeInterval>.Pending)
        XCTAssertEqual(result.cancelled, result.cancel(0.0).cancelled)
    }

    func test__finish__when_pending() {
        result = result.finish(now)
        XCTAssertEqual(result.finished.value, elapsed)
    }

    func test__finish__when_already_set() {
        result = result.finish()
        XCTAssertNotEqual(result.finished, PendingValue<NSTimeInterval>.Pending)
        XCTAssertEqual(result.finished, result.finish(0.0).finished)
    }

    func test__add_child() {
        result = result.addChild(child)
        XCTAssertEqual(result.children.count, 1)
        XCTAssertEqual(result.children[0].finished, 3)
    }

    func test__create_result_when_pending() {
        XCTAssertNil(result.createResult())
    }

    func test__create_result__finished__cancelled_is_none() {
        let profileResult = result.setIdentity(identity).attach().start().finish().createResult()
        XCTAssertNil(profileResult?.cancelled)
    }

    func test__create_result__cancelled__finish_is_none() {
        let profileResult = result.setIdentity(identity).attach().start().cancel().createResult()
        XCTAssertNil(profileResult?.finished)
    }

    func test__create_result__with_children() {
        let profileResult = result.setIdentity(identity).attach().start().finish().addChild(child).createResult()
        XCTAssertEqual(profileResult?.children.count ?? 0, 1)
    }

}

















