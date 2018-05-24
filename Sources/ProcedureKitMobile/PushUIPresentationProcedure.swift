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

open class PushUIPresentationProcedure: UIBlockProcedure {

    public init(push viewControllerToPresent: UIViewController, from: UIViewController, animated: Bool = true) {
        super.init {
            from.present(viewControllerToPresent, animated: animated, completion: { })
        }
    }
}
