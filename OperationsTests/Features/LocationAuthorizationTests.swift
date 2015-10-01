//
//  AuthorizationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation
import CoreLocation
import XCTest
@testable import Operations

class TestableLocationRegistrar: NSObject {

    let fakeLocationManager = CLLocationManager()

    var servicesEnabled = true
    var didCheckServiceEnabled = false

    var authorizationStatus: CLAuthorizationStatus = .NotDetermined
    var didCheckAuthorizationStatus = false

    weak var delegate: CLLocationManagerDelegate!
    var didSetDelegate = false

    var responseStatus: CLAuthorizationStatus = .AuthorizedAlways
    var didRequestAuthorization: LocationUsage?

    required override init() { }
}

extension TestableLocationRegistrar: LocationCapabilityRegistrarType {

    func opr_locationServicesEnabled() -> Bool {
        didCheckServiceEnabled = true
        return servicesEnabled
    }

    func opr_authorizationStatus() -> CLAuthorizationStatus {
        didCheckAuthorizationStatus = true
        return authorizationStatus
    }

    func opr_setDelegate(aDelegate: CLLocationManagerDelegate) {
        didSetDelegate = true
        delegate = aDelegate
    }

    func opr_requestAuthorizationWithRequirement(requirement: LocationUsage) {
        didRequestAuthorization = requirement
        authorizationStatus = responseStatus
        delegate.locationManager!(fakeLocationManager, didChangeAuthorizationStatus: responseStatus)
    }
}

class CLLocationManagerTests: XCTestCase, CLLocationManagerDelegate {

    func test__setting_delegate_works() {
        let manager = CLLocationManager()
        manager.opr_setDelegate(self)
        XCTAssertNotNil(manager.delegate)
    }
}

class LocationCapabilityTests: OperationTests {

    var registrar: TestableLocationRegistrar!
    var capability: _LocationCapability<TestableLocationRegistrar>!

    override func setUp() {
        super.setUp()
        registrar = TestableLocationRegistrar()
        capability = _LocationCapability(.WhenInUse, registrar: registrar)
    }

    override func tearDown() {
        registrar = nil
        capability = nil
        super.tearDown()
    }

    func test__get_status() {

        var completedWithEnabled: Bool? = .None
        var completedWithStatus: _LocationCapability.Status? = .None

        let operation = GetAuthorizationStatus(capability) { enabled, status in
            completedWithEnabled = enabled
            completedWithStatus = status
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        guard let enabled = completedWithEnabled, status = completedWithStatus else {
            XCTFail("Completion block was not executed")
            return
        }

        XCTAssertTrue(enabled)
        XCTAssertEqual(status, CLAuthorizationStatus.NotDetermined)
        XCTAssertTrue(registrar.didCheckServiceEnabled)
        XCTAssertTrue(registrar.didCheckAuthorizationStatus)
        XCTAssertNil(registrar.didRequestAuthorization)
    }

    func test__condition_fails_when_capability_disabled() {
        capability.registrar.servicesEnabled = false

        let operation = TestOperation()
        operation.addCondition(AuthorizedFor(capability))

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
        XCTAssertNil(registrar.didRequestAuthorization)

        if let error = receivedErrors.first as? CapabilityError<_LocationCapability<TestableLocationRegistrar>> {
            switch error {
            case .NotAvailable:
                break
            default:
                XCTFail("Incorrect error returned from condition.")
            }
        }
        else {
            XCTFail("No error received from condition.")
        }
    }

    func test__condition_fails_when_status_denied() {
        capability.registrar.authorizationStatus = .Denied

        let operation = TestOperation()
        operation.addCondition(AuthorizedFor(capability))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
        XCTAssertNil(registrar.didRequestAuthorization)
    }

    func test__condition_fails_when_status_misses_requirements() {
        registrar.authorizationStatus = .AuthorizedWhenInUse
        registrar.responseStatus = .AuthorizedWhenInUse
        capability = _LocationCapability(.Always, registrar: registrar)

        let operation = TestOperation()
        operation.addCondition(AuthorizedFor(capability))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertFalse(operation.didExecute)
        XCTAssertEqual(registrar.didRequestAuthorization!, LocationUsage.Always)
    }

    func test__condition_succeeds_when_status_meets_requirements() {
        capability.registrar.authorizationStatus = .AuthorizedWhenInUse

        let operation = TestOperation()
        operation.addCondition(AuthorizedFor(capability))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
        XCTAssertNil(registrar.didRequestAuthorization)
    }

    func test__condition_succeeds_when_status_exceeds_requirements() {
        capability.registrar.authorizationStatus = .AuthorizedAlways

        let operation = TestOperation()
        operation.addCondition(AuthorizedFor(capability))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
        XCTAssertNil(registrar.didRequestAuthorization)
    }

    func test__authorization_requested_when_status_not_determined() {

        let operation = TestOperation()
        operation.addCondition(AuthorizedFor(capability))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.didExecute)
        XCTAssertEqual(registrar.didRequestAuthorization!, LocationUsage.WhenInUse)
    }
}



