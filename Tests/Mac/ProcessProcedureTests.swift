//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//


import XCTest
import ProcedureKit
import TestingProcedureKit
import Foundation
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

    func test__start_process_with_launchpath_only() {
        processProcedure = ProcessProcedure(launchPath: launchPath)
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
        checkAfterDidExecute(procedure: processProcedure, withTimeout: 1) { procedure in
            procedure.cancel()
        }
        XCTAssertProcedureCancelledWithoutErrors(processProcedure)
    }

    func test__processIdentifier_before_launched() {
        XCTAssertEqual(processProcedure.processIdentifier, 0)
    }

    func test__processIdentifier_after_launched() {
        processProcedure = ProcessProcedure(launchPath: "/bin/bash/", arguments: ["-c", "sleep 1"])
        weak var didExecuteExpectation = expectation(description: "DidExecute: \(#function)")
        let processIdentifier = Protector<Int32>(-1)
        processProcedure.addDidExecuteBlockObserver { procedure in
            let retrievedProcessIdentifier = procedure.processIdentifier
            processIdentifier.overwrite(with: retrievedProcessIdentifier)
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
        processProcedure.suspend { success in
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
        processProcedure.suspend { success in
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
        processProcedure.resume { success in
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
        processProcedure.resume { success in
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
        processProcedure.addDidExecuteBlockObserver { procedure in
            procedure.suspend { (success) in
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

    // MARK: - Configuration Properties (Read-only)

    func test__arguments() {
        processProcedure = ProcessProcedure(launchPath: launchPath, arguments: arguments)
        XCTAssertEqual(processProcedure.arguments ?? [], arguments)
    }

    func test__currentDirectoryPath() {
        let currentDirectoryPath = "/bin/"
        processProcedure = ProcessProcedure(launchPath: launchPath, currentDirectoryPath: currentDirectoryPath)
        XCTAssertEqual(processProcedure.currentDirectoryPath, currentDirectoryPath)
    }

    func test__environment() {
        var environment = ProcessInfo().environment
        environment.updateValue("new", forKey: "procedurekittest")
        processProcedure = ProcessProcedure(launchPath: launchPath, environment: environment)
        XCTAssertEqual(processProcedure.environment ?? [:], environment)
    }

    func test__launchPath() {
        XCTAssertEqual(processProcedure.launchPath, launchPath)
    }

    func test__standardError() {
        let pipe = Pipe()
        processProcedure = ProcessProcedure(launchPath: launchPath, standardError: pipe)
        guard let readValue = processProcedure.standardError else {
            XCTFail("standardError is nil")
            return
        }
        guard let readValueAsPipe = readValue as? Pipe else {
            XCTFail("standardError is not expected type")
            return
        }
        XCTAssertEqual(readValueAsPipe, pipe)
    }

    func test__standardInput() {
        let pipe = Pipe()
        processProcedure = ProcessProcedure(launchPath: launchPath, standardInput: pipe)
        guard let readValue = processProcedure.standardInput else {
            XCTFail("standardInput is nil")
            return
        }
        guard let readValueAsPipe = readValue as? Pipe else {
            XCTFail("standardInput is not expected type")
            return
        }
        XCTAssertEqual(readValueAsPipe, pipe)
    }

    func test__standardOutput() {
        let pipe = Pipe()
        processProcedure = ProcessProcedure(launchPath: launchPath, standardOutput: pipe)
        guard let readValue = processProcedure.standardOutput else {
            XCTFail("standardOutput is nil")
            return
        }
        guard let readValueAsPipe = readValue as? Pipe else {
            XCTFail("standardOutput is not expected type")
            return
        }
        XCTAssertEqual(readValueAsPipe, pipe)
    }
}
