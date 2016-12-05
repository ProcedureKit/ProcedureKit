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

extension UIViewController: PresentingViewController { }

public protocol DismissingViewController: class {
    var didDismissViewControllerBlock: () -> Void { get set }
}

public enum PresentationStyle {
    case show, showDetail, present
}

open class UIProcedure: Procedure {

    public let presented: UIViewController
    public let presenting: PresentingViewController
    public let style: PresentationStyle
    public let wrapInNavigationController: Bool
    public let sender: Any?

    private var shouldFinishAfterPresentating: Bool

    public init<T: UIViewController>(present: T, from: PresentingViewController, withStyle style: PresentationStyle, inNavigationController: Bool = true, sender: Any? = nil) {
        self.presented = present
        self.presenting = from
        self.style = style
        self.wrapInNavigationController = inNavigationController
        self.sender = sender
        self.shouldFinishAfterPresentating = true
        super.init()
    }

    public init<T: UIViewController>(present: T, from: PresentingViewController, withStyle style: PresentationStyle, inNavigationController: Bool = true, sender: Any? = nil, waitForDismissal: Bool) where T: DismissingViewController {
        self.presented = present
        self.presenting = from
        self.style = style
        self.wrapInNavigationController = inNavigationController
        self.sender = sender
        self.shouldFinishAfterPresentating = true
        super.init()
        if waitForDismissal {
            shouldFinishAfterPresentating = false
            present.didDismissViewControllerBlock = { [weak self] in
                guard let strongSelf = self else { return }
                if !strongSelf.shouldFinishAfterPresentating && strongSelf.isExecuting {
                    strongSelf.finish()
                }
            }
        }
    }

    open override func execute() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            switch strongSelf.style {
            case .present:
                let viewControllerToPresent: UIViewController
                if strongSelf.presented is UIAlertController || !strongSelf.wrapInNavigationController {
                    viewControllerToPresent = strongSelf.presented
                }
                else {
                    viewControllerToPresent = UINavigationController(rootViewController: strongSelf.presented)
                }
                strongSelf.presenting.present(viewControllerToPresent, animated: true, completion: nil)

            case .show:
                strongSelf.presenting.show(strongSelf.presented, sender: strongSelf.sender)

            case .showDetail:
                strongSelf.presenting.showDetailViewController(strongSelf.presented, sender: strongSelf.sender)
            }

            if strongSelf.shouldFinishAfterPresentating {
                strongSelf.finish()
                return
            }
        }
    }
}
