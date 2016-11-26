//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication: NetworkActivityIndicatorProtocol { }

public extension NetworkActivityController {

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

    public convenience init() {
        self.init(controller: NetworkActivityController.shared)
    }
}
