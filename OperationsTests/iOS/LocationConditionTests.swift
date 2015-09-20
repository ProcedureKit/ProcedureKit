//
//  LocationConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import XCTest
import CoreLocation
@testable import Operations

class TestableLocationManager: NSObject, LocationManager {
    let fakeLocationManager = CLLocationManager()

    var serviceEnabled: Bool
    var authorizationStatus: CLAuthorizationStatus
    var returnedStatus = CLAuthorizationStatus.AuthorizedAlways
    var returnedLocation: CLLocation!

    var didSetDelegate = false
    var didSetDesiredAccuracy: CLLocationAccuracy? = .None

    var didRequestWhenInUseAuthorization = false
    var didRequestAlwaysAuthorization = false
    var didStartUpdatingLocation = false
    var didStopLocationUpdates = false

    weak var delegate: CLLocationManagerDelegate!

    init(enabled: Bool, status: CLAuthorizationStatus) {
        serviceEnabled = enabled
        authorizationStatus = status
    }

    func opr_setDesiredAccuracy(accuracy: CLLocationAccuracy) {
        didSetDesiredAccuracy = accuracy
    }

    func opr_setDelegate(aDelegate: CLLocationManagerDelegate) {
        didSetDelegate = true
        delegate = aDelegate
    }

    func opr_requestWhenInUseAuthorization() {
        didRequestWhenInUseAuthorization = true
        changeStatus()
    }

    func opr_requestAlwaysAuthorization() {
        didRequestAlwaysAuthorization = true
        changeStatus()
    }

    func opr_startUpdatingLocation() {
        didStartUpdatingLocation = true
        delegate.locationManager!(fakeLocationManager, didUpdateLocations: [returnedLocation])
    }

    func opr_stopLocationUpdates() {
        didStopLocationUpdates = true
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

class LocationConditionTests: OperationTests {

    func test__service_enabled_with_always__then__permission_not_requested() {

        let locationManager = TestableLocationManager(enabled: true, status: .AuthorizedAlways)
        let operation = TestOperation()
        operation.addCondition(LocationCondition(usage: .Always, manager: locationManager))

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
        operation.addCondition(LocationCondition(usage: .WhenInUse, manager: locationManager))

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

        let locationManager = TestableLocationManager(enabled: false, status: .NotDetermined)

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
        let locationManager = TestableLocationManager(enabled: false, status: .NotDetermined)
        locationManager.returnedStatus = .AuthorizedWhenInUse

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

#endif
