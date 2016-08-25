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

    var registrar: TestableRemoteNotificationRegistrar!
    var condition: RemoteNotificationCondition!

    override func setUp() {
        super.setUp()
        registrar = TestableRemoteNotificationRegistrar()
        condition = RemoteNotificationCondition()
        condition.registrar = registrar
    }

    override func tearDown() {
        registrar = nil
        condition = nil
        super.tearDown()
    }

    func test__condition_succeeds__when_registration_succeeds() {
        let operation = TestOperation()
        operation.addCondition(condition)
        waitForOperation(operation)
        XCTAssertTrue(operation.didExecute)
    }

    func test__condition_fails__when_registration_fails() {
        registrar = TestableRemoteNotificationRegistrar(error: NSError(domain: "me.danthorpe.Operations", code: -10_001, userInfo: nil))
        condition.registrar = registrar

        let operation = TestOperation()
        operation.addCondition(condition)

        weak var expectation = expectationWithDescription("Test: \(#function)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
            dispatch_async(Queue.Main.queue, {
                guard let expectation = expectation else { print("Test: \(#function): Finished expectation after timeout"); return }
                expectation.fulfill()
            })
        })

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
