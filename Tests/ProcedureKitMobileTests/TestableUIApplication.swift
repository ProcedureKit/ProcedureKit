//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMobile

class TestableUIApplication: BackgroundTaskApplicationProtocol {

    typealias DidBeginBackgroundTask = (String?, UIBackgroundTaskIdentifier) -> Void
    typealias DidEndBackgroundTask = (UIBackgroundTaskIdentifier) -> Void

    var testableApplicationState: UIApplicationState?
    var didBeginBackgroundTask: DidBeginBackgroundTask?
    var didEndBackgroundTask: DidEndBackgroundTask?
    let application = UIApplication.shared

    init(state: UIApplicationState? = nil, didBeginTask: DidBeginBackgroundTask? = nil, didEndTask: DidEndBackgroundTask? = nil) {
        testableApplicationState = state
        didBeginBackgroundTask = didBeginTask
        didEndBackgroundTask = didEndTask
    }


    var applicationState: UIApplicationState {
        return testableApplicationState ?? application.applicationState
    }

    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        let identifier = application.beginBackgroundTask(withName: taskName, expirationHandler: handler)
        didBeginBackgroundTask?(taskName, identifier)
        return identifier
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        application.endBackgroundTask(identifier)
        didEndBackgroundTask?(identifier)
    }


    func enterBackground() {
        testableApplicationState = .background
        NotificationCenter.default.post(name: NSNotification.Name.UIApplicationDidEnterBackground, object: self)
    }

    func becomeActive() {
        testableApplicationState = .active
        NotificationCenter.default.post(name: NSNotification.Name.UIApplicationDidBecomeActive, object: self)
    }
}
