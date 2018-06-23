//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//


import XCTest
import TestingProcedureKit
import Foundation
@testable import ProcedureKitMac

class ProcessProcedureTests: ProcedureKitTestCase {

    var process: Process!
    var processProcedure: ProcessProcedure!

    var launchPath: String!
    var executableURL: URL!
    var arguments: [String]!

    let bash = "/bin/bash"
    let bashWaitIndefinitelyForInput = "read -n1 -r -p \"Wait indefinitely for input\" key"

    override func setUp() {
        super.setUp()

        launchPath = "/bin/echo"
        executableURL = URL(fileURLWithPath: launchPath)
        arguments = [ "Hello World" ]
        processProcedure = ProcessProcedure(launchPath: launchPath, arguments: arguments)
    }

    func test__start_process() {
        wait(for: processProcedure)
        PKAssertProcedureFinished(processProcedure)
    }

    func test__start_process_with_executableurl() {
        processProcedure = ProcessProcedure(executableURL: executableURL, arguments: arguments)
        wait(for: processProcedure)
        PKAssertProcedureFinished(processProcedure)
    }

    func test__start_process_with_launchpath_only() {
        processProcedure = ProcessProcedure(launchPath: launchPath)
        wait(for: processProcedure)
        PKAssertProcedureFinished(processProcedure)
    }

    func test__start_process_with_executableurl_only() {
        processProcedure = ProcessProcedure(executableURL: executableURL)
        wait(for: processProcedure)
        PKAssertProcedureFinished(processProcedure)
    }

    func test__start_process_with_non_existent_launchpath() {
        let nonExistentLaunchPath = "/bin/echo8procedurekit"
        guard !FileManager.default.isExecutableFile(atPath: nonExistentLaunchPath) else {
            // the non-existent launch path used for this test exists on the local system
            XCTFail("Cannot run test. The non-existent launch path exists on this system: \(nonExistentLaunchPath)")
            return
        }
        processProcedure = ProcessProcedure(launchPath: nonExistentLaunchPath)
        wait(for: processProcedure)
        PKAssertProcedureFinishedWithError(processProcedure, ProcessProcedure.Error.invalidLaunchPath)
    }

    func test__start_process_with_non_existent_executableurl() {
        let nonExistentExecutableURL = URL(fileURLWithPath: "/bin/echo8procedurekit")
        guard !FileManager.default.isExecutableFile(atPath: nonExistentExecutableURL.path) else {
            // the non-existent launch path used for this test exists on the local system
            XCTFail("Cannot run test. The non-existent launch path exists on this system: \(nonExistentExecutableURL)")
            return
        }
        processProcedure = ProcessProcedure(executableURL: nonExistentExecutableURL)
        wait(for: processProcedure)
        PKAssertProcedureFinishedWithError(processProcedure, ProcessProcedure.Error.invalidLaunchPath)
    }

    func test__cancel_process_before_launched() {
        processProcedure.cancel()
        wait(for: processProcedure)
        PKAssertProcedureCancelled(processProcedure)
    }

    func test__cancel_process_after_launched() {
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", bashWaitIndefinitelyForInput], processDidLaunch: { processProcedure in
                processProcedure.cancel()
        })
        wait(for: processProcedure, withTimeout: 1)
        PKAssertProcedureCancelled(processProcedure)
    }

    func test__processIdentifier_before_launched() {
        XCTAssertEqual(processProcedure.processIdentifier, 0)
    }

    func test__processIdentifier_after_launched() {
        weak var didExecuteExpectation = expectation(description: "DidExecute: \(#function)")
        let processIdentifier = Protector<Int32>(-1)
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", "sleep 1"], processDidLaunch: { processProcedure in
                let retrievedProcessIdentifier = processProcedure.processIdentifier
                processIdentifier.overwrite(with: retrievedProcessIdentifier)
                DispatchQueue.main.async {
                    didExecuteExpectation?.fulfill()
                }
        })
        wait(for: processProcedure)
        XCTAssertGreaterThan(processIdentifier.access, 0)
    }

    func test__processIdentifier_after_finished() {
        wait(for: processProcedure)
        PKAssertProcedureFinished(processProcedure)
        XCTAssertGreaterThan(processProcedure.processIdentifier, 0)
    }

    func test__suspend_before_launched_returns_false() {
        weak var didSuspendExpectation = expectation(description: "Did Suspend: \(#function)")
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", "sleep 1"])
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
        PKAssertProcedureFinished(processProcedure)
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
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", "sleep 1"])
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
        PKAssertProcedureFinished(processProcedure)
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
        let didFinishGroup = DispatchGroup()
        weak var didSuspendExpectation = expectation(description: "Did Suspend: \(#function)")
        weak var delayPassed = expectation(description: "Delay Passed: \(#function)")
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", "sleep 1"], processDidLaunch: { processProcedure in
                processProcedure.suspend { (success) in
                    DispatchQueue.main.async {
                        XCTAssertTrue(success)
                        didSuspendExpectation?.fulfill()
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                    delayPassed?.fulfill()
                }
        })
        didFinishGroup.enter()
        processProcedure.addDidFinishBlockObserver { procedure, _ in
            didFinishGroup.leave()
        }
        run(operations: processProcedure)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertFalse(processProcedure.isFinished)

        // resume
        weak var didFinishExpectation = expectation(description: "Did Finish: \(#function)")
        didFinishGroup.notify(queue: DispatchQueue.main) {
            didFinishExpectation?.fulfill()
        }
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

    // MARK: - ProcessDidExitCleanly closure

    func test__process_did_exit_cleanly_closure_receives_expected_exit_status_input() {
        let exitStatus: Int32 = 5
        let receivedStatus = Protector<Int32?>(nil)
        let receivedReason = Protector<Process.TerminationReason?>(nil)
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", "exit \(exitStatus)"], processDidExitCleanly: { status, reason in
            receivedStatus.overwrite(with: status)
            receivedReason.overwrite(with: reason)
            return false
        })
        wait(for: processProcedure)

        guard let status = receivedStatus.access, let reason = receivedReason.access else {
            XCTFail("processDidExitCleanly closure was not called. status and/or reason are nil.")
            return
        }
        XCTAssertEqual(status, exitStatus, "processDidExitCleanly closure did not receive expected status (\(exitStatus)); instead, received: \(status))")
        XCTAssertEqual(reason, .exit, "processDidExitCleanly closure did not receive expected reason (.exit); instead, received: \(reason))")
        PKAssertProcedureFinishedWithError(processProcedure, ProcessProcedure.Error.didNotExitCleanly(exitStatus, .exit))
    }

    func test__process_did_exit_cleanly_closure_receives_expected_uncaught_signal_input() {
        let receivedStatus = Protector<Int32?>(nil)
        let receivedReason = Protector<Process.TerminationReason?>(nil)
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", bashWaitIndefinitelyForInput], processDidLaunch: { processProcedure in
            guard let process = processProcedure.process else { assertionFailure("ProcessProcedure.process does not exist"); return }
            DispatchQueue.main.async {
                // Send SIGTERM to the ProcessProcedure's internal Process
                // NOTE: This is only for testing. User code should use `ProcessProcedure.cancel()`.
                process.terminate()
            }
        }, processDidExitCleanly: { status, reason in
            receivedStatus.overwrite(with: status)
            receivedReason.overwrite(with: reason)
            return false
        })
        wait(for: processProcedure)

        guard let status = receivedStatus.access, let reason = receivedReason.access else {
            XCTFail("processDidExitCleanly closure was not called. status and/or reason are nil.")
            return
        }
        XCTAssertEqual(status, SIGTERM, "processDidExitCleanly closure did not receive expected status (\(SIGTERM)); instead, received: \(status))")
        XCTAssertEqual(reason, .uncaughtSignal, "processDidExitCleanly closure did not receive expected reason (.uncaughtSignal); instead, received: \(reason))")
        PKAssertProcedureFinishedWithError(processProcedure, ProcessProcedure.Error.didNotExitCleanly(SIGTERM, .uncaughtSignal))
    }

    // MARK: - Configuration Properties (Read-only)

    func test__arguments() {
        processProcedure = ProcessProcedure(launchPath: launchPath, arguments: arguments)
        XCTAssertEqual(processProcedure.arguments ?? [], arguments)
    }

    func test__currentDirectoryURL() {
        let currentDirectoryPath = "/bin"
        processProcedure = ProcessProcedure(launchPath: launchPath, currentDirectoryPath: currentDirectoryPath)
        XCTAssertEqual(processProcedure.currentDirectoryURL?.path, currentDirectoryPath)
    }

    func test__environment() {
        var environment = ProcessInfo().environment
        environment.updateValue("new", forKey: "procedurekittest")
        processProcedure = ProcessProcedure(launchPath: launchPath, environment: environment)
        XCTAssertEqual(processProcedure.environment ?? [:], environment)
    }

    func test__executableURL() {
        XCTAssertEqual(processProcedure.executableURL?.path, launchPath)
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

    // MARK: - Finishing

    func test__no_requirement__finishes_with_error() {
        processProcedure = ProcessProcedure()
        wait(for: processProcedure)
        PKAssertProcedureFinishedWithError(processProcedure, ProcedureKitError.requirementNotSatisfied())
    }

    func test__process_exit_status_1__finishes_with_error() {
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", "exit 1"])
        wait(for: processProcedure)
        PKAssertProcedureFinishedWithError(processProcedure, ProcessProcedure.Error.didNotExitCleanly(1, .exit))
    }

    func test__process_terminated_with_uncaught_signal__finishes_with_error() {
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", bashWaitIndefinitelyForInput], processDidLaunch: { processProcedure in
            guard let process = processProcedure.process else { assertionFailure("ProcessProcedure.process does not exist"); return }
            DispatchQueue.main.async {
                // Send SIGTERM to the ProcessProcedure's internal Process
                // NOTE: This is only for testing. User code should use `ProcessProcedure.cancel()`.
                process.terminate()
            }
        })
        wait(for: processProcedure)
        PKAssertProcedureFinishedWithError(processProcedure, ProcessProcedure.Error.didNotExitCleanly(SIGTERM, .uncaughtSignal))
    }

    func test__process_did_exit_cleanly_closure_false__finishes_with_error() {
        let didCallClosure = Protector(false)
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", "exit 0"], processDidExitCleanly: { _, _ in
            didCallClosure.overwrite(with: true)
            return false
        })
        wait(for: processProcedure)
        XCTAssertTrue(didCallClosure.access, "processDidExitCleanly closure was not called.")
        PKAssertProcedureFinishedWithError(processProcedure, ProcessProcedure.Error.didNotExitCleanly(0, .exit))
    }

    func test__process_did_exit_cleanly_closure_true__finishes_without_error() {
        let didCallClosure = Protector(false)
        processProcedure = ProcessProcedure(launchPath: bash, arguments: ["-c", "exit 1"], processDidExitCleanly: { _, _ in
            didCallClosure.overwrite(with: true)
            return true
        })
        wait(for: processProcedure)
        XCTAssertTrue(didCallClosure.access, "processDidExitCleanly closure was not called.")
        PKAssertProcedureFinished(processProcedure)
    }
}

extension Process.TerminationReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .exit: return ".exit"
        case .uncaughtSignal: return ".uncaughtSignal"
        }
    }
}
