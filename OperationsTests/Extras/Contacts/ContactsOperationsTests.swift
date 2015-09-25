//
//  ContactsOperationsTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/09/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import XCTest
import Contacts

@testable import Operations

class TestableContactsRegistrar: ContactsPermissionRegistrar {

    var didAccessStatus = false
    var didRequestAccess = false
    var requestedEntityType: CNEntityType? = .None
    var accessError: NSError? = .None

    var status: CNAuthorizationStatus
    let accessRequestShouldSucceed: Bool

    required init() {
        self.status = .NotDetermined
        self.accessRequestShouldSucceed = true
    }

    init(status: CNAuthorizationStatus, accessRequestShouldSucceed: Bool = true) {
        self.status = status
        self.accessRequestShouldSucceed = accessRequestShouldSucceed
    }

    func opr_authorizationStatusForEntityType(entityType: CNEntityType) -> CNAuthorizationStatus {
        didAccessStatus = true
        requestedEntityType = entityType
        return status
    }

    func opr_requestAccessForEntityType(entityType: CNEntityType, completion: (Bool, NSError?) -> Void) {
        didRequestAccess = true
        requestedEntityType = entityType
        if accessRequestShouldSucceed {
            status = .Authorized
            completion(true, .None)
        }
        else {
            status = .Denied
            completion(false, accessError)
        }
    }
}

class ContactsOperationsTests: OperationTests {

    func test__given_authorization_granted__access_succeeds() {

        let registrar = TestableContactsRegistrar(status: .NotDetermined)
        let operation = TestOperation()
        operation.addCondition(_ContactsCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(registrar.didAccessStatus)
        XCTAssertTrue(registrar.didRequestAccess)
    }

    func test__given_authorization_already_granted__access_succeeds() {

        let registrar = TestableContactsRegistrar(status: .Authorized)
        let operation = TestOperation()
        operation.addCondition(_ContactsCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(registrar.didAccessStatus)
        XCTAssertFalse(registrar.didRequestAccess)
    }

    func test__given_authorization_denied__access_fails() {
        let registrar = TestableContactsRegistrar(status: .NotDetermined, accessRequestShouldSucceed: false)
        let operation = TestOperation()
        operation.addCondition(_ContactsCondition(registrar: registrar))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
        XCTAssertTrue(registrar.didAccessStatus)
        XCTAssertTrue(registrar.didRequestAccess)
    }

}
