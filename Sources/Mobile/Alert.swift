//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit

public class AlertProcedure<Presenting: PresentingViewController>: UIProcedure<Presenting> {

    public init(presentAlertFrom presenting: Presenting, withPreferredStyle preferredAlertStyle: UIAlertControllerStyle = .alert, waitForDismissal: Bool = false) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: preferredAlertStyle)
        super.init(present: alert, from: presenting, withStyle: .present, inNavigationController: false, sender: nil, waitForDismissal: waitForDismissal)
    }
}
