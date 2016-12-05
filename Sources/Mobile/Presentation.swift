//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import UIKit

public protocol PresentingViewController: class {

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)

    func show(_ viewControllerToShow: UIViewController, sender: Any?)

    func showDetailViewController(_ viewControllerToShow: UIViewController, sender: Any?)
}

public protocol PresentationProcedure {
    associatedtype Presented: UIViewController
    associatedtype Presenting: PresentingViewController
}

public enum PresentationStyle {
    case show, showDetail, present
}

open class UIProcedure<T, V>: Procedure, PresentationProcedure, InputProcedure where T: UIViewController, V: PresentingViewController {
    public typealias Presented = T
    public typealias Presenting = V

    public var input: Pending<Presented> = .pending
    public let presenting: Presenting
    public let style: PresentationStyle
    public let wrapInNavigationController: Bool
    public let sender: Any?
    public let waitForDismissal: Bool

    public init(present: T? = nil, from: V, withStyle style: PresentationStyle, inNavigationController: Bool = true, sender: Any? = nil, waitForDismissal: Bool = false) {
        self.input = Pending(present)
        self.presenting = from
        self.style = style
        self.wrapInNavigationController = inNavigationController
        self.sender = sender
        self.waitForDismissal = waitForDismissal
        super.init()
    }

    open override func execute() {
        guard let viewController = input.value else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            switch strongSelf.style {
            case .present:
                let viewControllerToPresent: UIViewController
                if viewController is UIAlertController || !strongSelf.wrapInNavigationController {
                    viewControllerToPresent = viewController
                }
                else {
                    viewControllerToPresent = UINavigationController(rootViewController: viewController)
                }
                strongSelf.presenting.present(viewControllerToPresent, animated: true, completion: nil)

            case .show:
                strongSelf.presenting.show(viewController, sender: strongSelf.sender)

            case .showDetail:
                strongSelf.presenting.showDetailViewController(viewController, sender: strongSelf.sender)
            }

            guard strongSelf.waitForDismissal else {
                strongSelf.finish()
                return
            }

            // Deal with waiting for dismissal here

        }
    }
}
