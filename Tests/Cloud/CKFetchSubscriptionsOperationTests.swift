//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitCloud

class TestCKFetchSubscriptionsOperation: TestCKDatabaseOperation, CKFetchSubscriptionsOperationProtocol, AssociatedErrorProtocol {

    typealias AssociatedError = FetchSubscriptionsError<Subscription>

    var subscriptionsByID: [String: Subscription]? = nil
    var error: Error? = nil

    var subscriptionIDs: [String]? = nil
    var fetchSubscriptionCompletionBlock: (([String: Subscription]?, Error?) -> Void)? = nil

    init(subscriptionsByID: [String: Subscription]? = nil, error: Error? = nil) {
        self.subscriptionsByID = subscriptionsByID
        self.error = error
        super.init()
    }

    override func main() {
        fetchSubscriptionCompletionBlock?(subscriptionsByID, error)
    }
}

