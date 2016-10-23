//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKModifyBadgeOperation: TestCKOperation, CKModifyBadgeOperationProtocol, AssociatedErrorProtocol {

    typealias AssociatedError = PKCKError

    var badgeValue: Int = 0
    var error: Error? = nil

    var modifyBadgeCompletionBlock: ((Error?) -> Void)? = nil

    init(value: Int = 0, error: Error? = nil) {
        self.badgeValue = value
        self.error = error
        super.init()
    }

    override func main() {
        modifyBadgeCompletionBlock?(error)
    }
}
