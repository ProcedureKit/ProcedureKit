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

public class BackgroundObserver: NSObject {

    public static let backgroundTaskName = "Background Operation Observer"

    private var identifier: UIBackgroundTaskIdentifier? = .None
    private let application: BackgroundTaskApplicationInterface

    private var isInBackground: Bool {
        return application.applicationState == .Background
    }

    public override convenience init() {
        self.init(app: UIApplication.sharedApplication())
    }

    public init(app: BackgroundTaskApplicationInterface) {
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

extension BackgroundObserver: OperationObserver {

    public func operationDidStart(operation: Operation) {
        // no-op
    }

    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        // no-op
    }

    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        endBackgroundTask()
    }
}
