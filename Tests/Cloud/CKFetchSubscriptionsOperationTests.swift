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

class CKFetchSubscriptionsOperationTests: CKProcedureTestCase {

    var target: TestCKFetchSubscriptionsOperation!
    var operation: CKProcedure<TestCKFetchSubscriptionsOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchSubscriptionsOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__subscriptionIDs() {
        let subscriptionIDs = [ "an-id", "another-id" ]
        operation.subscriptionIDs = subscriptionIDs
        XCTAssertNotNil(operation.subscriptionIDs)
        XCTAssertEqual(operation.subscriptionIDs ?? [], subscriptionIDs)
        XCTAssertNotNil(target.subscriptionIDs)
        XCTAssertEqual(target.subscriptionIDs ?? [], subscriptionIDs)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchSubscriptionCompletionBlock { subscriptionsBySubscriptionID in
            didExecuteBlock = true
        }
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block() {
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchSubscriptionCompletionBlock { subscriptionsBySubscriptionID in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}
