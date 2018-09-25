//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMobile

class BackgroundObserverTests: ProcedureKitTestCase {

    var backgroundTaskName: String!
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    var endedBackgroundTaskIdentifier: UIBackgroundTaskIdentifier!

    var didBeginTaskBlock: TestableUIApplication.DidBeginBackgroundTask!
    var didEndTaskBlock: TestableUIApplication.DidEndBackgroundTask!
    var taskGroup: DispatchGroup!
    var observer: BackgroundObserver!

    var testableApplication: TestableUIApplication!
    var testableBackgroundManager: BackgroundManager!

    var backgroundProcedure: WaitsToFinishProcedure!

    // Does not finish until told to (by something external).
    class WaitsToFinishProcedure: Procedure {
        override func execute() {
            // do nothing
        }
    }

    override func setUp() {
        super.setUp()
        Log.enabled = true
        backgroundProcedure = WaitsToFinishProcedure()
        backgroundProcedure.log.writer = TestableLogWriter()
        backgroundTaskName = "Hello world"
        taskGroup = DispatchGroup()
        didBeginTaskBlock = { name, identifier in
            self.taskGroup.enter()
            self.backgroundTaskName = name
            self.backgroundTaskIdentifier = identifier
        }
        didEndTaskBlock = {
            self.endedBackgroundTaskIdentifier = $0
            self.taskGroup.leave()
        }
        testableApplication = TestableUIApplication(state: UIApplication.State.active, didBeginTask: didBeginTaskBlock, didEndTask: didEndTaskBlock)
        testableBackgroundManager = BackgroundManager(app: testableApplication)
    }

    override func tearDown() {
        if let backgroundProcedure = backgroundProcedure {
            backgroundProcedure.cancel()
        }
        backgroundProcedure = nil
        backgroundTaskName = nil
        backgroundTaskIdentifier = nil
        endedBackgroundTaskIdentifier = nil
        didBeginTaskBlock = nil
        didEndTaskBlock = nil
        testableApplication = nil
        testableBackgroundManager = nil
        observer = nil
        taskGroup = nil
        super.tearDown()
    }

    private func waitForTaskGroup(withTimeout timeout: TimeInterval = 3) {
        weak var exp = expectation(description: "Task Group finished")
        taskGroup.notify(queue: DispatchQueue.main) {
            exp?.fulfill()
        }
        waitForExpectations(timeout: timeout)
    }

    // Adds a BackgroundObserver to a Procedure and waits until the observer
    // attempts to begin the background task for the Procedure.
    private func add(backgroundObserver: BackgroundObserver, to procedure: Procedure) {
        assert(Thread.isMainThread)

        let didBeginTask = DispatchGroup()
        didBeginTask.enter()

        testableApplication.didBeginBackgroundTask = { taskName, identifier in
            self.didBeginTaskBlock(taskName, identifier)
            didBeginTask.leave()
        }

        // add the background observer
        procedure.addObserver(backgroundObserver)

        // wait for attaching the BackgroundObserver to attempt to begin the background task
        weak var expDidBeginTask = expectation(description: "Attaching BackgroundObserver did begin background task")
        didBeginTask.notify(queue: DispatchQueue.main) {
            expDidBeginTask?.fulfill()
        }
        waitForExpectations(timeout: 3)
        expDidBeginTask = nil

        // reset
        testableApplication.didBeginBackgroundTask = self.didBeginTaskBlock
    }

    // MARK: Basic Functionality

    // TODO: @swiftlyfalling - These tests fail
    func x_test__background_observer_starts_and_ends_background_task() {

        let expectedBackgroundTaskName = BackgroundManager.backgroundTaskName(for: backgroundProcedure)

        observer = BackgroundObserver(manager: testableBackgroundManager)

        // add the background observer
        add(backgroundObserver: observer, to: backgroundProcedure)

        XCTAssertEqual(taskGroup.wait(timeout: .now()), .timedOut)
        XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
        XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
        XCTAssertEqual(testableApplication.backgroundTasks[0].2, .running)

        backgroundProcedure.addDidExecuteBlockObserver { backgroundProcedure in
            // finish the background procedure once it executes
            backgroundProcedure.finish()
        }
        wait(for: backgroundProcedure)
        waitForTaskGroup()

        PKAssertProcedureFinished(backgroundProcedure)
        XCTAssertEqual(backgroundTaskName, expectedBackgroundTaskName)
        XCTAssertNotEqual(backgroundTaskIdentifier, UIBackgroundTaskIdentifier.invalid)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
        XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
        XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
        XCTAssertEqual(testableApplication.backgroundTasks[0].2, .ended)
    }

    // MARK: When Background Execution is Unavailable

    func test__background_observer__when_background_execution_is_unavailable() {

        let expectedBackgroundTaskName = BackgroundManager.backgroundTaskName(for: backgroundProcedure)

        // simulate the state in which running in the background is not possible
        testableApplication.backgroundExecutionDisabled = true

        observer = BackgroundObserver(manager: testableBackgroundManager)

        // add the background observer
        add(backgroundObserver: observer, to: backgroundProcedure)

        // if background execution isn't possible...
        // 1.) The Application should have received a request to begin a background task
        XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
        XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
        // 2.) But beginBackgroundTask should have returned UIBackgroundTaskInvalid
        XCTAssertEqual(backgroundTaskIdentifier, UIBackgroundTaskIdentifier.invalid)

        // run and finish the Procedure
        backgroundProcedure.addDidExecuteBlockObserver { backgroundProcedure in
            // finish the background procedure once it executes
            backgroundProcedure.finish()
        }
        wait(for: backgroundProcedure)

        // the task group should never finish, since the BackgroundObserver did not successfully
        // register a background task, and thus will never end a background task
        XCTAssertEqual(taskGroup.wait(timeout: .now() + 0.3), .timedOut, "The BackgroundObserver ended a background task - this should not happen, since its attempt at registering a background task should have been unsuccessful.")
        XCTAssertNil(endedBackgroundTaskIdentifier)

        // clean-up - explicitly finish the task group
        taskGroup.leave()

        PKAssertProcedureFinished(backgroundProcedure)
    }

    // MARK: Cancellation Behavior: .never

    // TODO: @swiftlyfalling - These tests fail
    func x_test__background_observer__never_cancel_procedure() {

        let expectedBackgroundTaskName = BackgroundManager.backgroundTaskName(for: backgroundProcedure)

        let didCancel = DispatchGroup()
        didCancel.enter()
        backgroundProcedure.addDidCancelBlockObserver { backgroundProcedure, errors in
            didCancel.leave()
        }

        observer = BackgroundObserver(manager: testableBackgroundManager, cancelProcedure: .never)

        // add the background observer
        add(backgroundObserver: observer, to: backgroundProcedure)

        XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
        XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
        XCTAssertEqual(testableApplication.backgroundTasks[0].2, .running)

        backgroundProcedure.addDidExecuteBlockObserver(synchronizedWith: DispatchQueue.main) { [testableApplication = testableApplication!] backgroundProcedure in
            // enter the background while executing (should not trigger cancel)
            testableApplication.enterBackground()
            XCTAssertEqual(didCancel.wait(timeout: .now() + 0.2), .timedOut, "The Procedure was cancelled after entering the background, even though `cancelProcedure: .never`.")

            // simulate the background execution time expiring while executing (should not trigger cancel)
            testableApplication.simulateBackgroundTimeExpiration()
            XCTAssertEqual(didCancel.wait(timeout: .now() + 0.2), .timedOut, "The Procedure was cancelled after simulating background time expiration, even though `cancelProcedure: .never`.")

            // transition *back* to active (should not trigger cancel)
            testableApplication.becomeActive()
            XCTAssertEqual(didCancel.wait(timeout: .now() + 0.2), .timedOut, "The Procedure was cancelled after leaving the background, even though `cancelProcedure: .never`.")

            backgroundProcedure.finish()
        }
        wait(for: backgroundProcedure)
        waitForTaskGroup()

        PKAssertProcedureFinished(backgroundProcedure)
        XCTAssertEqual(backgroundTaskName, expectedBackgroundTaskName)
        XCTAssertNotEqual(backgroundTaskIdentifier, UIBackgroundTaskIdentifier.invalid)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
        XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
        XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
        XCTAssertEqual(testableApplication.backgroundTasks[0].2, .ended)

        // clean-up
        guard !backgroundProcedure.isCancelled else { return }
        didCancel.leave() // since the Procedure should never have been cancelled
    }

    // MARK: Cancellation Behavior: .whenAppIsBackgrounded

    func test__background_observer__cancel_when_app_is_backgrounded__app_already_in_background() {

        let expectedBackgroundTaskName = BackgroundManager.backgroundTaskName(for: backgroundProcedure)
        testableApplication.enterBackground()

        observer = BackgroundObserver(manager: testableBackgroundManager, cancelProcedure: .whenAppIsBackgrounded)

        let didCancel = DispatchGroup()
        let cancellationError = Protector<Error?>(nil)
        didCancel.enter()
        backgroundProcedure.addDidCancelBlockObserver { backgroundProcedure, error in
            cancellationError.overwrite(with: error)
            didCancel.leave()
        }

        // add the background observer
        add(backgroundObserver: observer, to: backgroundProcedure)

        weak var exp = expectation(description: "Procedure was cancelled")
        didCancel.notify(queue: DispatchQueue.main) {
            exp?.fulfill()
        }
        waitForExpectations(timeout: 3)

        let receivedCancellationError = cancellationError.access
        XCTAssertNotNil(receivedCancellationError)
        XCTAssertTrue(receivedCancellationError is ProcedureKitError.AppWasBackgrounded)

        XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
        XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
    }

    func test__background_observer__cancel_when_app_is_backgrounded__app_transitions_to_background_while_executing() {

        let expectedBackgroundTaskName = BackgroundManager.backgroundTaskName(for: backgroundProcedure)

        observer = BackgroundObserver(manager: testableBackgroundManager, cancelProcedure: .whenAppIsBackgrounded)

        let didCancel = DispatchGroup()
        let cancellationError = Protector<Error?>(nil)
        didCancel.enter()
        backgroundProcedure.addDidCancelBlockObserver { backgroundProcedure, error in
            cancellationError.overwrite(with: error)
            didCancel.leave()
        }

        // add the background observer
        add(backgroundObserver: observer, to: backgroundProcedure)

        // verify that the Procedure isn't cancelled
        XCTAssertEqual(didCancel.wait(timeout: .now() + 0.3), .timedOut)

        // but there should already exist a background task for the Procedure
        XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
        XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
        XCTAssertEqual(testableApplication.backgroundTasks[0].2, .running)

        // simulate entering the background
        testableApplication.enterBackground()

        // wait for cancellation to occur
        weak var exp = expectation(description: "Procedure was cancelled")
        didCancel.notify(queue: DispatchQueue.main) {
            exp?.fulfill()
        }
        waitForExpectations(timeout: 3)

        let receivedCancellationError = cancellationError.access
        XCTAssertNotNil(receivedCancellationError)
        XCTAssertTrue(receivedCancellationError is ProcedureKitError.AppWasBackgrounded)
    }

    // TODO: @swiftlyfalling - These tests fail
    func x_test__background_observer__cancel_when_app_is_backgrounded__app_is_active() {

        let expectedBackgroundTaskName = BackgroundManager.backgroundTaskName(for: backgroundProcedure)

        observer = BackgroundObserver(manager: testableBackgroundManager, cancelProcedure: .whenAppIsBackgrounded)

        // add the background observer
        add(backgroundObserver: observer, to: backgroundProcedure)

        backgroundProcedure.addDidExecuteBlockObserver(synchronizedWith: DispatchQueue.main) { [testableApplication = testableApplication!] backgroundProcedure in
            // verify that the Procedure isn't cancelled
            XCTAssertFalse(backgroundProcedure.isCancelled)

            // but there should already exist a background task for the Procedure
            XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
            XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
            XCTAssertEqual(testableApplication.backgroundTasks[0].2, .running)

            // finish the backgroundProcedure
            backgroundProcedure.finish()
        }

        wait(for: backgroundProcedure)
        waitForTaskGroup()

        PKAssertProcedureFinished(backgroundProcedure)
        XCTAssertEqual(backgroundTaskName, expectedBackgroundTaskName)
        XCTAssertNotEqual(backgroundTaskIdentifier, UIBackgroundTaskIdentifier.invalid)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
        XCTAssertEqual(testableApplication.backgroundTasks.count, 1)
        XCTAssertEqual(testableApplication.backgroundTasks[0].0, expectedBackgroundTaskName)
        XCTAssertEqual(testableApplication.backgroundTasks[0].2, .ended)
    }
}
