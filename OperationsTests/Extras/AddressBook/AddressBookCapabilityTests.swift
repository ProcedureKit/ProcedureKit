//
//  AddressBookCapabilityTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 06/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import XCTest
import AddressBook
import Contacts
@testable import Operations

class TestableAddressBookRegistrar: NSObject {

    var authorizationStatus: AddressBookAuthorizationStatus = .NotDetermined
    var didCheckAuthorizationStatusForRequirement: AddressBookAuthorizationStatus.EntityType? = .None

    var responseStatus: AddressBookAuthorizationStatus = .Authorized
    var responseError: NSError? = .None
    var responseSuccess = true
    var didRequestAuthorizationForRequirement: AddressBookAuthorizationStatus.EntityType? = .None

    required override init() { }
}

extension TestableAddressBookRegistrar: AddressBookRegistrarType {

    func opr_authorizationStatusForRequirement(entityType: AddressBookAuthorizationStatus.EntityType) -> AddressBookAuthorizationStatus {
        didCheckAuthorizationStatusForRequirement = entityType
        return authorizationStatus
    }

    func opr_requestAccessForRequirement(entityType: AddressBookAuthorizationStatus.EntityType, completion: (Bool, NSError?) -> Void) {
        didRequestAuthorizationForRequirement = entityType
        authorizationStatus = responseStatus
        completion(responseSuccess, responseError)
    }
}

class AddressBookCapabilityTests: XCTestCase {

    var registrar: TestableAddressBookRegistrar!
    var capability: _AddressBookCapability<TestableAddressBookRegistrar>!

    override func setUp() {
        super.setUp()
        registrar = TestableAddressBookRegistrar()
        capability = _AddressBookCapability(registrar: registrar)
    }

    func test__name_is_set() {
        XCTAssertEqual(capability.name, "Address Book")
    }

    func test__requirement_is_set() {
        XCTAssertEqual(capability.requirement, AddressBookAuthorizationStatus.EntityType.Contacts)
    }

    func test__registrar_is_set() {
        XCTAssertEqual(capability.registrar, registrar)
    }

    func test__is_available() {
        XCTAssertTrue(capability.isAvailable())
    }

    func test__authorization_status_queries_registrar() {
        capability.authorizationStatus { status in
            XCTAssertEqual(self.capability.requirement, self.registrar.didCheckAuthorizationStatusForRequirement!)
            XCTAssertEqual(status, AddressBookAuthorizationStatus.NotDetermined)
        }
    }

    func test_given_not_determined_request_authorization_queries_registrar() {
        var completionWasExecuted = false
        capability.requestAuthorizationWithCompletion {
            completionWasExecuted = true
            XCTAssertEqual(self.capability.requirement, self.registrar.didRequestAuthorizationForRequirement!)
        }
        XCTAssertTrue(completionWasExecuted)
    }

    func test_given_already_authorized_request_authorization_does_not_queries_registrar() {
        capability.registrar.authorizationStatus = .Authorized
        var completionWasExecuted = false
        capability.requestAuthorizationWithCompletion {
            completionWasExecuted = true
            XCTAssertNil(self.registrar.didRequestAuthorizationForRequirement)
        }
        XCTAssertTrue(completionWasExecuted)
    }

    func test_given_already_denied_request_authorization_does_not_queries_registrar() {
        capability.registrar.authorizationStatus = .Denied
        var completionWasExecuted = false
        capability.requestAuthorizationWithCompletion {
            completionWasExecuted = true
            XCTAssertNil(self.registrar.didRequestAuthorizationForRequirement)
        }
        XCTAssertTrue(completionWasExecuted)
    }

    func test_given_already_restricted_request_authorization_does_not_queries_registrar() {
        capability.registrar.authorizationStatus = .Restricted
        var completionWasExecuted = false
        capability.requestAuthorizationWithCompletion {
            completionWasExecuted = true
            XCTAssertNil(self.registrar.didRequestAuthorizationForRequirement)
        }
        XCTAssertTrue(completionWasExecuted)
    }

}







class AddressBookAuthorizationStatusTests: XCTestCase {

    func test__given_status_authorized__requirements_met() {
        XCTAssertTrue(AddressBookAuthorizationStatus.Authorized.isRequirementMet(.Contacts))
    }

    func test__given_status_not_determined__requirements_not_met() {
        XCTAssertFalse(AddressBookAuthorizationStatus.NotDetermined.isRequirementMet(.Contacts))
    }

    func test__given_status_denied__requirements_not_met() {
        XCTAssertFalse(AddressBookAuthorizationStatus.Denied.isRequirementMet(.Contacts))
    }

    func test__given_status_restricted__requirements_not_met() {
        XCTAssertFalse(AddressBookAuthorizationStatus.Restricted.isRequirementMet(.Contacts))
    }
}

class CNAuthorizationStatusTests: XCTestCase {

    func test__given_authorized__address_book_authorization_status_is_correct() {
        XCTAssertEqual(CNAuthorizationStatus.Authorized.addressBookAuthorizationStatus, AddressBookAuthorizationStatus.Authorized)
    }

    func test__given_not_determined__address_book_authorization_status_is_correct() {
        XCTAssertEqual(CNAuthorizationStatus.NotDetermined.addressBookAuthorizationStatus, AddressBookAuthorizationStatus.NotDetermined)
    }

    func test__given_denied__address_book_authorization_status_is_correct() {
        XCTAssertEqual(CNAuthorizationStatus.Denied.addressBookAuthorizationStatus, AddressBookAuthorizationStatus.Denied)
    }

    func test__given_restricted__address_book_authorization_status_is_correct() {
        XCTAssertEqual(CNAuthorizationStatus.Restricted.addressBookAuthorizationStatus, AddressBookAuthorizationStatus.Restricted)
    }
}

class CNEntityTypeTests: XCTestCase {

    func test__given_init_with_address_book_authorization_status_entity() {
        XCTAssertEqual(CNEntityType(entity: AddressBookAuthorizationStatus.EntityType.Contacts), CNEntityType.Contacts)
    }
}

@available(iOS, deprecated=9.0)
class ABAuthorizationStatusTests: XCTestCase {

    func test__given_authorized__address_book_authorization_status_is_correct() {
        XCTAssertEqual(ABAuthorizationStatus.Authorized.addressBookAuthorizationStatus, AddressBookAuthorizationStatus.Authorized)
    }

    func test__given_not_determined__address_book_authorization_status_is_correct() {
        XCTAssertEqual(ABAuthorizationStatus.NotDetermined.addressBookAuthorizationStatus, AddressBookAuthorizationStatus.NotDetermined)
    }

    func test__given_denied__address_book_authorization_status_is_correct() {
        XCTAssertEqual(ABAuthorizationStatus.Denied.addressBookAuthorizationStatus, AddressBookAuthorizationStatus.Denied)
    }

    func test__given_restricted__address_book_authorization_status_is_correct() {
        XCTAssertEqual(ABAuthorizationStatus.Restricted.addressBookAuthorizationStatus, AddressBookAuthorizationStatus.Restricted)
    }
}


