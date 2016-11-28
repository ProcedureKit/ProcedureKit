//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit


class TestableProfileReporter: ProcedureProfilerReporter {
    var didProfileResult: ProfileResult? = .none

    func finishedProfiling(withResult result: ProfileResult) {
        didProfileResult = result
    }
}

class ProfilerTests: ProcedureKitTestCase {

    var now: TimeInterval!
    var reporter: TestableProfileReporter!
    var profiler: ProcedureProfiler!

    override func setUp() {
        super.setUp()
        now = CFAbsoluteTimeGetCurrent() as TimeInterval
        reporter = TestableProfileReporter()
        profiler = ProcedureProfiler(reporter)
    }

    override func tearDown() {
        profiler = nil
        reporter = nil
        super.tearDown()
    }

    func validateProfileResult(result: ProfileResult, after: TimeInterval) {
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
        procedure.add(observer: profiler)

        wait(for: procedure)
        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result: result, after: now)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__profile_simple_operation_which_cancels() {

        procedure.add(observer: WillExecuteObserver { op in
            op.cancel()
        })
        procedure.add(observer: profiler)
        wait(for: procedure)

        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result: result, after: now)
        XCTAssertProcedureCancelledWithoutErrors()
    }

    func test__profile_operation__which_produces_child() {

        let child = TestProcedure()

        procedure = TestProcedure(produced: child)
        procedure.add(observer: profiler)

        wait(for: procedure)

        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result: result, after: now)
        XCTAssertProcedureFinishedWithoutErrors()
        XCTAssertEqual(result.children.count, 1)
        if let childResult = result.children.first {
            validateProfileResult(result: childResult, after: now)
        }
    }

    func test__profile_group_operation() {
        let group = GroupProcedure(operations: [ TestProcedure(), TestProcedure() ])
        group.log.severity = .notice
        group.add(observer: profiler)

        wait(for: group)

        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result: result, after: now)
        XCTAssertProcedureFinishedWithoutErrors(group)

        XCTAssertEqual(result.children.count, 2)
        for child in result.children {
            validateProfileResult(result: child, after: now)
        }
    }
}
