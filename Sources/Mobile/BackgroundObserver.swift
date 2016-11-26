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

public class BackgroundObserver: NSObject, ProcedureObserver {

    static let backgroundTaskName = "Background Observer"

    private let stateLock = NSLock()
    private var _identifier: UIBackgroundTaskIdentifier? = nil
    private var _log: LoggerProtocol? = nil
    private let application: BackgroundTaskApplicationProtocol

    private var isInBackground: Bool {
        return application.applicationState == .background
    }

    public override convenience init() {
        self.init(app: UIApplication.shared)
    }

    init(app: BackgroundTaskApplicationProtocol) {
        self.application = app
        super.init()
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(BackgroundObserver.didEnterBackground(withNotification:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        nc.addObserver(self, selector: #selector(BackgroundObserver.didBecomeActive(withNotification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)

        if isInBackground {
            startBackgroundTask()
        }
    }

    @objc func didEnterBackground(withNotification notification: NSNotification) {
        guard isInBackground else { return }
        startBackgroundTask()
    }

    @objc func didBecomeActive(withNotification notification: NSNotification) {
        guard !isInBackground else { return }
        endBackgroundTask()
    }

    private func startBackgroundTask() {
        stateLock.withCriticalScope {
            if _identifier == nil {
                _log?.info(message: "Will begin background task as application entered background.")
                _identifier = application.beginBackgroundTask(withName: BackgroundObserver.backgroundTaskName, expirationHandler: endBackgroundTask)
            }
        }
    }

    private func endBackgroundTask() {
        stateLock.withCriticalScope {
            guard let id = _identifier else { return }
            application.endBackgroundTask(id)
            _log?.info(message: "Did end background task.")
            _identifier = nil
        }
    }

    public func didAttach(to procedure: Procedure) {
        stateLock.withCriticalScope {
            _log = procedure.log
        }
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        endBackgroundTask()
    }
}
