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

    /// The title of the presented `UIAlertController`.
    public var title: String? {
        get {
            return alert.title
        }
        set {
            alert.title = newValue
            name = newValue
        }
    }

    /// The message body of the presented `UIAlertController`.
    public var message: String? {
        get {
            return alert.message
        }
        set {
            alert.message = newValue
        }
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
        addCondition(AlertPresentation())
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
