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
    let application = UIApplication.sharedApplication()

    init(state: UIApplicationState? = .None, didBeginTask: DidBeginBackgroundTask? = .None, didEndTask: DidEndBackgroundTask? = .None) {
        testableApplicationState = state
        didBeginBackgroundTask = didBeginTask
        didEndBackgroundTask = didEndTask
    }

    // Mocked functionality

    var applicationState: UIApplicationState {
        return testableApplicationState ?? application.applicationState
    }

    func beginBackgroundTaskWithName(taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        let identifier = application.beginBackgroundTaskWithName(taskName, expirationHandler: handler)
        didBeginBackgroundTask?(name: taskName, identifier: identifier)
        return identifier
    }

    func endBackgroundTask(identifier: UIBackgroundTaskIdentifier) {
        application.endBackgroundTask(identifier)
        didEndBackgroundTask?(identifier: identifier)
    }
}

class BackgroundObserverTests: OperationTests {

    func applicationEntersBackground(application: TestableUIApplication) {
        application.testableApplicationState = UIApplicationState.Background
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidEnterBackgroundNotification, object: self)
    }

    func applicationBecomesActive(application: TestableUIApplication) {
        application.testableApplicationState = UIApplicationState.Active
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidBecomeActiveNotification, object: self)
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
            state: UIApplicationState.Active,
            didBeginTask: didBeginTask,
            didEndTask: didEndTask)

        let operation = TestOperation(delay: 2, produced: TestOperation())
        operation.addObserver(BackgroundObserver(app: application))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        applicationEntersBackground(application)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.finished)

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
            state: UIApplicationState.Active,
            didBeginTask: didBeginTask,
            didEndTask: didEndTask)

        applicationEntersBackground(application)

        let operation = TestOperation(delay: 2)
        operation.addObserver(BackgroundObserver(app: application))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        applicationBecomesActive(application)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.finished)

        XCTAssertNotNil(backgroundTaskName)
        XCTAssertEqual(backgroundTaskName, BackgroundObserver.backgroundTaskName)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
    }
}
