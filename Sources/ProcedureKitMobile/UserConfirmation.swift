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
        completion({
            switch response {
            case .unknown: return .failure(ProcedureKitError.unknown)
            case .cancelled: return .failure(ProcedureKitError.ConditionEvaluationCancelled())
            case .confirmed: return .success(true)
            }
        }())
    }
}

extension UserConfirmationCondition: Alert {

    /**
     The style of the alert controller. (read-only)

     The value of this property is set to the value you specified in the [alertControllerWithTitle:message:preferredStyle:](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/occ/clm/UIAlertController/alertControllerWithTitle:message:preferredStyle:) method. This value determines how the alert is displayed onscreen.

     - returns: the preferred style of the alert
     */
    public var preferredStyle: UIAlertControllerStyle {
        return alert.preferredStyle
    }

    /**
     The title of the alert.

     The title string is displayed prominently in the alert or action sheet. You should use this string to get the user’s attention and communicate the reason for displaying the alert.

     - returns: the optional title String?
     */
    public var title: String? {
        get { return alert.title }
        set {
            alert.title = newValue
            name = newValue
        }
    }

    /**
     Descriptive text that provides more details about the reason for the alert.

     The message string is displayed below the title string and is less prominent. Use this string to provide additional context about the reason for the alert or about the actions that the user might take.

     - returns: the optional message String?
     */
    public var message: String? {
        get { return alert.message }
        set { alert.message = newValue }
    }

    /**
     The actions that the user can take in response to the alert or action sheet. (read-only)

     The actions are in the order in which you added them to the alert controller. This order also corresponds to the order in which they are displayed in the alert or action sheet. The second action in the array is displayed below the first, the third is displayed below the second, and so on.

     - returns: the array of UIAlertAction actions.
     */
    public var actions: [UIAlertAction] {
        return alert.actions
    }

    /**
     The preferred action for the user to take from an alert.

     The preferred action is relevant for the [UIAlertControllerStyleAlert](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/c/tdef/UIAlertControllerStyle) style only; it is not used by action sheets. When you specify a preferred action, the alert controller highlights the text of that action to give it emphasis. (If the alert also contains a cancel button, the preferred action receives the highlighting instead of the cancel button.) If the iOS device is connected to a physical keyboard, pressing the Return key triggers the preferred action.

     The action object you assign to this property must have already been added to the alert controller’s list of actions. Assigning an object to this property before adding it with the [addAction:](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/occ/instm/UIAlertController/addAction:) method is a programmer error.

     The default value of this property is `nil`.

     - returns: the optional preferredAction, UIAlertAction
     */
    @available (iOS 9.0, *)
    public var preferredAction: UIAlertAction? {
        get { return alert.preferredAction }
        set { alert.preferredAction = newValue }
    }

    /**
     The array of text fields displayed by the alert. (read-only)

     Use this property to access the text fields displayed by the alert. The text fields are in the order in which you added them to the alert controller. This order also corresponds to the order in which they are displayed in the alert.

     - returns: the optional array of UITextField instances
     */
    public var textFields: [UITextField]? {
        return alert.textFields
    }

    /**
     Adds an action button with a title, style and handler.

     Do not add actions directly to the `UIAlertController`, as
     this will prevent the `AlertOperation` from correctly finishing.

     - parameter actionWithTitle: an optional String?.
     - parameter style: a `UIAlertActionStyle` which defaults to `.default`.
     - parameter handler: a block which receives the operation, and returns Void.
     */
    @discardableResult public func add(actionWithTitle title: String?, style: UIAlertActionStyle = .default, handler: @escaping (AlertProcedure, UIAlertAction) -> Void = { _, _ in }) -> UIAlertAction {
        return alert.add(actionWithTitle: title, style: style, handler: handler)
    }
}
