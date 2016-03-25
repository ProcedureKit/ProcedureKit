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
    func beginBackgroundTaskWithName(taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(identifier: UIBackgroundTaskIdentifier)
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

    private var identifier: UIBackgroundTaskIdentifier? = .None
    private let application: BackgroundTaskApplicationInterface

    private var isInBackground: Bool {
        return application.applicationState == .Background
    }

    /// Initialize a `BackgroundObserver`, takes no parameters.
    public override convenience init() {
        self.init(app: UIApplication.sharedApplication())
    }

    init(app: BackgroundTaskApplicationInterface) {
        application = app

        super.init()

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(BackgroundObserver.didEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: .None)
        nc.addObserver(self, selector: #selector(BackgroundObserver.didBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: .None)

        if isInBackground {
            startBackgroundTask()
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @objc func didEnterBackground(notification: NSNotification) {
        if isInBackground {
            startBackgroundTask()
        }
    }

    @objc func didBecomeActive(notification: NSNotification) {
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
            identifier = .None
        }
    }
}

extension BackgroundObserver: OperationDidFinishObserver {

    /// Conforms to `OperationDidFinishObserver`, will end any background task that has been started.
    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        endBackgroundTask()
    }
}
