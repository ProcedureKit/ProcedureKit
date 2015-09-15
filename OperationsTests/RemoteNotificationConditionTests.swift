//
//  UserNotificationConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestableRemoteNotificationRegistrar: RemoteNotificationRegistrarType {

    var didRegister = false
    let error: NSError?

    init(error: NSError? = .None) {
        self.error = error
    }
    
    func opr_registerForRemoteNotifications() {
        didRegister = true
        if let error = error {
            RemoteNotificationCondition.didFailToRegisterForRemoteNotifications(error)
        }
        else {
            let data = "I'm a token!".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
            RemoteNotificationCondition.didReceiveNotificationToken(data!)
        }
    }
}


class RemoteNotificationConditionTests: OperationTests {

    func test__condition_succeeds__when_registration_succeeds() {
        let registrar = TestableRemoteNotificationRegistrar()

        let operation = TestOperation()
        operation.addCondition(RemoteNotificationCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
    }

    func test__condition_fails__when_registration_fails() {
        let registrar = TestableRemoteNotificationRegistrar(error: NSError(domain: "me.danthorpe.Operations", code: -10_001, userInfo: nil))

        let operation = TestOperation()
        operation.addCondition(RemoteNotificationCondition(registrar: registrar))

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            receivedErrors = errors
            expectation.fulfill()
        }))

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
        if let error = receivedErrors.first as? RemoteNotificationCondition.Error {
            switch error {
            case .ReceivedError(_):
                break // expected.
            }
        }
        else {
            XCTFail("No error message was observed")
        }
    }
}



