//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication: NetworkActivityIndicatorProtocol { }

public extension NetworkActivityController {

    /// (iOS-only) A shared NetworkActivityController that uses `UIApplication.shared`
    /// to display/hide the network activity indicator in the status bar.
    ///
    /// Since each NetworkActivityController manages its own count of started/stopped
    /// procedures with attached NetworkObservers, you are encouraged to use this
    /// shared NetworkActivityController to manage the network activity indicator
    /// in the status bar (or the convenience initializers that do so).
    static let shared = NetworkActivityController()

    /// (iOS-only) Initialize a NetworkActivityController that displays/hides the
    /// network activity indicator in the status bar. (via UIApplication)
    ///
    /// - Parameter timerInterval: How long to wait after observed network activity stops
    ///                            before the network activity indicator is set to false.
    ///                            (This helps reduce flickering if you rapidly create
    ///                            procedures with attached NetworkObservers.)
    public convenience init(timerInterval: TimeInterval = 1.0) {
        self.init(timerInterval: timerInterval, indicator: UIApplication.shared)
    }
}

public extension NetworkObserver {

    /// (iOS-only) Initialize a NetworkObserver that displays/hides
    /// the network activity indicator in the status bar. (via UIApplication)
    public convenience init() {
        self.init(controller: NetworkActivityController.shared)
    }
}
