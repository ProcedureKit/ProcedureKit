//
//  BackgroundObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

@available(iOS 8, *)
public protocol BackgroundTaskApplicationInterface {
    var applicationState: UIApplicationState { get }
    func beginBackgroundTaskWithName(taskName: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(identifier: UIBackgroundTaskIdentifier)
}

@available(iOS 8, *)
extension UIApplication: BackgroundTaskApplicationInterface { }

/**
An observer which will automatically start & stop a background task if the
application enters the background.

Attach a `BackgroundObserver` to an operation which must be completed even
if the app goes in the background.
*/
@available(iOS 8, *)
public class BackgroundObserver {

    private var identifier: UIBackgroundTaskIdentifier? = .None
    internal var application: BackgroundTaskApplicationInterface = UIApplication.sharedApplication()

    private var isInBackground: Bool {
        return application.applicationState == .Background
    }

    private func startBackgroundTaskForOperation(operation: Operation) {
        if identifier == nil {
            identifier = application.beginBackgroundTaskWithName("Background Task for: \(operation.operationName)") {
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

extension BackgroundObserver: OperationDidStartObserver {

    /// Conforms to `OperationDidStartObserver`, will start a background task.
    public func didStartOperation(operation: Operation) {
        startBackgroundTaskForOperation(operation)
    }
}

extension BackgroundObserver: OperationDidFinishObserver {

    /// Conforms to `OperationDidFinishObserver`, will end any background task that has been started.
    public func didFinishOperation(operation: Operation, errors: [ErrorType]) {
        endBackgroundTask()
    }
}
