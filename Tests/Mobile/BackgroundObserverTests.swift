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

        let application = TestableUIApplication(state: UIApplicationState.active, didBeginTask: didBeginTask, didEndTask: didEndTask)

        let observer = BackgroundObserver()
        observer.application = application

        procedure.add(observer: observer)

        check(procedure: procedure) { _ in
            application.enterBackground()
        }

        XCTAssertProcedureFinishedWithoutErrors()
        XCTAssertEqual(backgroundTaskName, BackgroundObserver.backgroundTaskName)
        XCTAssertEqual(backgroundTaskIdentifier, endedBackgroundTaskIdentifier)
    }
}
