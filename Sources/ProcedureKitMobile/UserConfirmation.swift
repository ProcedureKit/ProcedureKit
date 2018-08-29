//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit


/**
 The condition succeeds if the user's response to the shown alert
 is a confirmation action. Else, the condition will fail.

 Therefore, this condition can be attached to procedures which
 require the user to consent. For example, consider deleting
 data or user-generated records. You might present an alert to
 get the user to confirm deletion.
 */
public class UserConfirmationCondition: Condition {

    /// The Response type
    public enum Response {
        case unknown, confirmed, cancelled
    }

    fileprivate var alert: AlertProcedure

    private var response: Response = .unknown


    /// Initialize a new UserConfirmationCondition
    ///
    /// - Parameters:
    ///   - title: a String? the alert title, defaults to "User Confirmation"
    ///   - message: a String?, the alert message, default to nil
    ///   - confirmationActionTitle: a String, the action title which
    ///        indicates the user's confirmation. Defaults to "Okay".
    ///   - isDestructive: a Bool, which indicates if the procedure is
    //         destructive. Defaults to true.
    ///   - cancelActionTitle: a String, the action title for the user
    ///        not confirming. Default to "Cancel"
    ///   - viewController: a UIViewController, the view controller which will
    ///        present the alert controller.
    public init(
        title: String? = NSLocalizedString("User Confirmation", comment: "User Confirmation"),
        message: String? = nil,
        confirmationActionTitle: String = NSLocalizedString("Okay", comment: "Okay"),
        isDestructive: Bool = true,
        cancelActionTitle: String = NSLocalizedString("Cancel", comment: "Cancel"),
        from viewController: UIViewController) {

        alert = AlertProcedure(title: title, message: message, from: viewController, waitForDismissal: true)

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
