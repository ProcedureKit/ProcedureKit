//
//  UIOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 30/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

// MARK: - UI


public protocol PresentingViewController: class {
    func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)?)

    @available(iOS 8.0, *)
    func showViewController(vc: UIViewController, sender: AnyObject?)

    @available(iOS 8.0, *)
    func showDetailViewController(vc: UIViewController, sender: AnyObject?)
}

extension UIViewController: PresentingViewController { }

public enum ViewControllerDisplayStyle<ViewController: PresentingViewController> {

    case Show(ViewController)
    case ShowDetail(ViewController)
    case Present(ViewController)

    func displayController<C where C: UIViewController>(controller: C, sender: AnyObject?, completion: (() -> Void)?) {
        switch self {

        case .Present(let from):
            if controller is UIAlertController {
                from.presentViewController(controller, animated: true, completion: completion)
            }
            else {
                let nav = UINavigationController(rootViewController: controller)
                from.presentViewController(nav, animated: true, completion: completion)
            }

        case .Show(let from):
            from.showViewController(controller, sender: sender)

        case .ShowDetail(let from):
            from.showDetailViewController(controller, sender: sender)
        }
    }
}

public enum UIOperationError: ErrorType {
    case PresentationViewControllerNotSet
}


public class UIOperation<C, From where C: UIViewController, From: PresentingViewController>: Operation {

    let controller: C
    let from: ViewControllerDisplayStyle<From>
    let sender: AnyObject?
    let completion: (() -> Void)?

    public init(controller: C, displayControllerFrom from: ViewControllerDisplayStyle<From>, sender: AnyObject? = .None, completion: (() -> Void)? = .None) {
        self.controller = controller
        self.from = from
        self.sender = sender
        self.completion = completion
    }

    public override func execute() {
        dispatch_async(Queue.Main.queue) {
            self.from.displayController(self.controller, sender: self.sender, completion: self.completion)
        }
    }
}

