//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit


class TestableProfileReporter: ProcedureProfilerReporter {

    let didProfileResultGroup = DispatchGroup()

    init() {
        didProfileResultGroup.enter()
    }
    deinit {
        guard let _ = didProfileResult else {
            // did not finish profiling before going out of scope
            // missing matching leave for DispatchGroup.enter()
            didProfileResultGroup.leave()
            return
        }
    }

    var didProfileResult: ProfileResult? {
        get { return _didProfileResult.access }
        set { _didProfileResult.overwrite(with: newValue) }
    }

    var _didProfileResult = Protector<ProfileResult?>(.none)

    func finishedProfiling(withResult result: ProfileResult) {
        didProfileResult = result
        didProfileResultGroup.leave()
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

    func waitForReporterAnd(for procedure: Procedure, withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function) {
        wait(for: procedure, andReporter: reporter, withTimeout: timeout, withExpectationDescription: expectationDescription)
    }

    func wait(for procedure: Procedure, andReporter reporter: TestableProfileReporter, withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function) {

        // Wait for the Procedure to finish
        wait(for: procedure, withTimeout: timeout, withExpectationDescription: expectationDescription)

        // - Profiling finishes via a DidFinish observer on the Procedure
        // - The above wait may return prior to the DidFinish observer being called
        // Thus, additionally wait for the TestableProfileReporter to be signaled
        // with the ProfileResult.
        weak var exp = expectation(description: "Finished profiling for: \(expectationDescription)")
        reporter.didProfileResultGroup.notify(queue: DispatchQueue.main) {
            exp?.fulfill()
        }
        waitForExpectations(timeout: timeout)
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

        waitForReporterAnd(for: procedure)
        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result: result, after: now)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__profile_simple_operation_which_cancels() {

        procedure.add(observer: WillExecuteObserver { op, _ in
            op.cancel()
        })
        procedure.add(observer: profiler)
        waitForReporterAnd(for: procedure)

        guard let result = reporter.didProfileResult else {
            XCTFail("Reporter did not receive profile result."); return
        }

        validateProfileResult(result: result, after: now)
        XCTAssertProcedureCancelledWithoutErrors()
    }

    func test__profile_operation__which_produces_child() {

        let child = TestProcedure()
        // Also wait for the produced child to complete
        addCompletionBlockTo(procedure: child)

        procedure = TestProcedure(produced: child)
        procedure.add(observer: profiler)

        // Because of the addCompletionBlockTo line above, wait for the procedure *and*
        // the child it produces to complete
        waitForReporterAnd(for: procedure)

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

        waitForReporterAnd(for: group)

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
