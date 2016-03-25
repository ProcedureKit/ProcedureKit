//
//  CalendarCapabilityTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 20/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import EventKit
@testable import Operations

class TestableEventsRegistrar: NSObject {

    var authorizationStatus: EKAuthorizationStatus = .NotDetermined
    var didCheckAuthorizationStatus = false

    var responseStatus: EKAuthorizationStatus = .Authorized
    var accessAllowed: Bool = true
    var accessError: NSError? = .None
    var didRequestAuthorization: EKEntityType? = .None

    required override init() { }
}

extension TestableEventsRegistrar: EventsCapabilityRegistrarType {

    func opr_authorizationStatusForRequirement(requirement: EKEntityType) -> EKAuthorizationStatus {
        didCheckAuthorizationStatus = true
        return authorizationStatus
    }

    func opr_requestAccessForRequirement(requirement: EKEntityType, completion: EKEventStoreRequestAccessCompletionHandler) {
        didRequestAuthorization = requirement
        authorizationStatus = responseStatus
        completion(accessAllowed, accessError)
    }
}

class EKAuthorizationStatusTests: XCTestCase {

    func test__given_status_not_determined__requirements_not_met() {
        let status = EKAuthorizationStatus.NotDetermined
        XCTAssertFalse(status.isRequirementMet(.Event))
    }

    func test__given_status_restricted__requirements_not_met() {
        let status = EKAuthorizationStatus.Restricted
        XCTAssertFalse(status.isRequirementMet(.Event))
    }

    func test__given_status_denied__requirements_not_met() {
        let status = EKAuthorizationStatus.Denied
        XCTAssertFalse(status.isRequirementMet(.Event))
    }

    func test__given_status_authorized__requirements_met() {
        let status = EKAuthorizationStatus.Authorized
        XCTAssertTrue(status.isRequirementMet(.Event))
    }
}

class EventsCapabilityTests: XCTestCase {
    var registrar: TestableEventsRegistrar!
    var capability: EventsCapability!

    override func setUp() {
        super.setUp()
        registrar = TestableEventsRegistrar()
        capability = EventsCapability(.Event)
        capability.registrar = registrar
    }

    override func tearDown() {
        registrar = nil
        capability = nil
        super.tearDown()
    }

    func test__name() {
        XCTAssertEqual(capability.name, "Events")
    }

    func test__requirement_is_set() {
        XCTAssertEqual(capability.requirement, EKEntityType.Event)
    }

    func test__is_available_always() {
        XCTAssertTrue(capability.isAvailable())
    }

    func test__authorization_status_queries_register() {
        capability.authorizationStatus { XCTAssertEqual($0, EKAuthorizationStatus.NotDetermined) }
        XCTAssertTrue(registrar.didCheckAuthorizationStatus)
    }

    func test__given_not_determined_request_authorization() {
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertEqual(registrar.didRequestAuthorization!, EKEntityType.Event)
        XCTAssertTrue(didComplete)
    }

    func test__given_denied_does_not_request() {
        registrar.authorizationStatus = .Denied
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertNil(registrar.didRequestAuthorization)
        XCTAssertTrue(didComplete)
    }

    func test__given_authorized_does_not_request() {
        registrar.authorizationStatus = .Authorized
        var didComplete = false
        capability.requestAuthorizationWithCompletion {
            didComplete = true
        }
        XCTAssertNil(registrar.didRequestAuthorization)
        XCTAssertTrue(didComplete)
    }


}
