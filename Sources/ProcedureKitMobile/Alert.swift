//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit

/**
 `AlertProcedure` is a Procedure subclass which will present a `UIAlertController`.

 The alert controller is entirely managed by the procedure. The title, message,
 text fields and actions are set via properties and methods on `AlertProcedure`.

 A key understanding here is that `AlertProcedure` can finish when it is
 dismissed, which is the default behaviour, or after it has presented the alert
 controller.

 In order to finish when the alert is dismissed, it is critical that the alert
 action handler includes logic to call finish. Therefore, the procedure itself
 exposes API to add actions, so that finish is called correctly. Therefore,
 by restricting exposure to the underlying `UIAlertController` this behaviour
 can be guaranteed.
 */
open class AlertProcedure: Procedure {

    internal let controller: UIAlertController

    internal let waitForDismissal: Bool

    // - returns: The presenting view controller
    public weak var viewController: PresentingViewController?


    /**
     The style of the alert controller. (read-only)

     The value of this property is set to the value you specified in the [alertControllerWithTitle:message:preferredStyle:](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/occ/clm/UIAlertController/alertControllerWithTitle:message:preferredStyle:) method. This value determines how the alert is displayed onscreen.

     - returns: the preferred style of the alert
     */
    public var preferredStyle: UIAlertController.Style {
        return controller.preferredStyle
    }

    /**
     The title of the alert.

     The title string is displayed prominently in the alert or action sheet. You should use this string to get the user’s attention and communicate the reason for displaying the alert.

     - returns: the optional title String?
     */
    public var title: String? {
        get { return controller.title }
        set {
            guard false == isExecuting && false == isFinished else { return }
            controller.title = newValue
        }
    }

    /**
     Descriptive text that provides more details about the reason for the alert.

     The message string is displayed below the title string and is less prominent. Use this string to provide additional context about the reason for the alert or about the actions that the user might take.

     - returns: the optional message String?
     */
    public var message: String? {
        get { return controller.message }
        set {
            guard false == isExecuting && false == isFinished else { return }
            controller.message = newValue
        }
    }

    /**
     The array of text fields displayed by the alert. (read-only)

     Use this property to access the text fields displayed by the alert. The text fields are in the order in which you added them to the alert controller. This order also corresponds to the order in which they are displayed in the alert.

     - returns: the optional array of UITextField instances
     */
    public var textFields: [UITextField]? {
        return controller.textFields
    }

    /**
     The actions that the user can take in response to the alert or action sheet. (read-only)

     The actions are in the order in which you added them to the alert controller. This order also corresponds to the order in which they are displayed in the alert or action sheet. The second action in the array is displayed below the first, the third is displayed below the second, and so on.

     - returns: the array of UIAlertAction actions.
     */
    public var actions: [UIAlertAction] {
        return controller.actions
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
        get { return controller.preferredAction }
        set { fatalError("Set the preferred action using the add(actionWithTitle:style:isPreferred:handler:) method.") }
    }

    /**
     Creates an `AlertProcedure`. It must be constructed with the view
     controller which the alert will be presented from. This is stored as a
     weak reference.

     - parameter title: an optional alert title, defaults to nil
     - parameter message: an optional alert message, defaults to nil
     - parameter from: a `UIViewController` instance.
     - parameter waitForDismissal: a Bool, defaults to true, which indicates whether the
          procedure should wait until the alert controller is dismissed until finishing.

     - notes: The presenting view controller is weakly held.
     - notes: The AlertController uses an "alert" style, and it is not possible to use AlertProcedure
       to show "action sheet" style alerts.
     */
    public init(title: String? = nil, message: String? = nil, from viewController: PresentingViewController, waitForDismissal: Bool = true) {
        self.controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.waitForDismissal = waitForDismissal
        self.viewController = viewController
        super.init()
        addCondition(MutuallyExclusive<UIAlertController>())
    }

    @available(*, deprecated: 5.0.0, message: "Use init(title:message:style:from:waitForDismissal:) instead.")
    public convenience init(presentAlertFrom presenting: PresentingViewController, withPreferredStyle preferredAlertStyle: UIAlertController.Style = .alert, waitForDismissal: Bool = true) {
        self.init(title: nil, message: nil, from: presenting, waitForDismissal: waitForDismissal)
    }

    open override func execute() {
        guard false == isCancelled else { return }

        if controller.actions.isEmpty {
            add(actionWithTitle: NSLocalizedString("Okay", comment: "Okay"))
        }

        let present = UIBlockProcedure { [weak self] in
            guard let this = self, let viewController = this.viewController else { return }
            viewController.present(this.controller, animated: true) {
                guard let alsothis = self else { return }
                if false == alsothis.waitForDismissal {
                    alsothis.finish()
                }
            }
        }
        present.system.enabled = false

        do { try produce(operation: present) }
        catch { log.fatal.message("Unable to present alert, error: \(error)") }
    }

    /**
     Adds an action button with a title, style and handler.

     Do not add actions directly to the `UIAlertController`, as
     this will prevent the `AlertProcedure` from correctly finishing.

     - parameter actionWithTitle: an optional String?.
     - parameter style: a `UIAlertActionStyle` which defaults to `.default`.
     - parameter handler: a block which receives the operation, and returns Void.
     */
    @discardableResult public func add(actionWithTitle title: String?, style: UIAlertAction.Style = .default, isPreferred: Bool = false, handler: @escaping (AlertProcedure, UIAlertAction) -> Void = { _, _ in }) -> UIAlertAction {
        let action = UIAlertAction(title: title, style: style) { [weak self] action in
            guard let this = self else { return }
            handler(this, action)
            guard this.isExecuting else { return }
            if this.waitForDismissal {
                this.finish()
            }
        }
        controller.addAction(action)
        if #available(iOS 9.0, *), isPreferred {
            controller.preferredAction = action
        }
        return action
    }

    /**
     Adds a text field to an alert.

     Calling this method adds an editable text field to the alert. You can call this method more than once to add additional text fields. The text fields are stacked in the resulting alert.

     You can add a text field only if the [preferredStyle](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/occ/instp/UIAlertController/preferredStyle) property is set to [UIAlertControllerStyleAlert](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/c/tdef/UIAlertControllerStyle).

     - parameter configurationHandler: A block for configuring the text field prior to displaying the alert. This block has no return value and takes a single parameter corresponding to the text field object. Use that parameter to change the text field properties.
     */
    public func addTextField(configurationHandler: ((UITextField) -> Void)?) {
        controller.addTextField(configurationHandler: configurationHandler)
    }
}


