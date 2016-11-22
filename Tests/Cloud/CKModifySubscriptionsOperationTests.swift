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

class CKModifySubscriptionsOperationTests: CKProcedureTestCase {
    
    var target: TestCKModifySubscriptionsOperation!
    var operation: CKProcedure<TestCKModifySubscriptionsOperation>!
    
    override func setUp() {
        super.setUp()
        target = TestCKModifySubscriptionsOperation()
        operation = CKProcedure(operation: target)
    }
    
    func test__set_get__subscriptionsToSave() {
        let subscriptionsToSave = [ "a-subscription", "another-subscription" ]
        operation.subscriptionsToSave = subscriptionsToSave
        XCTAssertNotNil(operation.subscriptionsToSave)
        XCTAssertEqual(operation.subscriptionsToSave ?? [], subscriptionsToSave)
        XCTAssertNotNil(target.subscriptionsToSave)
        XCTAssertEqual(target.subscriptionsToSave ?? [], subscriptionsToSave)
    }
    
    func test__set_get__recordZoneIDsToDelete() {
        let subscriptionIDsToDelete = [ "a-subscription-id", "another-subscription-id" ]
        operation.subscriptionIDsToDelete = subscriptionIDsToDelete
        XCTAssertNotNil(operation.subscriptionIDsToDelete)
        XCTAssertEqual(operation.subscriptionIDsToDelete ?? [], subscriptionIDsToDelete)
        XCTAssertNotNil(target.subscriptionIDsToDelete)
        XCTAssertEqual(target.subscriptionIDsToDelete ?? [], subscriptionIDsToDelete)
    }
    
    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }
    
    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setModifySubscriptionsCompletionBlock { savedSubscriptions, deletedSubscriptionIDs in
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
        operation.setModifySubscriptionsCompletionBlock { savedSubscriptions, deletedSubscriptionIDs in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureModifySubscriptionsOperationTests: CKProcedureTestCase {
    typealias T = TestCKModifySubscriptionsOperation
    var cloudkit: CloudKitProcedure<T>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKModifySubscriptionsOperation() }
        cloudkit.container = container
        cloudkit.subscriptionsToSave = [ "subscription 1" ]
        cloudkit.subscriptionIDsToDelete = [ "subscription 2 ID" ]
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

    func test__set_get_database() {
        cloudkit.database = "I'm a different database!"
        XCTAssertEqual(cloudkit.database, "I'm a different database!")
    }

    func test__set_get_previousServerChangeToken() {
        cloudkit.previousServerChangeToken = "I'm a different token!"
        XCTAssertEqual(cloudkit.previousServerChangeToken, "I'm a different token!")
    }

    func test__set_get_resultsLimit() {
        cloudkit.resultsLimit = 20
        XCTAssertEqual(cloudkit.resultsLimit, 20)
    }

    func test__set_get_subscriptionsToSave() {
        cloudkit.subscriptionsToSave = [ "subscription 3" ]
        XCTAssertEqual(cloudkit.subscriptionsToSave ?? [], [ "subscription 3" ])
    }

    func test__set_get_subscriptionIDsToDelete() {
        cloudkit.subscriptionIDsToDelete = [ "subscription 2 ID" ]
        XCTAssertEqual(cloudkit.subscriptionIDsToDelete ?? [], [ "subscription 2 ID" ])
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
        cloudkit.setModifySubscriptionsCompletionBlock { _, _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKModifySubscriptionsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKModifySubscriptionsOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setModifySubscriptionsCompletionBlock { _, _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKModifySubscriptionsOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setModifySubscriptionsCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKModifySubscriptionsOperation()
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
        cloudkit.setModifySubscriptionsCompletionBlock { _, _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

