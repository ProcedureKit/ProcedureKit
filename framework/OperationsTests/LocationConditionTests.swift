//
//  LocationConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import CoreLocation
import Operations

class TestableLocationManager: NSObject, LocationManager {
    let fakeLocationManager = CLLocationManager()

    var serviceEnabled: Bool
    var authorizationStatus: CLAuthorizationStatus
    var returnedStatus = CLAuthorizationStatus.AuthorizedAlways
    var didRequestWhenInUseAuthorization = false
    var didRequestAlwaysAuthorization = false

    weak var delegate: CLLocationManagerDelegate!

    init(enabled: Bool, status: CLAuthorizationStatus) {
        serviceEnabled = enabled
        authorizationStatus = status
    }

    func requestWhenInUseAuthorization() {
        didRequestWhenInUseAuthorization = true
        changeStatus()
    }

    func requestAlwaysAuthorization() {
        didRequestAlwaysAuthorization = true
        changeStatus()
    }

    private func changeStatus() {
        authorizationStatus = returnedStatus
        switch authorizationStatus {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            serviceEnabled = true
        default:
            serviceEnabled = false
        }
        delegate.locationManager!(fakeLocationManager, didChangeAuthorizationStatus: returnedStatus)
    }
}

class TestableLocationManagerDelegate: NSObject, CLLocationManagerDelegate {

    var didReceiveChangedStatus = CLAuthorizationStatus.NotDetermined

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        didReceiveChangedStatus = status
    }
}

class LocationConditionTests: OperationTests {

    func test__service_enabled_with_always__then__permission_not_requested() {

        let locationManager = TestableLocationManager(enabled: true, status: .AuthorizedAlways)
        let operation = TestOperation()
        operation.addCondition(LocationCondition(manager: locationManager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(locationManager.didRequestAlwaysAuthorization)
        XCTAssertFalse(locationManager.didRequestWhenInUseAuthorization)

    }

    func test__service_enabled_with_when_in_use__then__permission_not_requested() {

        let locationManager = TestableLocationManager(enabled: true, status: .AuthorizedWhenInUse)
        let operation = TestOperation()
        operation.addCondition(LocationCondition(manager: locationManager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(locationManager.didRequestAlwaysAuthorization)
        XCTAssertFalse(locationManager.didRequestWhenInUseAuthorization)
    }

    func test__service_enabled_with_in_user_but_always_required_then__always_permissions_requested() {

        let locationManager = TestableLocationManager(enabled: true, status: .AuthorizedWhenInUse)
        let operation = TestOperation()
        operation.addCondition(LocationCondition(usage: .Always, manager: locationManager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(locationManager.didRequestAlwaysAuthorization)
        XCTAssertFalse(locationManager.didRequestWhenInUseAuthorization)
    }


    func test__service_disabled__then__always_permissions_requested() {

        let locationManagerDelegate = TestableLocationManagerDelegate()
        let locationManager = TestableLocationManager(enabled: false, status: .NotDetermined)
        locationManager.delegate = locationManagerDelegate

        let operation = TestOperation()
        operation.addCondition(LocationCondition(usage: .Always, manager: locationManager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertTrue(locationManager.didRequestAlwaysAuthorization)
        XCTAssertFalse(locationManager.didRequestWhenInUseAuthorization)
    }

    func test__service_disabled_when_is_use_required_then__when_in_use_permissions_requested() {

        let locationManagerDelegate = TestableLocationManagerDelegate()
        let locationManager = TestableLocationManager(enabled: false, status: .NotDetermined)
        locationManager.returnedStatus = .AuthorizedWhenInUse
        locationManager.delegate = locationManagerDelegate

        let operation = TestOperation()
        operation.addCondition(LocationCondition(usage: .WhenInUse, manager: locationManager))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.finished)
        XCTAssertFalse(locationManager.didRequestAlwaysAuthorization)
        XCTAssertTrue(locationManager.didRequestWhenInUseAuthorization)
    }


}
