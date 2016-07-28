//
//  AlertOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

/**
An `Operation` subclass for presenting a configured `UIAlertController`.

Initialize the `AlertOperation` with the controller which is presenting
the alert. This "controller" can be a `UIViewController` but, just
needs to be any type conforming to `PresentingViewController`. This can
the used to help unit testing.

To configure the `UIAlertController` you can set the `title` and
`message`, and call `addActionWithTitle(: style: handler:)` on the
operation before adding it to a queue.

For example

    let alert = AlertOperation(presentAlertFrom: self)
    alert.title = NSLocalizedString("A title!", comment: "A Title!")
    alert.message = NSLocalizedString("This is a message.", comment: "This is a message.")
    alert.addActionWithTitle(NSLocalizedString("Ok", comment: "Ok")) { _ in
        println("Did press ok!")
    }
    queue.addOperation(alert)
*/
public class AlertOperation<From: PresentingViewController>: Operation {

    private var uiOperation: UIOperation<UIAlertController, From>

    /// Access the presented `UIAlertController`.
    public var alert: UIAlertController {
        return uiOperation.controller
    }

    /**
    Creates an `AlertOperation`. It must be constructed with the view
    controller which the alert will be presented from.

    - parameter from: a generic type conforming to `PresentingViewController`,
    such as an `UIViewController`
    */
    public init(presentAlertFrom from: From, preferredStyle: UIAlertControllerStyle = .Alert) {
        let controller = UIAlertController(title: .None, message: .None, preferredStyle: preferredStyle)
        uiOperation = UIOperation(controller: controller, displayControllerFrom: .Present(from))
        super.init()
        name = "Alert<\(From.self)>"
        addCondition(MutuallyExclusive<UIViewController>())
    }

    /**
     Call to add an action button with a title, style and handler.

     Do not add actions directly to the `UIAlertController`, as
     this will prevent the `AlertOperation` from correctly finishing.

     - parameter title: a required String.
     - parameter style: a `UIAlertActionStyle` which defaults to `.Default`.
     - parameter handler: a block which receives the operation, and returns Void.
     */
    public func addActionWithTitle(title: String, style: UIAlertActionStyle = .Default, handler: AlertOperation -> Void = { _ in }) -> UIAlertAction {
        let action = UIAlertAction(title: title, style: style) { [weak self] _ in
            if let weakSelf = self {
                handler(weakSelf)
                weakSelf.finish()
            }
        }
        alert.addAction(action)
        return action
    }

    /**
     The actions that the user can take in response to the alert or action sheet. (read-only)

     The actions are in the order in which you added them to the alert controller. This order also corresponds to the order in which they are displayed in the alert or action sheet. The second action in the array is displayed below the first, the third is displayed below the second, and so on.
     */
    public var actions: [UIAlertAction] {
        get {
            return alert.actions
        }
    }

    /**
     The preferred action for the user to take from an alert.

     The preferred action is relevant for the [UIAlertControllerStyleAlert](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/c/tdef/UIAlertControllerStyle) style only; it is not used by action sheets. When you specify a preferred action, the alert controller highlights the text of that action to give it emphasis. (If the alert also contains a cancel button, the preferred action receives the highlighting instead of the cancel button.) If the iOS device is connected to a physical keyboard, pressing the Return key triggers the preferred action.

     The action object you assign to this property must have already been added to the alert controller’s list of actions. Assigning an object to this property before adding it with the [addAction:](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/occ/instm/UIAlertController/addAction:) method is a programmer error.

     The default value of this property is `nil`.
     */
    @available (iOS 9.0, *)
    public var preferredAction: UIAlertAction? {
        get {
            return alert.preferredAction
        }

        set {
            alert.preferredAction = newValue
        }
    }

    /**
     Adds a text field to an alert.

     Calling this method adds an editable text field to the alert. You can call this method more than once to add additional text fields. The text fields are stacked in the resulting alert.

     You can add a text field only if the [preferredStyle](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/occ/instp/UIAlertController/preferredStyle) property is set to [UIAlertControllerStyleAlert](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/c/tdef/UIAlertControllerStyle).

     - parameter configurationHandler: A block for configuring the text field prior to displaying the alert. This block has no return value and takes a single parameter corresponding to the text field object. Use that parameter to change the text field properties.
     */
    public func addTextFieldWithConfigurationHandler(configurationHandler: ((UITextField) -> Void)?) {
        alert.addTextFieldWithConfigurationHandler(configurationHandler)
    }

    /**
     The array of text fields displayed by the alert. (read-only)

     Use this property to access the text fields displayed by the alert. The text fields are in the order in which you added them to the alert controller. This order also corresponds to the order in which they are displayed in the alert.
     */
    public var textFields: [UITextField]? {
        get {
            return alert.textFields
        }
    }

    /**
     The title of the alert.

     The title string is displayed prominently in the alert or action sheet. You should use this string to get the user’s attention and communicate the reason for displaying the alert.
     */
    public var title: String? {
        get {
            return alert.title
        }
        set {
            alert.title = newValue
            name = newValue
        }
    }

    /**
     Descriptive text that provides more details about the reason for the alert.

     The message string is displayed below the title string and is less prominent. Use this string to provide additional context about the reason for the alert or about the actions that the user might take.
     */
    public var message: String? {
        get {
            return alert.message
        }
        set {
            alert.message = newValue
        }
    }

    /**
     The style of the alert controller. (read-only)

     The value of this property is set to the value you specified in the [alertControllerWithTitle:message:preferredStyle:](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAlertController_class/#//apple_ref/occ/clm/UIAlertController/alertControllerWithTitle:message:preferredStyle:) method. This value determines how the alert is displayed onscreen.
     */
    public var preferredStyle: UIAlertControllerStyle {
        get {
            return alert.preferredStyle
        }
    }

    /**
    Will add a default "Okay" action (`NSLocalizedString("Okay", comment: "Okay")`)
    if the alert has no actions. Will then produce the UI operation which presents
    the alert controller.
    */
    public override func execute() {
        if alert.actions.isEmpty {
            addActionWithTitle(NSLocalizedString("Okay", comment: "Okay"))
        }
        uiOperation.log.severity = log.severity
        produceOperation(uiOperation)
    }
}
