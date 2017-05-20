//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import CloudKit
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

    override func tearDown() {
        target = nil
        operation = nil
        super.tearDown()
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

class CloudKitProcedureFetchSubscriptionsOperationTests: CKProcedureTestCase {
    typealias T = TestCKFetchSubscriptionsOperation
    var cloudkit: CloudKitProcedure<T>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchSubscriptionsOperation() }
        cloudkit.container = container
        cloudkit.subscriptionIDs = [ "subscription id 1", "subscription id 2" ]
    }

    override func tearDown() {
        cloudkit = nil
        super.tearDown()
    }

    func test__set_get__errorHandlers() {
        cloudkit.set(errorHandlers: [.internalError: cloudkit.passthroughSuggestedErrorHandler])
        XCTAssertEqual(cloudkit.errorHandlers.count, 1)
        XCTAssertNotNil(cloudkit.errorHandlers[.internalError])
    }

    func test__set_get_container() {
        cloudkit.container = "I'm a different container!"
        XCTAssertEqual(cloudkit.container, "I'm a different container!")
    }

    func test__set_get_subscriptionIDs() {
        cloudkit.subscriptionIDs = [ "subscription id 3", "subscription id 4" ]
        XCTAssertEqual(cloudkit.subscriptionIDs ?? [], [ "subscription id 3", "subscription id 4" ])
    }

    func test__cancellation() {
        cloudkit.cancel()
        wait(for: cloudkit)
        XCTAssertProcedureCancelledWithoutErrors(cloudkit)
    }

    func test__success_without_completion_block_set() {
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__success_with_completion_block_set() {
        var didExecuteBlock = false
        cloudkit.setFetchSubscriptionCompletionBlock { _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchSubscriptionsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchSubscriptionsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setFetchSubscriptionCompletionBlock { _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchSubscriptionsOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setFetchSubscriptionCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchSubscriptionsOperation()
            if shouldError {
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.limitExceeded.rawValue, userInfo: nil)
                shouldError = false
            }
            return op
        }
        var didRunCustomHandler = false
        cloudkit.set(errorHandlerForCode: .limitExceeded) { _, _, _, suggestion in
            didRunCustomHandler = true
            return suggestion
        }

        var didExecuteBlock = false
        cloudkit.setFetchSubscriptionCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

