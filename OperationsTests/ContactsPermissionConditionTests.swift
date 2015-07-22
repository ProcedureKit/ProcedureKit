//
//  ContactsPermissionConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Contacts
import Operations

@available(iOS 9.0, *)
class AuthorizedContactStore: ContactsAuthenticationManager {

    static func authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus {
        return .Authorized
    }

    func requestAccessForEntityType(entityType: CNEntityType, completionHandler: (Bool, NSError?) -> Void) {
        completionHandler(true, nil)
    }
}

@available(iOS 9.0, *)
class AuthorizedContactStoreWithUndeterminedAccess: ContactsAuthenticationManager {

    var didReceiveAccessRequest = false

    static func authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus {
        return .NotDetermined
    }

    func requestAccessForEntityType(entityType: CNEntityType, completionHandler: (Bool, NSError?) -> Void) {
        didReceiveAccessRequest = true
        completionHandler(true, nil)
    }
}

@available(iOS 9.0, *)
class ContactsPermissionConditionTests: OperationTests {

    func test__contacts_permission_with_authorized_contact_store() {

        let mananger = AuthorizedContactStore()
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation(delay: 1)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        operation.addCondition(ContactsPermissionCondition(manager: mananger))

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.finished)
        }
    }

    func test__contacts_permission_with_authorized_but_not_determined_access() {

        let mananger = AuthorizedContactStoreWithUndeterminedAccess()
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation(delay: 1)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        operation.addCondition(ContactsPermissionCondition(manager: mananger))

        var observedErrors = Array<ErrorType>()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            if op == operation {
                observedErrors = errors
            }
            expectation.fulfill()
        }))

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { _ in
            if let error = observedErrors[0] as? ContactsPermissionCondition.Error {
                XCTAssertTrue(error == ContactsPermissionCondition.Error.NotDetermined)
            }
            else {
                XCTFail("No error message was observer")
            }
        }
    }
}

