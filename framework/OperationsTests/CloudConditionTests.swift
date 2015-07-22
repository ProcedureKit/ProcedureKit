//
//  CloudConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import CloudKit
import Operations

class TestableCloudContainer: CloudContainer {

    let accountStatus: CKAccountStatus
    var accountStatusError: NSError? = .None

    var applicationPermissionStatus: CKApplicationPermissionStatus = .Granted
    var applicationPermissionStatusError: NSError? = .None

    var requestApplicationPermissionStatus: CKApplicationPermissionStatus = .Granted
    var requestApplicationPermissionStatusError: NSError? = .None

    init(accountStatus: CKAccountStatus) {
        self.accountStatus = accountStatus
    }

    func verifyPermissions(permissions: CKApplicationPermissions, requestPermissionIfNecessary: Bool, completion: ErrorType? -> Void) {
        verifyAccountStatusForContainer(self, permissions, requestPermissionIfNecessary, completion)
    }

    func accountStatusWithCompletionHandler(completionHandler: ((CKAccountStatus, NSError!) -> Void)!) {
        completionHandler(accountStatus, accountStatusError)
    }

    func statusForApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock!) {
        completionHandler(applicationPermissionStatus, applicationPermissionStatusError)
    }

    func requestApplicationPermission(applicationPermission: CKApplicationPermissions, completionHandler: CKApplicationPermissionBlock!) {
        completionHandler(requestApplicationPermissionStatus, requestApplicationPermissionStatusError)
    }
}

class CloudConditionTests: OperationTests {

    var operation: TestOperation!
    var container: TestableCloudContainer!

    override func setUp() {
        super.setUp()

        operation = TestOperation(delay: 1)
        container = TestableCloudContainer(accountStatus: .Available)
    }

    override func tearDown() {
        operation = nil
        container = nil
        super.tearDown()
    }

    func test__cloud_container_executes_when_available() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        operation.addCondition(CloudContainerCondition(container: container))

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(self.operation.didExecute)
            XCTAssertTrue(self.operation.finished)
        }
    }

    func test__cloud_container_executes_when_permissions_are_discoverable() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        let condition = CloudContainerCondition(container: container, permissions: .PermissionUserDiscoverability)
        operation.addCondition(condition)

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(self.operation.didExecute)
            XCTAssertTrue(self.operation.finished)
        }
    }

    func test__cloud_container_errors_when_account_status_is_not_available() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        container = TestableCloudContainer(accountStatus: CKAccountStatus.NoAccount)
        let accountStatusError = NSError(domain: "Operations Test", code: 1234, userInfo: nil)
        container.accountStatusError = accountStatusError
        let condition = CloudContainerCondition(container: container)
        operation.addCondition(condition)

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            receivedErrors = errors
            expectation.fulfill()
        }))

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { _ in
            XCTAssertFalse(self.operation.didExecute)
            XCTAssertTrue(self.operation.cancelled)
            if let error = receivedErrors[0] as? CloudContainerCondition.Error {
                XCTAssertTrue(error == CloudContainerCondition.Error.AccountStatusError(accountStatusError))
            }
            else {
                XCTFail("No error message was observed")
            }
        }
    }

    func test__cloud_container_requests_permissions_which_would_be_granted_if_requested() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        container.applicationPermissionStatus = .InitialState
        container.requestApplicationPermissionStatus = .Granted
        let condition = CloudContainerCondition(container: container, permissions: .PermissionUserDiscoverability)
        operation.addCondition(condition)

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            receivedErrors = errors
            expectation.fulfill()
        }))

        runOperation(operation)

        waitForExpectationsWithTimeout(5) { error in
            XCTAssertFalse(self.operation.didExecute)
            XCTAssertTrue(self.operation.cancelled)
            if let error = receivedErrors[0] as? CloudContainerCondition.Error {
                XCTAssertTrue(error == CloudContainerCondition.Error.PermissionRequestRequired)
            }
            else {
                XCTFail("No error message was observer")
            }
        }
    }



}
