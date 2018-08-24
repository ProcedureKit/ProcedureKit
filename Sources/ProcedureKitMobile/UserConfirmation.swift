//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit

public class UserConfirmationCondition: Condition {

    public enum Response {
        case unknown, confirmed, cancelled
    }

    fileprivate var alert: AlertProcedure

    private var response: Response = .unknown

    public init(
        title: String? = NSLocalizedString("User Confirmation", comment: "User Confirmation"),
        message: String? = nil,
        confirmationActionTitle: String = NSLocalizedString("Okay", comment: "Okay"),
        isDestructive: Bool = true,
        cancelActionTitle: String = NSLocalizedString("Cancel", comment: "Cancel"),
        style: UIAlertControllerStyle = .alert,
        from viewController: UIViewController) {

        alert = AlertProcedure(title: title, message: message, style: style, from: viewController, waitForDismissal: true)

        super.init()
        name = "UserConfirmationCondition"
        alert.add(actionWithTitle: confirmationActionTitle, style: isDestructive ? .destructive : .default) { [weak self] _, _ in
            self?.response = .confirmed
        }
        alert.add(actionWithTitle: cancelActionTitle, style: .cancel) { [weak self] _, _ in
            self?.response = .cancelled
        }
        produceDependency(alert)
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
