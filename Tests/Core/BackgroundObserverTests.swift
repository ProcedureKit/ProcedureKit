//
//  BackgroundObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestableUIApplication: BackgroundTaskApplicationInterface {

    typealias DidBeginBackgroundTask = (name: String?, identifier: UIBackgroundTaskIdentifier) -> Void
    typealias DidEndBackgroundTask = (identifier: UIBackgroundTaskIdentifier) -> Void

    var testableApplicationState: UIApplicationState?
    var didBeginBackgroundTask: DidBeginBackgroundTask?
    var didEndBackgroundTask: DidEndBackgroundTask?
    let application = UIApplication.shared()

    init(state: UIApplicationState? = .none, didBeginTask: DidBeginBackgroundTask? = .none, didEndTask: DidEndBackgroundTask? = .none) {
        testableApplicationState = state
        didBeginBackgroundTask = didBeginTask
        didEndBackgroundTask = didEndTask
    }

    // Mocked functionality

    var applicationState: UIApplicationState {
        return testableApplicationState ?? application.applicationState
    }

    func beginBackgroundTaskWithName(_ taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        let identifier = application.beginBackgroundTask(withName: taskName, expirationHandler: handler)
        didBeginBackgroundTask?(name: taskName, identifier: identifier)
        return identifier
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        application.endBackgroundTask(identifier)
        didEndBackgroundTask?(identifier: identifier)
    }
}

class BackgroundObserverTests: OperationTests {

    func applicationEntersBackground(_ application: TestableUIApplication) {
        application.testableApplicationState = UIApplicationState.background
        NotificationCenter.default().post(name: NSNotification.Name.UIApplicationDidEnterBackground, object: self)
    }

    func applicationBecomesActive(_ application: TestableUIApplication) {
        application.testableApplicationState = UIApplicationState.active
        NotificationCenter.default().post(name: NSNotification.Name.UIApplicationDidBecomeActive, object: self)
    }

    func test__background_observer_starts_background_task() {
        var backgroundTaskName: String = "Hello world"
        var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
        var endedBackgroundTaskIdentifier: UIBackgroundTaskIdentifier!

        let didBeginTask: TestableUIApplication.DidBeginBackgroundTask = { name, identifier in
            if let name = name {
                backgroundTaskName = name
            }
            backgroundTaskIdentifier = identifier
        }

        let didEndTask: TestableUIApplication.DidEndBackgroundTask = { identifier in
            endedBackgroundTaskIdentifier = identifier
        }

        let application = TestableUIApplication(
            state: UIApplicationState.active,
            didBeginTask: didBeginTask,
            didEndTask: didEndTask)

        let operation = TestOperation(delay: 2, produced: TestOperation())
        operation.addObserver(BackgroundObserver(app: application))

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        applicationEntersBackground(application)

        waitForExpectations(withTimeout: 5, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.isFinished)

        XCTAssertNotNil(backgroundTaskName)
        XCTAssertEqual(backgroundTaskName, BackgroundObserver.backgroundTaskName)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
    }

    func test__background_observer_starts_in_background_then_becomes_active() {
        var backgroundTaskName: String = "Hello world"
        var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
        var endedBackgroundTaskIdentifier: UIBackgroundTaskIdentifier!

        let didBeginTask: TestableUIApplication.DidBeginBackgroundTask = { (name, identifier) in
            if let name = name {
                backgroundTaskName = name
            }
            backgroundTaskIdentifier = identifier
        }

        let didEndTask: TestableUIApplication.DidEndBackgroundTask = { identifier in
            endedBackgroundTaskIdentifier = identifier
        }

        let application = TestableUIApplication(
            state: UIApplicationState.active,
            didBeginTask: didBeginTask,
            didEndTask: didEndTask)

        applicationEntersBackground(application)

        let operation = TestOperation(delay: 2)
        operation.addObserver(BackgroundObserver(app: application))

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        applicationBecomesActive(application)

        waitForExpectations(withTimeout: 5, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.isFinished)

        XCTAssertNotNil(backgroundTaskName)
        XCTAssertEqual(backgroundTaskName, BackgroundObserver.backgroundTaskName)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
    }
}
