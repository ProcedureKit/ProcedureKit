//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit

public class UserConfirmationCondition: Condition {

    public enum Response {
        case unknown, confirmed, cancelled
    }

    fileprivate var alert: AlertProcedure
    private var response: Response = .unknown

    public init(presentAlertFrom presenting: PresentingViewController, withPreferredStyle preferredAlertStyle: UIAlertControllerStyle = .alert, title: String = "User confirmation", message: String? = nil, confirmMessage: String = NSLocalizedString("Okay", comment: "Okay"), isDestructive: Bool = true, cancelMessage: String = NSLocalizedString("Cancel", comment: "Cancel")) {

        alert = AlertProcedure(presentAlertFrom: presenting, withPreferredStyle: preferredAlertStyle, waitForDismissal: true)
        super.init()
        name = "UserConfirmationCondition"
        alert.title = title
        alert.message = message
        alert.add(actionWithTitle: confirmMessage, style: isDestructive ? .destructive : .default) { [weak self] _, _ in
            self?.response = .confirmed
        }
        alert.add(actionWithTitle: cancelMessage, style: .cancel) { [weak self] _, _ in
            self?.response = .cancelled
        }
        produce(dependency: alert)
    }

    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        let result: ConditionResult = {
            switch response {
            case .unknown: return .failure(ProcedureKitError.unknown)
            case .cancelled: return .failure(ProcedureKitError.ConditionEvaluationCancelled())
            case .confirmed: return .success(true)
            }
        }()
        completion(result)
    }
}
