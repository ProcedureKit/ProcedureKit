//
//  BackgroundObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

internal protocol BackgroundTaskApplicationInterface {
    var applicationState: UIApplicationState { get }
    func beginBackgroundTaskWithName(taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: BackgroundTaskApplicationInterface { }

class BackgroundObserver: NSObject {

    static let backgroundTaskName = "Background Operation Observer"

    private var identifier: UIBackgroundTaskIdentifier? = .None
    private let application: BackgroundTaskApplicationInterface

    private var isInBackground: Bool {
        return application.applicationState == .Background
    }

    override convenience init() {
        self.init(app: UIApplication.sharedApplication())
    }

    internal init(app: BackgroundTaskApplicationInterface) {
        application = app

        super.init()

        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: "didEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: .None)
        nc.addObserver(self, selector: "didBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: .None)

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
        guard let _ = identifier else {
            identifier = application.beginBackgroundTaskWithName(self.dynamicType.backgroundTaskName) {
                self.endBackgroundTask()
            }
            return
        }
    }

    private func endBackgroundTask() {
        if let id = identifier {
            application.endBackgroundTask(id)
            identifier = .None
        }
    }
}

extension BackgroundObserver: OperationObserver {

    func operationDidStart(operation: Operation) {
        // no-op
    }

    func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        // no-op
    }

    func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        endBackgroundTask()
    }
}
