//
//  AlertOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

public protocol PresentingViewController: class {
    func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
}

public class AlertOperation: Operation {

    private let controller = UIAlertController(title: .None, message: .None, preferredStyle: .Alert)
    private let presentingController: PresentingViewController?

    public var title: String? {
        get {
            return controller.title
        }
        set {
            controller.title = newValue
            name = newValue
        }
    }

    public var message: String? {
        get {
            return controller.message
        }
        set {
            controller.message = newValue
        }
    }

    public init(presentFromController: PresentingViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) {
        self.presentingController = presentFromController
        super.init()
        addCondition(AlertPresentation())
        addCondition(MutuallyExclusive<UIViewController>())
    }

    public func addActionWithTitle(title: String, style: UIAlertActionStyle = .Default, handler: AlertOperation -> Void = { _ in }) {
        let action = UIAlertAction(title: title, style: style) { [weak self] _ in
            if let weakSelf = self {
                handler(weakSelf)
            }
            self?.finish()
        }
        controller.addAction(action)
    }

    public override func execute() {
        if let presentingController = presentingController {

            if controller.actions.isEmpty {
                addActionWithTitle(NSLocalizedString("Okay", comment: "Okay"))
            }

            dispatch_async(Queue.Main.queue) {
                presentingController.presentViewController(self.controller, animated: true, completion: nil)
            }
        }
        else {
            finish()
        }
    }
}

extension UIViewController: PresentingViewController { }
