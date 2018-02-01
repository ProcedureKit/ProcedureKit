//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit

internal protocol BackgroundTaskApplicationProtocol {

    var applicationState: UIApplicationState { get }

    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Swift.Void)?) -> UIBackgroundTaskIdentifier

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: BackgroundTaskApplicationProtocol { }

public extension ProcedureKitError {

    /// When the app enters (or is already in) the background state,
    /// Procedures with an attached `BackgroundObserver` with
    /// cancellationOption == `.cancelProcedureWhenAppIsBackgrounded`
    /// will be cancelled with this error.
    public struct AppWasBackgrounded: Error {
        internal init() { }
    }
}

/**
 An observer that automatically establishes a background task for the attached `Procedure`, and
 provides (optional) cancellation behavior for background-related events.

 Every `Procedure` with an attached BackgroundObserver begins a [background task](https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html#//apple_ref/doc/uid/TP40007072-CH4-SW3)
 that is ended when either:

 - The `Procedure` finishes.
 - The background execution time expires (and background task expiration handlers are notified).

 (Whichever comes first.)

 ### Handling Background Events

 By default, `BackgroundObserver` will never cancel its attached `Procedure`.

 However, you can optionally specify a `CancellationBehavior` when initializing a `BackgroundObserver`.

 Specifying `.whenAppIsBackgrounded` causes the `BackgroundObserver` to cancel the attached `Procedure`
 with error `ProcedureKitError.AppWasBackgrounded` when the application is backgrounded (or if it is
 already in the background).

 In any case, the `Procedure` still has an associated background task until it finishes, which provides a
 [system-determined finite amount of time](https://developer.apple.com/documentation/uikit/uiapplication/1623029-backgroundtimeremaining) to handle cancellation, clean-up, and finish.

 - NOTE:
 For a short, finite-length `Procedure` that should be completed even if the app goes into the background,
 attach a `BackgroundObserver` with `CancellationBehavior` `.never` (the default).

 - NOTE:
 For a `Procedure` that shouldn't start or continue running if the app goes into the background (or if the
 app is already in the background), attach a `BackgroundObserver` with `CancellationBehavior`
 `.whenAppIsBackgrounded`.
 */
public class BackgroundObserver: ProcedureObserver {

    /// A behavior used to specify when the `BackgroundObserver` will cancel the attached `Procedure`.
    ///
    /// - whenAppIsBackgrounded: when the application is backgrounded (or if it is already backgrounded)
    /// - whenBackgroundExecutionTimeExpires: when the application's background execution time expires
    /// - never: do not cancel the attached Procedure
    public enum CancellationBehavior {
        case whenAppIsBackgrounded
        case never
    }

    private let manager: BackgroundManager
    private let cancelProcedure: CancellationBehavior

    /// Initialize a BackgroundObserver (which internally uses UIApplication.shared).
    ///
    /// - Parameter cancelProcedure: (optional) when to cancel the attached `Procedure` (by default, never)
    public convenience init(cancelProcedure: CancellationBehavior = .never) {
        self.init(manager: BackgroundManager.shared, cancelProcedure: cancelProcedure)
    }

    /// Internal: For testing purposes, initialize with a custom `BackgroundManager`.
    internal init(manager: BackgroundManager, cancelProcedure: CancellationBehavior = .never) {
        self.manager = manager
        self.cancelProcedure = cancelProcedure
    }

    internal static var logMessage_FailedToInitiateBackgroundTask = "Failed to initiate background task / handling for Procedure. (Running in the background may not be possible.)"

    /// Public override of `didAttach(to:)` `ProcedureObserver` method that handles starting
    /// a background task for the attached `Procedure` (and setting up background event handlers).
    ///
    /// - Parameter procedure: the `Procedure`
    public func didAttach(to procedure: Procedure) {
        var result: BackgroundManager.BackgroundHandlingResult = []
        switch cancelProcedure {
        case .never:
            result = manager.startBackgroundHandling(for: procedure, withExpirationHandler: { _ in })
        case .whenAppIsBackgrounded:
            result = manager.startBackgroundHandling(for: procedure, withAppIsInBackgroundHandler: { procedure in
                procedure.cancel(withErrors: [ProcedureKitError.AppWasBackgrounded()])
            }, withExpirationHandler: { _ in })
        }

        guard result.contains(.success) else {
            procedure.log.warning(message: BackgroundObserver.logMessage_FailedToInitiateBackgroundTask)
            return
        }

        if result.contains(.additionalHandlersForThisProcedure) {
            procedure.log.info(message: "More than one BackgroundObserver has been attached to this Procedure")
        }
    }

    /// Public override of `did(finish:)` `ProcedureObserver` method that handles ending the
    /// background task for the attached `Procedure`, as well as cleaning up any background
    /// event handlers.
    ///
    /// - Parameter procedure: the `Procedure`
    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        manager.didFinish(procedure: procedure)
    }
}

/// Used to manage background tasks (and related background-state event handlers) for all Procedures.
internal class BackgroundManager {

    typealias BackgroundTaskExpirationHandler = (Procedure) -> Void
    typealias AppIsInBackgroundHandler = (Procedure) -> Void

    static let shared = BackgroundManager(app: UIApplication.shared)

    private class ProcedureBackgroundRegistry {

        class AppDidEnterBackgroundHandlerRecord {
            let handler: AppDidEnterBackgroundHandler
            init(_ handler: @escaping AppDidEnterBackgroundHandler) {
                self.handler = handler
            }
        }

        enum ProcedureInfo {
            case firstBackgroundTaskIdentifierForProcedure
            case additionalBackgroundTaskIdentifierForProcedure
        }

        typealias AppDidEnterBackgroundHandler = AppIsInBackgroundHandler

        private var _backgroundTasksPerProcedure = [Procedure: [Protector<UIBackgroundTaskIdentifier>]]()
        private var _backgroundEventHandlersPerProcedure = [Procedure: [AppDidEnterBackgroundHandlerRecord]]()
        private let lock = PThreadMutex()

        /// Adds a background task identifier to the registry for a specific `Procedure`.
        ///
        /// While this always succeeds, it will return information about the
        /// state of the registry for that `Procedure`.
        ///
        /// - Parameters:
        ///   - identifier: the `UIBackgroundTaskIdentifier`
        ///   - procedure: the `Procedure`
        /// - Returns: `ProcedureInfo`
        func add(backgroundTaskIdentifier identifier: Protector<UIBackgroundTaskIdentifier>, for procedure: Procedure) -> ProcedureInfo {
            return lock.withCriticalScope {
                guard var backgroundTaskIdentifiers = _backgroundTasksPerProcedure[procedure] else {
                    _backgroundTasksPerProcedure.updateValue([identifier], forKey: procedure)
                    return .firstBackgroundTaskIdentifierForProcedure
                }
                backgroundTaskIdentifiers.append(identifier)
                _backgroundTasksPerProcedure[procedure] = backgroundTaskIdentifiers
                return .additionalBackgroundTaskIdentifierForProcedure
            }
        }

        func add(appDidEnterBackgroundHandler handler: @escaping AppDidEnterBackgroundHandler, for procedure: Procedure) -> AppDidEnterBackgroundHandlerRecord {
            return lock.withCriticalScope {
                let newRecord = AppDidEnterBackgroundHandlerRecord(handler)
                guard var backgroundHandlers = _backgroundEventHandlersPerProcedure[procedure] else {
                    _backgroundEventHandlersPerProcedure.updateValue([newRecord], forKey: procedure)
                    return newRecord
                }
                backgroundHandlers.append(newRecord)
                _backgroundEventHandlersPerProcedure[procedure] = backgroundHandlers
                return newRecord
            }
        }

        /// Claim an AppDidEnterBackgroundHandlerRecord for execution.
        ///
        /// - Returns: `true` if this is the first claim on execution, `false` if the handler has been previously claimed for execution
        func claim(appIsInBackgroundHandler record: AppDidEnterBackgroundHandlerRecord, for procedure: Procedure) -> Bool {
            return lock.withCriticalScope { () -> Bool in
                // verify that the AppIsInBackgroundHandlerRecord is still in the _backgroundEventHandlersPerProcedure
                guard var backgroundHandlersForProcedure = _backgroundEventHandlersPerProcedure[procedure] else { return false }
                guard let handlerRecordIndex = backgroundHandlersForProcedure.index(where: { $0 === record }) else {
                    // otherwise, something else (ex. background state change) already claimed it
                    return false
                }
                backgroundHandlersForProcedure.remove(at: handlerRecordIndex)
                _backgroundEventHandlersPerProcedure[procedure] = backgroundHandlersForProcedure
                return true
            }
        }

        /// Claims all existing AppDidEnterBackgroundHandlerRecords for execution.
        ///
        /// - Returns: all claimed AppDidEnterBackgroundHandlerRecords (by Procedure)
        func claimAllBackgroundHandlersForExecution() -> [Procedure: [AppDidEnterBackgroundHandlerRecord]] {
            return lock.withCriticalScope {
                let claimedHandlers = _backgroundEventHandlersPerProcedure
                _backgroundEventHandlersPerProcedure = [Procedure: [AppDidEnterBackgroundHandlerRecord]]()
                return claimedHandlers
            }
        }

        /// Remove all registered BackgroundTaskIdentifiers and AppDidEnterBackground handlers
        /// for a specified Procedure from the registry.
        ///
        /// - Parameter procedure: the Procedure
        /// - Returns: an array of the removed UIBackgroundTaskIdentifiers
        func remove(for procedure: Procedure) -> [UIBackgroundTaskIdentifier]? {
            let backgroundTasks = lock.withCriticalScope { () -> [Protector<UIBackgroundTaskIdentifier>]? in
                let backgroundTasks = _backgroundTasksPerProcedure.removeValue(forKey: procedure)
                _backgroundEventHandlersPerProcedure.removeValue(forKey: procedure)
                return backgroundTasks
            }
            let backgroundTaskIdentifiers: [UIBackgroundTaskIdentifier]? = backgroundTasks?.flatMap {
                let identifier = $0.returnCurrentAndOverwrite(with: UIBackgroundTaskInvalid)
                guard identifier != UIBackgroundTaskInvalid else { return nil }
                return identifier
            }
            return backgroundTaskIdentifiers
        }
    }

    struct BackgroundHandlingResult: OptionSet {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }

        public static let success                               = BackgroundHandlingResult(rawValue: 1 << 0)
        public static let additionalHandlersForThisProcedure    = BackgroundHandlingResult(rawValue: 1 << 1)
    }

    private let registry = ProcedureBackgroundRegistry()
    private let application: BackgroundTaskApplicationProtocol
    private var appIsInBackground: Bool {
        get { return backgroundStateLock.withCriticalScope { _appIsInBackground } }
        set {
            backgroundStateLock.withCriticalScope {
                _appIsInBackground = newValue
            }
        }
    }
    private var _appIsInBackground: Bool = false
    private let backgroundStateLock = PThreadMutex()

    init(app: BackgroundTaskApplicationProtocol) {
        self.application = app

        // Register to receive Background Enter / Leave notifications
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(BackgroundManager.didEnterBackground(withNotification:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: application)
        nc.addObserver(self, selector: #selector(BackgroundManager.didBecomeActive(withNotification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: application)

        // To obtain the current application state, dispatch to main
        DispatchQueue.main.async {

            let currentlyIsInBackground = (self.application.applicationState == .background)
            self.appIsInBackground = currentlyIsInBackground

            // Upon first retrieval of the current app background state,
            // if the app is backgrounded, dispatch any existing
            // AppIsInBackgroundHandlers for Procedures.
            if currentlyIsInBackground {
                self.executeAppIsInBackgroundHandlers()
            }
        }
    }

    deinit {
        removeNotificationCenterObservers()
    }

    private func executeAppIsInBackgroundHandlers() {
        assert(DispatchQueue.isMainDispatchQueue || Thread.current.isMainThread)
        let handlersByProcedure = registry.claimAllBackgroundHandlersForExecution()
        for (procedure, handlers) in handlersByProcedure {
            // call all the handlers for the Procedure
            handlers.forEach { $0.handler(procedure) }
        }
    }

    @objc func didEnterBackground(withNotification notification: NSNotification) {
        assert(DispatchQueue.isMainDispatchQueue || Thread.current.isMainThread)
        // app entered background
        appIsInBackground = true
        // retrieve and execute the AppIsInBackground handlers for any Procedures
        executeAppIsInBackgroundHandlers()
    }

    @objc func didBecomeActive(withNotification notification: NSNotification) {
        assert(DispatchQueue.isMainDispatchQueue || Thread.current.isMainThread)
        // app became active
        appIsInBackground = false
    }

    /// Begins a background task for the `Procedure`, with an expiration handler.
    ///
    /// The BackgroundManager internally provides an expiration handler for the background task that:
    ///     1.) Calls the provided expirationHandler
    ///     2.) Ends the background task
    ///
    /// - Parameters:
    ///   - procedure: the Procedure
    ///   - expirationHandler: an expiration handler that is called when the background task created for the Procedure is signaled of impending expiration of background time
    func startBackgroundHandling(for procedure: Procedure, withExpirationHandler expirationHandler: @escaping BackgroundTaskExpirationHandler) -> BackgroundHandlingResult {
        // register a background task for the Procedure
        return registerBackgroundTask(for: procedure, withExpirationHandler: expirationHandler)
    }

    /// Begins a background task for the `Procedure`, with a appIsInBackground handler and an expiration handler.
    ///
    /// The BackgroundManager internally provides an expiration handler for the background task that:
    ///     1.) Calls the provided expirationHandler
    ///     2.) Ends the background task
    ///
    /// The appIsInBackground handler is called *once*, when the app first enters the background state
    /// or if the app is *already* in the background state (when background handling is started for the
    /// `Procedure`).
    ///
    /// - Parameters:
    ///   - procedure: the Procedure
    ///   - appIsInBackgroundHandler: a handler that is called (once) when the app first enters the background state or if it is already in the background state.
    ///   - expirationHandler: an expiration handler that is called when the background task created for the Procedure is signaled of impending expiration of background time
    func startBackgroundHandling(for procedure: Procedure, withAppIsInBackgroundHandler appIsInBackgroundHandler: @escaping AppIsInBackgroundHandler, withExpirationHandler expirationHandler: @escaping BackgroundTaskExpirationHandler) -> BackgroundHandlingResult {
        // Register a background task for the Procedure
        let result = registerBackgroundTask(for: procedure, withExpirationHandler: expirationHandler)

        // Register handler for app background state change
        let backgroundHandler = registry.add(appDidEnterBackgroundHandler: appIsInBackgroundHandler, for: procedure)

        // Check if the app is already backgrounded
        if appIsInBackground {
            // If so, this may have happened prior to the call to registry.add(appDidEnterBackgroundHandler:) above
            // in which case there will be no state change to trigger a call of the appIsInBackgroundHandler.

            // So, dispatch async to main immediately
            DispatchQueue.main.async {
                // And then on the main queue, attempt to claim the handler for execution
                guard self.registry.claim(appIsInBackgroundHandler: backgroundHandler, for: procedure) else {
                    // Something else - such as a processed DidEnterBackground event - claimed this
                    // handler for execution. Return immediately to avoid calling the handler twice.
                    return
                }
                backgroundHandler.handler(procedure)
            }
        }

        return result
    }

    /// Must be paired with every successful call to `startBackgroundHandling(for: ...)`
    /// Call it when the procedure didFinish.
    ///
    /// Removes outstanding background tasks and registered background handlers associated with the Procedure
    ///
    /// - Parameter procedure: the Procedure
    func didFinish(procedure: Procedure) {
        // Remove procedure from registry
        guard let procedureBackgroundTasks = registry.remove(for: procedure) else {
            // didFinish(procedure:) called for Procedure that does not currently exist in registry
            return
        }
        // End all background tasks associated with procedure
        for taskIdentifier in procedureBackgroundTasks {
            application.endBackgroundTask(taskIdentifier)
        }
    }

    /// Registers a background task for a Procedure.
    private func registerBackgroundTask(for procedure: Procedure, withExpirationHandler expirationHandler: @escaping BackgroundTaskExpirationHandler) -> BackgroundHandlingResult {
        // register a background task for the Procedure

        let identifier = Protector<UIBackgroundTaskIdentifier>(UIBackgroundTaskInvalid)
        let finalExpirationHandler = { [weak procedure, application, identifier] in
            // call provided expiration handler
            if let procedure = procedure {
                expirationHandler(procedure)
            }

            // claim the identifier (for ending *once*) here
            let claimedIdentifier = identifier.returnCurrentAndOverwrite(with: UIBackgroundTaskInvalid)

            // end background task (if it hasn't already ended)
            guard claimedIdentifier != UIBackgroundTaskInvalid else { return }
            application.endBackgroundTask(claimedIdentifier)
        }

        let createdIdentifier = identifier.write { ward -> UIBackgroundTaskIdentifier in
            ward = application.beginBackgroundTask(withName: BackgroundManager.backgroundTaskName(for: procedure), expirationHandler: finalExpirationHandler)
            return ward
        }

        guard createdIdentifier != UIBackgroundTaskInvalid else {
            // beginBackgroundTask(withName:expirationHandler:) returned `UIBackgroundTaskInvalid`
            // This can happen if running in the background is not possible.
            // Return the empty set of BackgroundHandlingResult
            return []
        }

        // store the identifier in the registrar
        let result = registry.add(backgroundTaskIdentifier: identifier, for: procedure)
        switch result {
        case .firstBackgroundTaskIdentifierForProcedure:
            return [.success]
        case .additionalBackgroundTaskIdentifierForProcedure:
            return [.success, .additionalHandlersForThisProcedure]
        }
    }

    internal static func backgroundTaskName(for procedure: Procedure) -> String {
        return "Background Task for \(String(describing: type(of: procedure))): \"\(procedure.operationName)\""
    }

    private func removeNotificationCenterObservers() {
        // To support iOS < 9.0 and macOS < 10.11, NotificationCenter observers must be removed.
        // (Or a crash may result.)
        // Reference: https://developer.apple.com/reference/foundation/notificationcenter/1415360-addobserver
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        nc.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
}

fileprivate extension Protector {
    func returnCurrentAndOverwrite(with newValue: T) -> T {
        return write { (ward: inout T) -> T in
            let previous = ward
            ward = newValue
            return previous
        }
    }
}
