//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import UIKit
import ProcedureKit

internal protocol BackgroundTaskApplicationProtocol {

    var applicationState: UIApplicationState { get }

    func beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Swift.Void)?) -> UIBackgroundTaskIdentifier

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: BackgroundTaskApplicationProtocol { }

public class BackgroundObserver: NSObject, ProcedureObserver {

    static let backgroundTaskName = "Background Observer"

    private var identifier: UIBackgroundTaskIdentifier? = nil
    internal var application: BackgroundTaskApplicationProtocol = UIApplication.shared

    private var isInBackground: Bool {
        return application.applicationState == .background
    }

    public override init() {
        application = UIApplication.shared
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
        if identifier == nil {
            identifier = application.beginBackgroundTask(withName: BackgroundObserver.backgroundTaskName, expirationHandler: endBackgroundTask)
        }
    }

    private func endBackgroundTask() {
        guard let id = identifier else { return }
        application.endBackgroundTask(id)
        identifier = nil
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {

    }
}
