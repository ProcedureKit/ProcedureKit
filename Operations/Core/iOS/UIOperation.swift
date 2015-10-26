//
//  UIOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 30/08/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import UIKit

// MARK: - UI

/**
A protocol which defines the presentation API used for `UIOperation`. This is mostly to provide testability.
*/
public protocol PresentingViewController: class {

    /**
    Presents the view controller.

    - parameter viewController: the `UIViewController` being presented.
    - parameter animated: a `Bool` flag to indicate whether the presentation should be animated.
    - parameter completion: a completion block which may be nil.
    */
    func presentViewController(viewController: UIViewController, animated: Bool, completion: (() -> Void)?)


    @available(iOS 8.0, *)
    /**
    Shows the view controller.

    - parameter vc: the `UIViewController` being presented.
    - parameter sender: an optional `AnyObject`, usually this is a `UIControl`.
    */
    func showViewController(vc: UIViewController, sender: AnyObject?)

    @available(iOS 8.0, *)
    /**
    Shows the view controller as a detail controller in a split view controller.

    - parameter vc: the `UIViewController` being presented.
    - parameter sender: an optional `AnyObject`, usually this is a `UIControl`.
    */
    func showDetailViewController(vc: UIViewController, sender: AnyObject?)
}

extension UIViewController: PresentingViewController { }

/**
A simple enum to convey how a view controller should be presented. The view controller
which performs the presentation is stored as an associated type, and is generic. So, 
to present a detail view controller from a master view controller say, it would be
used like this

    let from: ViewControllerDisplayStyle = .ShowDetail(masterViewController)
    from.displayController(detailViewController, sender: .None, completion: .None)

This enum is used as an argument for the `UIOperation` class which usually is 
responsible for creating the view controller which is to be presented.
*/
public enum ViewControllerDisplayStyle<ViewController: PresentingViewController> {

    case Show(ViewController)
    case ShowDetail(ViewController)
    case Present(ViewController)

    /// Access the associated view controller.
    public var controller: ViewController {
        switch self {
        case .Show(let controller):
            return controller
        case .ShowDetail(let controller):
            return controller
        case .Present(let controller):
            return controller
        }
    }

    /**
    A function which will present the view controller from the associated view controller property.
    
    When the style is `.Present`, and the controller is not a `UIAlertController`, it is automatically
    placed as the root controller of a `UINavigationController` which is then presented.

    - parameter controller: a `UIViewController` subclass which will be presented.
    - parameter sender: an optional `AnyObject` used as the sender when showing the view controller
    - parameter completion: an optional completion block, defaults to .None.
    */
    public func displayController<C where C: UIViewController>(controller: C, sender: AnyObject?, completion: (() -> Void)? = .None) {
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

/**
`UIOperation` is an `Operation` subclass which is responsible for presenting one view controller
from another view controller. The operation is generic over both of these types. It uses
standard `UIViewController` presentation APIs. These APIs have been condensed into the 
`PresentingViewController` protocol, meaning that the *presenting* generic type is just something
conforming to this protocol. This is for testing purposes, don't let it confuse you, the From 
generic type is your view controller.

However, note that the presenting view controller is associated into a `ViewControllerDisplayStyle`.
This enum lets you define how the view controller should be presented. Either, "show", "show detail" or
"present".
*/
public class UIOperation<C, From where C: UIViewController, From: PresentingViewController>: Operation {

    /// The controller which will be presented.
    public let controller: C

    /// The presenting `ViewControllerDisplayStyle`
    public let from: ViewControllerDisplayStyle<From>

    /// The `AnyObject` sender.
    public let sender: AnyObject?
    let completion: (() -> Void)?

    /**
    Construct a `UIOperation` with the presented view controller, the presenting view controller display 
    style, and optional sender and completion blocks. For example...
    
        let ui = UIOperation(
            controller: detailViewController, 
            displayControllerFrom: .ShowDetail(myViewController)
        )
    
    - parameter controller: the generic `UIViewController` subclass.
    - parameter displayControllerFrom: a ViewControllerDisplayStyle<From> value.
    - parameter sender: an optional `AnyObject` see docs for UIViewController.
    - parameter completion: an optional void block, see docs for UIViewController.
    */
    public init(controller: C, displayControllerFrom from: ViewControllerDisplayStyle<From>, sender: AnyObject? = .None, completion: (() -> Void)? = .None) {
        self.controller = controller
        self.from = from
        self.sender = sender
        self.completion = completion
    }

    /**
    When the operation executes, on the main queue, it calls `displayController` on the
    ViewControllerDisplayStyle, which in turn will execute either `presentViewController`, 
    `showViewController`, or `showDetailViewController`.
    */
    public override func execute() {
        dispatch_async(Queue.Main.queue) {
            self.from.displayController(self.controller, sender: self.sender, completion: self.completion)
        }
    }
}

