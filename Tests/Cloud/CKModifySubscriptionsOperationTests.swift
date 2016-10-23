//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKModifySubscriptionsOperation: TestCKDatabaseOperation, CKModifySubscriptionsOperationProtocol, AssociatedErrorProtocol {

    typealias AssociatedError = ModifySubscriptionsError<Subscription, String>

    var saved: [Subscription]? = nil
    var deleted: [String]? = nil
    var error: Error? = nil

    var subscriptionsToSave: [Subscription]? = nil
    var subscriptionIDsToDelete: [String]? = nil
    var modifySubscriptionsCompletionBlock: (([Subscription]?, [String]?, Error?) -> Void)? = nil

    init(saved: [Subscription]? = nil, deleted: [String]? = nil, error: Error? = nil) {
        self.saved = saved
        self.deleted = deleted
        self.error = error
        super.init()
    }

    override func main() {
        modifySubscriptionsCompletionBlock?(saved, deleted, error)
    }
}

