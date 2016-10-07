//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMobile

class BackgroundObserverTests: ProcedureKitTestCase {

    var backgroundTaskName: String!
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    var endedBackgroundTaskIdentifier: UIBackgroundTaskIdentifier!

    var didBeginTask: TestableUIApplication.DidBeginBackgroundTask!
    var didEndTask: TestableUIApplication.DidEndBackgroundTask!
    var observer: BackgroundObserver!

    override func setUp() {
        super.setUp()
        backgroundTaskName = "Hello world"
        didBeginTask = { name, identifier in
            self.backgroundTaskName = name
            self.backgroundTaskIdentifier = identifier
        }
        didEndTask = { self.endedBackgroundTaskIdentifier = $0 }
    }

    override func tearDown() {
        backgroundTaskName = nil
        backgroundTaskIdentifier = nil
        endedBackgroundTaskIdentifier = nil
        didBeginTask = nil
        didEndTask = nil
        observer = nil
        super.tearDown()
    }

    func test__background_observer_starts_background_task() {

        let application = TestableUIApplication(state: UIApplicationState.active, didBeginTask: didBeginTask, didEndTask: didEndTask)

        observer = BackgroundObserver(app: application)

        procedure.add(observer: observer)

        check(procedure: procedure) { _ in
            application.enterBackground()
        }

        XCTAssertProcedureFinishedWithoutErrors()
        XCTAssertEqual(backgroundTaskName, BackgroundObserver.backgroundTaskName)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
    }

    func test__background_observer_starts_in_background_then_becomes_active() {

        let application = TestableUIApplication(state: UIApplicationState.background, didBeginTask: didBeginTask, didEndTask: didEndTask)
        application.enterBackground()

        observer = BackgroundObserver(app: application)

        procedure.add(observer: observer)

        check(procedure: procedure) { _ in
            application.becomeActive()
        }

        XCTAssertProcedureFinishedWithoutErrors()
        XCTAssertEqual(backgroundTaskName, BackgroundObserver.backgroundTaskName)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
    }
}
