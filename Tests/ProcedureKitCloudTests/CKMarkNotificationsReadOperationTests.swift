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

class TestCKMarkNotificationsReadOperation: TestCKOperation, CKMarkNotificationsReadOperationProtocol, AssociatedErrorProtocol {
    typealias AssociatedError = MarkNotificationsReadError<String>

    var notificationIDs: [String] = []
    var error: Error? = nil
    var markNotificationsReadCompletionBlock: (([String]?, Error?) -> Void)? = nil

    init(markIDsToRead: [String] = [], error: Error? = nil) {
        self.notificationIDs = markIDsToRead
        self.error = error
        super.init()
    }

    override func main() {
        markNotificationsReadCompletionBlock?(notificationIDs, error)
    }
}

class CKMarkNotificationsReadOperationTests: CKProcedureTestCase {

    var target: TestCKMarkNotificationsReadOperation!
    var operation: CKProcedure<TestCKMarkNotificationsReadOperation>!
    var toMark: [TestCKMarkNotificationsReadOperation.NotificationID]!

    override func setUp() {
        super.setUp()
        toMark = [ "this-is-an-id", "this-is-another-id" ]
        target = TestCKMarkNotificationsReadOperation(markIDsToRead: toMark)
        operation = CKProcedure(operation: target)
    }

    func test__set_get__notificationIDs() {
        let notificationIDs = [ "an-id", "another-id" ]
        operation.notificationIDs = notificationIDs
        XCTAssertEqual(operation.notificationIDs, notificationIDs)
        XCTAssertEqual(target.notificationIDs, notificationIDs)
    }

    func test__success_without_completion_block() {
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__success_with_completion_block() {
        var didExecuteBlock = false
        var receivedNotificationIDs: [String]?
        operation.setMarkNotificationsReadCompletionBlock { notificationIDsMarkedRead in
            didExecuteBlock = true
            receivedNotificationIDs = notificationIDsMarkedRead
        }
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertEqual(receivedNotificationIDs ?? ["this is not the id you're looking for"], toMark)
    }

    func test__error_without_completion_block() {
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithoutErrors(operation)
    }

    func test__error_with_completion_block() {
        var didExecuteBlock = false
        operation.setMarkNotificationsReadCompletionBlock { notificationIDsMarkedRead in
            didExecuteBlock = true
        }
        target.error = TestError()
        wait(for: operation)
        XCTAssertProcedureFinishedWithErrors(operation, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }
}

class CloudKitProcedureMarkNotificationsReadOperationTests: CKProcedureTestCase {
    typealias T = TestCKMarkNotificationsReadOperation
    var cloudkit: CloudKitProcedure<T>!

    override func setUp() {
        super.setUp()
        cloudkit = CloudKitProcedure(strategy: .immediate) { TestCKMarkNotificationsReadOperation() }
        cloudkit.container = container
        cloudkit.notificationIDs = [ "notification id 1", "notification id 2" ]
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

    func test__set_get__notificationIDs() {
        cloudkit.notificationIDs = [ "notification id 3", "notification id 4" ]
        XCTAssertEqual(cloudkit.notificationIDs, [ "notification id 3", "notification id 4" ])
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
        cloudkit.setMarkNotificationsReadCompletionBlock { _ in
            didExecuteBlock = true
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_without_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKMarkNotificationsReadOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
    }

    func test__error_with_completion_block_set() {
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let operation = TestCKMarkNotificationsReadOperation()
            operation.error = NSError(domain: CKErrorDomain, code: CKError.internalError.rawValue, userInfo: nil)
            return operation
        }

        var didExecuteBlock = false
        cloudkit.setMarkNotificationsReadCompletionBlock { _ in
            didExecuteBlock = true
        }

        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithErrors(cloudkit, count: 1)
        XCTAssertFalse(didExecuteBlock)
    }

    func test__error_which_retries_using_retry_after_key() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKMarkNotificationsReadOperation()
            if shouldError {
                let userInfo = [CKErrorRetryAfterKey: NSNumber(value: 0.001)]
                op.error = NSError(domain: CKErrorDomain, code: CKError.Code.serviceUnavailable.rawValue, userInfo: userInfo)
                shouldError = false
            }
            return op
        }
        var didExecuteBlock = false
        cloudkit.setMarkNotificationsReadCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
    }

    func test__error_which_retries_using_custom_handler() {
        var shouldError = true
        cloudkit = CloudKitProcedure(strategy: .immediate) {
            let op = TestCKMarkNotificationsReadOperation()
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
        cloudkit.setMarkNotificationsReadCompletionBlock { _ in didExecuteBlock = true }
        wait(for: cloudkit)
        XCTAssertProcedureFinishedWithoutErrors(cloudkit)
        XCTAssertTrue(didExecuteBlock)
        XCTAssertTrue(didRunCustomHandler)
    }
    
}

