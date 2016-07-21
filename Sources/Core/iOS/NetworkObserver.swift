//
//  NetworkObserver.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

protocol NetworkActivityIndicatorInterface {
    var networkActivityIndicatorVisible: Bool { get set }
}

extension UIApplication: NetworkActivityIndicatorInterface { }

/**
An `OperationObserverType` which can be used to manage the network
activity indicator in iOS. Note that this is not an observer of
when the network is available. See `ReachableOperation`.
*/
public class NetworkObserver: OperationWillExecuteObserver, OperationDidFinishObserver {

    let networkActivityIndicator: NetworkActivityIndicatorInterface

    /// Initializer takes no parameters.
    public convenience init() {
        self.init(indicator: UIApplication.shared())
    }

    init(indicator: NetworkActivityIndicatorInterface) {
        networkActivityIndicator = indicator
    }

    /// Conforms to `OperationObserver`, will start the network activity indicator.
    public func willExecuteOperation(_ operation: OldOperation) {
        Queue.main.queue.async {
            NetworkIndicatorController.sharedInstance.networkActivityIndicator = self.networkActivityIndicator
            NetworkIndicatorController.sharedInstance.networkActivityDidStart()
        }
    }

    /// Conforms to `OperationObserver`, will stop the network activity indicator.
    public func didFinishOperation(_ operation: OldOperation, errors: [ErrorProtocol]) {
        Queue.main.queue.async {
            NetworkIndicatorController.sharedInstance.networkActivityIndicator = self.networkActivityIndicator
            NetworkIndicatorController.sharedInstance.networkActivityDidEnd()
        }
    }
}

private class NetworkIndicatorController {

    static let sharedInstance = NetworkIndicatorController()

    private var activityCount = 0
    private var visibilityTimer: Timer?

    var networkActivityIndicator: NetworkActivityIndicatorInterface = UIApplication.shared()

    private init() {
        // Prevents use outside of the shared instance.
    }

    private func updateIndicatorVisibility() {
        if activityCount > 0 && networkActivityIndicator.networkActivityIndicatorVisible == false {
            networkIndicatorShouldShow(true)
        }
        else if activityCount == 0 {
            visibilityTimer = Timer(interval: 1.0) {
                self.networkIndicatorShouldShow(false)
            }
        }
    }

    private func networkIndicatorShouldShow(_ shouldShow: Bool) {
        visibilityTimer?.cancel()
        visibilityTimer = .none
        networkActivityIndicator.networkActivityIndicatorVisible = shouldShow
    }

    // Public API

    func networkActivityDidStart() {
        assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")
        activityCount += 1
        updateIndicatorVisibility()
    }

    func networkActivityDidEnd() {
        assert(Thread.isMainThread, "Altering network activity indicator state can only be done on the main thread.")
        activityCount -= 1
        updateIndicatorVisibility()
    }
}

private struct Timer {

    private var isCancelled = false

    init(interval: TimeInterval, handler: ()->()) {
        let after = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        Queue.main.queue.after(when: after) {
            if self.isCancelled != true {
                handler()
            }
        }
    }

    mutating func cancel() {
        isCancelled = true
    }
}
