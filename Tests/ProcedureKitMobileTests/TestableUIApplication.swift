//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitMobile

class TestableUIApplication: BackgroundTaskApplicationProtocol {

    typealias DidBeginBackgroundTask = (String?, UIBackgroundTaskIdentifier) -> Void
    typealias DidEndBackgroundTask = (UIBackgroundTaskIdentifier) -> Void

    enum BackgroundTaskState {
        case running
        case ended
    }

    /// (TaskName, Handler, TaskState)
    typealias BackgroundTasks = [(String?, (() -> Void)?, BackgroundTaskState)]

    let stateLock = PThreadMutex()

    private var testableApplicationState: UIApplication.State { return stateLock.withCriticalScope { _testableApplicationState } }
    var backgroundTasks: BackgroundTasks { return stateLock.withCriticalScope { _backgroundTasks } }
    var didBeginBackgroundTask: DidBeginBackgroundTask? {
        get { return stateLock.withCriticalScope { _didBeginBackgroundTask } }
        set {
            stateLock.withCriticalScope {
                _didBeginBackgroundTask = newValue
            }
        }
    }
    var didEndBackgroundTask: DidEndBackgroundTask? {
        get { return stateLock.withCriticalScope { _didEndBackgroundTask } }
        set {
            stateLock.withCriticalScope {
                _didEndBackgroundTask = newValue
            }
        }
    }
    var backgroundExecutionDisabled: Bool {
        get { return stateLock.withCriticalScope { _backgroundExecutionDisabled } }
        set {
            stateLock.withCriticalScope {
                _backgroundExecutionDisabled = newValue
            }
        }
    }

    private var _didBeginBackgroundTask: DidBeginBackgroundTask?
    private var _didEndBackgroundTask: DidEndBackgroundTask?
    private var _backgroundExecutionDisabled: Bool = false
    private var _testableApplicationState: UIApplication.State
    private var _backgroundTasks: BackgroundTasks = []

    init(state: UIApplication.State = .active, didBeginTask: DidBeginBackgroundTask? = nil, didEndTask: DidEndBackgroundTask? = nil) {
        _testableApplicationState = state
        didBeginBackgroundTask = didBeginTask
        didEndBackgroundTask = didEndTask
    }

    /// - Requires: Must be called from the main thread / queue.
    var applicationState: UIApplication.State {
        guard Thread.isMainThread || DispatchQueue.isMainDispatchQueue else {
            fatalError("applicationState must be read from the main thread (re: UIApplication thread-safety).")
        }
        return stateLock.withCriticalScope { _testableApplicationState }
    }

    /// May be called from any thread.
    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        let identifier: UIBackgroundTaskIdentifier = stateLock.withCriticalScope {
            _backgroundTasks.append((taskName, handler, .running))
            guard !_backgroundExecutionDisabled else {
                return UIBackgroundTaskIdentifier.invalid
            }
            let identifier = _backgroundTasks.count
            assert(identifier != UIBackgroundTaskIdentifier.invalid.rawValue, "Generated an identifier (\(identifier)) == UIBackgroundTaskInvalid, which will break the internals of BackgroundObserver. The TestableUIApplication must be fixed.")
            return UIBackgroundTaskIdentifier(rawValue: identifier)
        }
        didBeginBackgroundTask?(taskName, identifier)
        return identifier
    }

    /// May be called from any thread.
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        stateLock.withCriticalScope { // () -> Bool in
            guard identifier != UIBackgroundTaskIdentifier.invalid else {
                fatalError("Called endBackgroundTask with `UIBackgroundTaskInvalid`.")
            }
            guard identifier.rawValue <= _backgroundTasks.count && identifier.rawValue > 0 else {
                fatalError("Called endBackgroundTask with an invalid identifier.")
            }
            let taskIndex = identifier.rawValue
            guard _backgroundTasks.count > taskIndex else {
                fatalError("Identifier not stored with background tasks.")
            }
            _backgroundTasks[taskIndex].2 = .ended
        }
        didEndBackgroundTask?(identifier)
    }

    /// - Requires: Must be called from the main thread / queue.
    func enterBackground() {
        guard Thread.isMainThread || DispatchQueue.isMainDispatchQueue else {
            fatalError("applicationState must be modified from the main thread (re: UIApplication thread-safety).")
        }
        stateLock.withCriticalScope { _testableApplicationState = .background }
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: self)
    }

    /// - Requires: Must be called from the main thread / queue.
    func simulateBackgroundTimeExpiration() {
        guard Thread.isMainThread || DispatchQueue.isMainDispatchQueue else {
            fatalError("simulateBackgroundTimeExpiration() must be called from the main thread / queue.")
        }
        guard self.testableApplicationState == .background else { fatalError("Cannot simulate background time expiration if the testable application state is not `.background`.") }
        // loop over all registered background tasks and call their expiration handlers
        for (_, handler, state) in self.backgroundTasks {
            guard state == .running else { continue }
            // call expiration handler
            handler?()
        }
    }

    /// - Requires: Must be called from the main thread / queue.
    func becomeActive() {
        guard Thread.isMainThread || DispatchQueue.isMainDispatchQueue else {
            fatalError("applicationState must be modified from the main thread (re: UIApplication thread-safety).")
        }
        stateLock.withCriticalScope { _testableApplicationState = .active }
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: self)
    }
}
