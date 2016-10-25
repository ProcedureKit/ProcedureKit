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
