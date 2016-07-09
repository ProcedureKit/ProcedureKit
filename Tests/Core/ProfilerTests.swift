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

class OperationProfilerTests: OperationTests {

    var now: NSTimeInterval!
    var reporter: TestableProfileReporter!
    var profiler: OperationProfiler!

    override func setUp() {
        super.setUp()
        now = CFAbsoluteTimeGetCurrent() as NSTimeInterval
        reporter = TestableProfileReporter()
        profiler = OperationProfiler(reporter)
    }

    override func tearDown() {
            profiler = nil
        reporter = nil
        super.tearDown()
    }

    func validateProfileResult(result: ProfileResult, after: NSTimeInterval) {
        XCTAssertGreaterThanOrEqual(result.created, after)
        XCTAssertGreaterThan(result.attached, 0)
        XCTAssertGreaterThanOrEqual(result.started, result.attached)
        if let cancelled = result.cancelled {
            XCTAssertGreaterThanOrEqual(cancelled, result.attached)
            XCTAssertGreaterThanOrEqual(result.finished ?? 0.0, cancelled)
        }
        else if let finished = result.finished {
            XCTAssertGreaterThanOrEqual(finished, result.started)
        }
        else {
            XCTFail("Profile result neither cancelled nor finished!"); return
        }
    }

    func test__profile_simple_operation_which_finishes() {
        let operation = TestOperation()
        operation.addObserver(profiler)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result, after: now)
        XCTAssertNotNil(result.finished)
    }

    func test__profile_simple_operation_which_cancels() {
        let operation = TestOperation(delay: 1.0)
        operation.addObserver(WillExecuteObserver { op in
            op.cancel()
        })
        operation.addObserver(profiler)

        addCompletionBlockToTestOperation(operation)
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result, after: now)
        XCTAssertNotNil(result.cancelled)
    }


    func test__profile_operation__which_produces_child() {
        let child = TestOperation()
        addCompletionBlockToTestOperation(child)

        let operation = TestOperation(produced: child)
        addCompletionBlockToTestOperation(operation)

        operation.addObserver(profiler)

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result, after: now)
        XCTAssertNotNil(result.finished)
        XCTAssertEqual(result.children.count, 1)
        if let childResult = result.children.first {
            validateProfileResult(childResult, after: now)
        }
    }

    func test__profile_group_operation() {
        let operation = GroupOperation(operations: [ TestOperation(), TestOperation() ])
        operation.addObserver(profiler)

        waitForOperation(operation)

        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result, after: now)
        XCTAssertNotNil(result.finished)
        XCTAssertEqual(result.children.count, 2)
        for child in result.children {
            validateProfileResult(child, after: now)
        }
    }
}

class PrintableProfileResultTests: XCTestCase {

    var now: NSTimeInterval!
    var result: ProfileResult!
    var printable: PrintableProfileResult!

    override func setUp() {
        super.setUp()
        now = CFAbsoluteTimeGetCurrent() as NSTimeInterval
        result = ProfileResult(identity: OperationIdentity(identifier: "Result", name: .None), created: now, attached: 0.1, started: 0.2, cancelled: .None, finished: 0.3, children: [])
        printable = PrintableProfileResult(result: result)
    }

    override func tearDown() {
        now = nil
        result = nil
        super.tearDown()
    }

    func test__add_row_with_interval_text() {
        let output = printable.addRowWithInterval(1.0, text: "Hello World")
        XCTAssertEqual(output, "+1.0 Hello World\n")
    }

    func test__add_row_with_interval_for_event() {
        let output = printable.addRowWithInterval(1.0, forEvent: .Attached)
        XCTAssertEqual(output, "+1.0 Attached\n")
    }

    func test__description__with_whole_result() {
        XCTAssertEqual(printable.description, "+0.1 Attached\n+0.2 Started\n+0.3 Finished\n")
    }

    func test__description__with_indentation() {
        printable = PrintableProfileResult(indentation: 3, result: result)
        XCTAssertEqual(printable.description, "   +0.1 Attached\n   +0.2 Started\n   +0.3 Finished\n")
    }

    func test__description__which_cancelled() {
        result = ProfileResult(identity: OperationIdentity(identifier: "Child", name: .None), created: now, attached: 0.1, started: 0.2, cancelled: 0.25, finished: 0.3, children: [])
        printable = PrintableProfileResult(result: result)
        XCTAssertEqual(printable.description, "+0.1 Attached\n+0.2 Started\n+0.25 Cancelled\n+0.3 Finished\n")
    }

    func test__description__with_children() {
        let child2 = ProfileResult(identity: OperationIdentity(identifier: "Child 2", name: .None), created: now + 0.5, attached: 0.1, started: 0.2, cancelled: .None, finished: 0.3, children: [])
        let child1 = ProfileResult(identity: OperationIdentity(identifier: "Child 1", name: "Data Operation"), created: now + 0.2, attached: 0.1, started: 0.2, cancelled: .None, finished: 0.3, children: [child2])
        result = ProfileResult(identity: OperationIdentity(identifier: "Result", name: .None), created: now, attached: 0.1, started: 0.2, cancelled: .None, finished: 0.3, children: [child1])
        printable = PrintableProfileResult(result: result)
        XCTAssertEqual(printable.description, "+0.1 Attached\n+0.2 Started\n-> Spawned Data Operation #Child 1 with profile results\n  +0.1 Attached\n  +0.2 Started\n  -> Spawned Unnamed Operation #Child 2 with profile results\n    +0.1 Attached\n    +0.2 Started\n    +0.3 Finished\n  +0.3 Finished\n+0.3 Finished\n")
    }
}

class ProfileLoggerTests: XCTestCase {

    var result: ProfileResult!
    var reporter: OperationProfileLogger!

    override func setUp() {
        super.setUp()
        LogManager.severity = .Notice
        result = ProfileResult(identity: OperationIdentity(identifier: "Testing", name: "MyOperation"), created: CFAbsoluteTimeGetCurrent() as NSTimeInterval, attached: 0.1, started: 0.2, cancelled: .None, finished: 0.3, children: [])
    }

    override func tearDown() {
        result = nil
        LogManager.severity = .Warning
        super.tearDown()
    }

    func test__reporter_logs_name() {
        reporter = OperationProfileLogger { message, severity, _, _, _ in
            XCTAssertTrue(message.hasPrefix("MyOperation #Testing: finished profiling with results:\n"), "Message did not have correct prefix: \(message)")
            XCTAssertEqual(severity, LogSeverity.Info)
        }
        reporter.finishedProfilingWithResult(result)
    }
}















