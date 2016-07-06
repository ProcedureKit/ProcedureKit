//
//  BackgroundObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

public protocol BackgroundTaskApplicationInterface {
    var applicationState: UIApplicationState { get }
    func beginBackgroundTaskWithName(_ taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: BackgroundTaskApplicationInterface { }

/**
An observer which will automatically start & stop a background task if the
application enters the background.

Attach a `BackgroundObserver` to an operation which must be completed even
if the app goes in the background.
*/
public class BackgroundObserver: NSObject {

    static let backgroundTaskName = "Background Operation Observer"

    private var identifier: UIBackgroundTaskIdentifier? = .none
    private let application: BackgroundTaskApplicationInterface

    private var isInBackground: Bool {
        return application.applicationState == .background
    }

    /// Initialize a `BackgroundObserver`, takes no parameters.
    public override convenience init() {
        self.init(app: UIApplication.shared())
    }

    init(app: BackgroundTaskApplicationInterface) {
        application = app

        super.init()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(BackgroundObserver.didEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: .none)
        nc.addObserver(self, selector: #selector(BackgroundObserver.didBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: .none)

        if isInBackground {
            startBackgroundTask()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func didEnterBackground(_ notification: Notification) {
        if isInBackground {
            startBackgroundTask()
        }
    }

    @objc func didBecomeActive(_ notification: Notification) {
        if !isInBackground {
            endBackgroundTask()
        }
    }

    private func startBackgroundTask() {
        if identifier == nil {
            identifier = application.beginBackgroundTaskWithName(self.dynamicType.backgroundTaskName) {
                self.endBackgroundTask()
            }
        }
    }

    private func endBackgroundTask() {
        if let id = identifier {
            application.endBackgroundTask(id)
            identifier = .none
        }
    }
}

extension BackgroundObserver: OperationDidFinishObserver {

    /// Conforms to `OperationDidFinishObserver`, will end any background task that has been started.
    public func didFinishOperation(_ operation: Operation, errors: [ErrorProtocol]) {
        endBackgroundTask()
    }
}
