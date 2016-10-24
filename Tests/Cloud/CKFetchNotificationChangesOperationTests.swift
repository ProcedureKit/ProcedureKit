//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
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
