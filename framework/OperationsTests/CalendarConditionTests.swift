//
//  CalendarConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import EventKit
import Operations

class TestableEventKitAuthorizationManager: EventKitAuthorizationManagerType {

    var authorizationStatus: EKAuthorizationStatus
    var requestedAuthorizationStatus: EKAuthorizationStatus
    var accessAllowed: Bool {
        didSet {
            requestedAuthorizationStatus = accessAllowed ? .Authorized : .Denied
        }
    }
    var didRequestAccess = false

    init(status: EKAuthorizationStatus) {
        authorizationStatus = status
        requestedAuthorizationStatus = status
        accessAllowed = false
    }

    func authorizationStatusForEntityType(entityType: EKEntityType) -> EKAuthorizationStatus {
        return authorizationStatus
    }

    func requestAccessToEntityType(entityType: EKEntityType, completion: EKEventStoreRequestAccessCompletionHandler) {
        didRequestAccess = true
        authorizationStatus = requestedAuthorizationStatus
        completion(accessAllowed, nil)
    }
}

class CalendarConditionTests: OperationTests {

    func test__condition_succeeds__when_access_is_authorized() {

        let manager = TestableEventKitAuthorizationManager(status: .Authorized)
        let operation = TestOperation()
        operation.addCondition(CalendarCondition(type: EKEntityTypeEvent, authorizationManager: manager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)
    }

    func test__condition_fails__when_access_is_denied() {

        let manager = TestableEventKitAuthorizationManager(status: .Denied)
        let operation = TestOperation()
        operation.addCondition(CalendarCondition(type: EKEntityTypeEvent, authorizationManager: manager))

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
            expectation.fulfill()
        })

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertFalse(operation.didExecute)

        if let error = receivedErrors.first as? CalendarCondition.Error {
            switch error {
            case .AuthorizationFailed(let status):
                XCTAssertEqual(status, .Denied)
            }
        }
        else {
            XCTFail("Error message not received.")
        }
    }

    func test__authorization_is_requested__when_access_is_not_determined() {

        let manager = TestableEventKitAuthorizationManager(status: .NotDetermined)
        manager.accessAllowed = true

        let operation = TestOperation()
        operation.addCondition(CalendarCondition(type: EKEntityTypeEvent, authorizationManager: manager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(manager.didRequestAccess)
    }
}

