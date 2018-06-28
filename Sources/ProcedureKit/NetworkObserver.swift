//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

public protocol NetworkActivityIndicatorProtocol {
    #if swift(>=3.2)
        var isNetworkActivityIndicatorVisible: Bool { get set }
    #else // Swift < 3.2 (Xcode 8.x)
        var networkActivityIndicatorVisible: Bool { get set }
    #endif
}

public class NetworkActivityController {

    let interval: TimeInterval
    private(set) var indicator: NetworkActivityIndicatorProtocol

    private var count = 0
    private var delayedHide: DispatchWorkItem?

    private let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.NetworkActivityController", qos: .userInteractive)

    /// Initialize a NetworkActivityController
    ///
    /// - Parameters:
    ///   - timerInterval: How long to wait after observed network activity stops before
    ///                    the network activity indicator is set to false.
    ///                    (This helps reduce flickering if you rapidly create procedures
    ///                    with attached NetworkObservers.)
    ///   - indicator:     Conforms to `NetworkActivityIndicatorProtocol`.
    ///                    The `indicator`'s `networkActivityIndicatorVisible` property
    ///                    is queried/set by the NetworkActivityController.
    ///                    (NOTE: NetworkActivityController always accesses the indicator's
    ///                    `networkActivityIndicatorVisible` property on the main queue.)
    ///
    public init(timerInterval: TimeInterval = 1.0, indicator: NetworkActivityIndicatorProtocol) {
        self.interval = timerInterval
        self.indicator = indicator
    }

    /// start() is thread-safe
    func start() {
        queue.async {
            self.count += 1
            self.update()
        }
    }

    /// stop() is thread-safe
    func stop() {
        queue.async {
            self.count -= 1
            self.update()
        }
    }

    private func update() {
        if count > 0 {
            updateIndicator(withVisibility: true)
        }
        else if count == 0 {
            let workItem = DispatchWorkItem(block: {
                self.updateIndicator(withVisibility: false)
            })
            delayedHide = workItem
            queue.asyncAfter(deadline: .now() + interval, execute: workItem)
        }
    }

    private func updateIndicator(withVisibility visibility: Bool) {
        delayedHide?.cancel()
        delayedHide = nil
        DispatchQueue.main.async {
            // only set the visibility if it has changed
            #if swift(>=3.2)
                if self.indicator.isNetworkActivityIndicatorVisible != visibility {
                    self.indicator.isNetworkActivityIndicatorVisible = visibility
                }
            #else // Swift < 3.2 (Xcode 8.x)
                if self.indicator.networkActivityIndicatorVisible != visibility {
                    self.indicator.networkActivityIndicatorVisible = visibility
                }
            #endif
        }
    }
}

public class NetworkObserver: ProcedureObserver {

    private let networkActivityController: NetworkActivityController

    /// Initialize a NetworkObserver with a supplied NetworkActivityController.
    public init(controller: NetworkActivityController) {
        networkActivityController = controller
    }

    public func will(execute procedure: Procedure, pendingExecute: PendingExecuteEvent) {
        networkActivityController.start()
    }

    public func did(finish procedure: Procedure, with error: Error?) {
        networkActivityController.stop()
    }
}
