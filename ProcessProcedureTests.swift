//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//


import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMac

class ProcessProcedureTests: ProcedureKitTestCase {

    var process: Process!
    var processProcedure: ProcessProcedure!

    var launchPath: String!
    var arguments: [String]!

    override func setUp() {
        super.setUp()

        launchPath = "/bin/echo"
        arguments = [ "Hello World" ]
        processProcedure = ProcessProcedure(launchPath: launchPath, arguments: arguments)
    }

    func test__start_process() {
        wait(for: processProcedure)
        XCTAssertProcedureFinishedWithoutErrors(processProcedure)
    }

    func test__cancel_process_before_launched() {
        processProcedure.cancel()
        wait(for: processProcedure)
        XCTAssertProcedureCancelledWithoutErrors(processProcedure)
    }

    func test__cancel_process_after_launched() {
        processProcedure = ProcessProcedure(launchPath: "/bin/bash/", arguments: ["-c", "sleep 2"])
        processProcedure.addDidExecuteBlockObserver { (procedure) in
            procedure.cancel()
        }
        wait(for: processProcedure, withTimeout: 1)
        XCTAssertProcedureCancelledWithoutErrors(processProcedure)
    }

    func test__processIdentifier_before_launched() {
        XCTAssertEqual(processProcedure.processIdentifier, 0)
    }

    func test__processIdentifier_after_launched() {
        processProcedure = ProcessProcedure(launchPath: "/bin/bash/", arguments: ["-c", "sleep 1"])
        weak var didExecuteExpectation = expectation(description: "DidExecute: \(#function)")
        var processIdentifier = Protector<Int32>(-1)
        processProcedure.addDidExecuteBlockObserver { (procedure) in
            let retrievedProcessIdentifier = procedure.processIdentifier
            processIdentifier.write({ (processIdentifier) in
                processIdentifier = retrievedProcessIdentifier
            })
            DispatchQueue.main.async {
                didExecuteExpectation?.fulfill()
            }
        }
        wait(for: processProcedure)
        XCTAssertGreaterThan(processIdentifier.access, 0)
    }

    func test__processIdentifier_after_finished() {
        wait(for: processProcedure)
        XCTAssertProcedureFinishedWithoutErrors(processProcedure)
        XCTAssertGreaterThan(processProcedure.processIdentifier, 0)
    }

    func test__suspend_before_launched_returns_false() {
        weak var didSuspendExpectation = expectation(description: "Did Suspend: \(#function)")
        processProcedure = ProcessProcedure(launchPath: "/bin/bash/", arguments: ["-c", "sleep 1"])
        processProcedure.suspend { (success) in
            DispatchQueue.main.async {
                XCTAssertFalse(success)
                didSuspendExpectation?.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func test__suspend_after_finished_returns_false() {
        wait(for: processProcedure)
        XCTAssertProcedureFinishedWithoutErrors(processProcedure)
        weak var didSuspendExpectation = expectation(description: "Did Suspend: \(#function)")
        processProcedure.suspend { (success) in
            DispatchQueue.main.async {
                XCTAssertFalse(success)
                didSuspendExpectation?.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func test__resume_before_launched_returns_false() {
        weak var didResumeExpectation = expectation(description: "Did Resume: \(#function)")
        processProcedure = ProcessProcedure(launchPath: "/bin/bash/", arguments: ["-c", "sleep 1"])
        processProcedure.resume { (success) in
            DispatchQueue.main.async {
                XCTAssertFalse(success)
                didResumeExpectation?.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func test__resume_after_finished_returns_false() {
        wait(for: processProcedure)
        XCTAssertProcedureFinishedWithoutErrors(processProcedure)
        weak var didResumeExpectation = expectation(description: "Did Resume: \(#function)")
        processProcedure.resume { (success) in
            DispatchQueue.main.async {
                XCTAssertFalse(success)
                didResumeExpectation?.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func test__suspend_resume_while_executing() {
        // suspend
        weak var didSuspendExpectation = expectation(description: "Did Suspend: \(#function)")
        weak var delayPassed = expectation(description: "Delay Passed: \(#function)")
        processProcedure = ProcessProcedure(launchPath: "/bin/bash/", arguments: ["-c", "sleep 1"])
        processProcedure.addDidExecuteBlockObserver { (processProcedure) in
            processProcedure.suspend { (success) in
                DispatchQueue.main.async {
                    XCTAssertTrue(success)
                    didSuspendExpectation?.fulfill()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                delayPassed?.fulfill()
            }
        }
        run(operations: processProcedure)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertFalse(processProcedure.isFinished)

        // resume
        addCompletionBlockTo(procedure: processProcedure)
        weak var didResumeExpectation = expectation(description: "Did Resume: \(#function)")
        processProcedure.resume { (success) in
            DispatchQueue.main.async {
                XCTAssertTrue(success)
                didResumeExpectation?.fulfill()
            }
        }
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertTrue(processProcedure.isFinished)
    }
}
