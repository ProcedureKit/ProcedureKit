//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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
