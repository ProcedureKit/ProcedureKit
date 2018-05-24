//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
import ProcedureKit
import Foundation
import UIKit
#endif

/**
 Procedure to safely add a child view controller to a parent using
 UIViewController containment.
 */
open class AddChildViewControllerProcedure: UIBlockProcedure {

    /// A block type which receives the child's view to perform any autolayout.
    public typealias SetAutolayoutConstraintsBlockType = (UIView) -> ()

    public init(add child: UIViewController, to parent: UIViewController, with frame: CGRect, in view: UIView, setAutolayoutConstraints: SetAutolayoutConstraintsBlockType? = nil) {
        super.init {
            guard
                parent.view.subviews.contains(view) ||
                    parent.view == view
                else {
                    throw ProcedureKitError.programmingError(reason: "View \(view) is either not in the view hierarchy of the parent view \(parent.view), or is not equal to the parent view.")
            }

            parent.addChildViewController(child)
            child.view.frame = frame
            view.addSubview(child.view)
            setAutolayoutConstraints?(child.view)
            child.didMove(toParentViewController: parent)
        }
    }
}

open class RemoveChildViewControllerProcedure: UIBlockProcedure {

    public init(_ child: UIViewController) {
        super.init {
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }
    }
}
