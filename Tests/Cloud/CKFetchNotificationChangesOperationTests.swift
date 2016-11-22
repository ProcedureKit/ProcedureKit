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

class TestCKFetchNotificationChangesOperation: TestCKOperation, CKFetchNotificationChangesOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = FetchNotificationChangesError<ServerChangeToken>

    var error: Error? = nil
    var finalPreviousServerChangeToken: ServerChangeToken? = nil
    var changedNotifications: [Notification]? = nil
    var previousServerChangeToken: ServerChangeToken? = nil
    var resultsLimit: Int = 100
    var moreComing: Bool = false
    var notificationChangedBlock: ((Notification) -> Void)? = nil
    var fetchNotificationChangesCompletionBlock: ((ServerChangeToken?, Error?) -> Void)? = nil

    init(token: ServerChangeToken? = nil, error: Error? = nil) {
        self.finalPreviousServerChangeToken = token
        self.error = error
        super.init()
    }

    override func main() {
        if let changes = changedNotifications, let block = notificationChangedBlock {
            if changes.count > 0 {
                changes.forEach(block)
            }
        }
        fetchNotificationChangesCompletionBlock?(finalPreviousServerChangeToken, error)
    }
}

class CKFetchNotificationChangesOperationTests: CKProcedureTestCase {

    var target: TestCKFetchNotificationChangesOperation!
    var operation: CKProcedure<TestCKFetchNotificationChangesOperation>!

    override func setUp() {
        super.setUp()
        target = TestCKFetchNotificationChangesOperation()
        operation = CKProcedure(operation: target)
    }

    func test__set_get__previousServerChangeToken() {
        let previousServerChangeToken: String = "I'm a server token"
        operation.previousServerChangeToken = previousServerChangeToken
        XCTAssertEqual(operation.previousServerChangeToken, previousServerChangeToken)
        XCTAssertEqual(target.previousServerChangeToken, previousServerChangeToken)
    }
    
    func test__set_get__resultsLimits() {
        let limit: Int = 100
        operation.resultsLimit = limit
        XCTAssertEqual(operation.resultsLimit, limit)
        XCTAssertEqual(target.resultsLimit, limit)
    }

    func test__get__moreComing() {
        target.moreComing = true
        XCTAssertTrue(operation.moreComing)
        target.moreComing = false
        XCTAssertFalse(operation.moreComing)
    }

    func test__set_get__notificationChangedBlock() {
        var setByBlock = false
        let block: (String) -> Void = { notification in
            setByBlock = true
        }
        operation.notificationChangedBlock = block
        XCTAssertNotNil(operation.notificationChangedBlock)
        target.notificationChangedBlock?("notification")
        XCTAssertTrue(setByBlock)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        operation.setFetchNotificationChangesCompletionBlock { _ in
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
        operation.setFetchNotificationChangesCompletionBlock { _ in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureFetchNotificationChangesOperationTests: CKProcedureTestCase {

    var cloudkit: CloudKitProcedure<TestCKFetchNotificationChangesOperation>!

    var setByNotificationChangedBlock: TestCKFetchNotificationChangesOperation.Notification!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKFetchNotificationChangesOperation() }
        cloudkit.container = container
        cloudkit.previousServerChangeToken = token
        cloudkit.resultsLimit = 10
        cloudkit.notificationChangedBlock = { [unowned self] notification in
            self.setByNotificationChangedBlock = notification
        }
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

    func test__set_get_previousServerChangeToken() {
        cloudkit.previousServerChangeToken = "I'm a different token!"
        XCTAssertEqual(cloudkit.previousServerChangeToken, "I'm a different token!")
    }

    func test__set_get_resultsLimit() {
        cloudkit.resultsLimit = 20
        XCTAssertEqual(cloudkit.resultsLimit, 20)
    }

    func test__set_get_notificationChangedBlock() {
        XCTAssertNotNil(cloudkit.notificationChangedBlock)
        cloudkit.notificationChangedBlock?("a notification")
        XCTAssertEqual(setByNotificationChangedBlock, "a notification")
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
        cloudkit.setFetchNotificationChangesCompletionBlock { _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchNotificationChangesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKFetchNotificationChangesOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setFetchNotificationChangesCompletionBlock { _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchNotificationChangesOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setFetchNotificationChangesCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKFetchNotificationChangesOperation()
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
        cloudkit.setFetchNotificationChangesCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}
