//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch
#if os(iOS)
import UIKit
#endif

public protocol NetworkActivityIndicatorProtocol {
    var networkActivityIndicatorVisible: Bool { get set }
}

#if os(iOS)
extension UIApplication: NetworkActivityIndicatorProtocol { }
#endif

public class NetworkActivityController {

    #if os(iOS)
    @available(iOSApplicationExtension, unavailable)
    static let shared = NetworkActivityController()
    #endif

    let interval: TimeInterval
    private(set) var indicator: NetworkActivityIndicatorProtocol

    private var count = 0
    private var delayedHide: DispatchWorkItem?

    private let queue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.NetworkActivityController", qos: .userInteractive)

    #if os(iOS)
    /// (iOS-only) Initialize a NetworkActivityController that displays/hides the
    /// network activity indicator in the status bar. (via UIApplication)
    ///
    /// - Parameter timerInterval: How long to wait after observed network activity stops
    ///                            before the network activity indicator is set to false.
    ///                            (This helps reduce flickering if you rapidly create
    ///                            procedures with attached NetworkObservers.)
    @available(iOSApplicationExtension, unavailable, message: "Not supported in Application Extensions because UIApplication.shared is unavailable. Use init(indicator:) or init(timerInterval:indicator:) instead.")
    public convenience init(timerInterval: TimeInterval = 1.0) {
        self.init(timerInterval: timerInterval, indicator: UIApplication.shared)
    }
    #endif

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
            if self.indicator.networkActivityIndicatorVisible != visibility {
                self.indicator.networkActivityIndicatorVisible = visibility
            }
        }
    }
}

public class NetworkObserver: ProcedureObserver {

    private let networkActivityController: NetworkActivityController

    /// Initialize a NetworkObserver with a supplied NetworkActivityController.
    public init(controller: NetworkActivityController) {
        networkActivityController = controller
    }

    #if os(iOS)
    /// (iOS-only) Initialize a NetworkObserver that displays/hides
    /// the network activity indicator in the status bar. (via UIApplication)
    @available(iOSApplicationExtension, unavailable, message: "Not supported in Application Extensions because UIApplication.shared is unavailable. Use init(controller:) instead.")
    public convenience init() {
        self.init(controller: NetworkActivityController.shared)
    }
    #endif

    public func will(execute procedure: Procedure) {
        networkActivityController.start()
    }

    public func did(finish procedure: Procedure, withErrors errors: [Error]) {
        networkActivityController.stop()
    }
}
