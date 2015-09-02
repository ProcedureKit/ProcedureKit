//
//  LocationOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import CoreLocation
import Operations

class LocationOperationTests: OperationTests {

    func createLocationWithAccuracy(accuracy: CLLocationAccuracy) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2DMake(0.0, 0.0),
            altitude: 100,
            horizontalAccuracy: accuracy,
            verticalAccuracy: accuracy,
            course: 0,
            speed: 0,
            timestamp: NSDate())
    }

    func test__location_operation_receives_location() {

        var receivedLocation: CLLocation? = .None
        let accuracy: CLLocationAccuracy = 10

        let locationManager = TestableLocationManager(enabled: true, status: .AuthorizedAlways)
        locationManager.returnedLocation = createLocationWithAccuracy(accuracy)

        let operation = UserLocationOperation(accuracy: accuracy, manager: locationManager) { (location) -> Void in
            receivedLocation = location
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertEqual(locationManager.didSetDesiredAccuracy!, accuracy)
        XCTAssertEqual(receivedLocation!.horizontalAccuracy, accuracy)
        XCTAssertTrue(locationManager.didSetDelegate)
        XCTAssertTrue(locationManager.didStartUpdatingLocation)
        XCTAssertTrue(locationManager.didStopLocationUpdates)
    }
}

