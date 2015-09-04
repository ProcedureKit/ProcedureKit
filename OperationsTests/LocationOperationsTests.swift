//
//  LocationOperationsTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import CoreLocation
import MapKit
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

    func createPlacemark(coordinate: CLLocationCoordinate2D) -> CLPlacemark {
        return MKPlacemark(coordinate: coordinate, addressDictionary: ["City": "London"])
    }
}

class UserLocationOperationTests: LocationOperationTests {

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


class TestableReverseGeocoder: ReverseGeocoderType {

    var didCancel = false
    var didReverseLookup = false

    var placemark: CLPlacemark?
    var error: NSError?

    init(placemark: CLPlacemark?, error: NSError? = .None) {
        self.placemark = placemark
        self.error = error
    }

    func opr_cancel() {
        didCancel = true
    }

    func opr_reverseGeocodeLocation(location: CLLocation, completion: ([CLPlacemark], NSError?) -> Void) {
        didReverseLookup = true
        completion(placemark.map { [$0] } ?? [], error)
    }
}

class ReverseGeocodeOperationTests: LocationOperationTests {

    var location: CLLocation!
    var placemark: CLPlacemark!
    var geocoder: TestableReverseGeocoder!
    var operation: ReverseGeocodeOperation!

    override func setUp() {
        super.setUp()
        location = createLocationWithAccuracy(100.0)
        placemark = createPlacemark(location.coordinate)
        geocoder = TestableReverseGeocoder(placemark: placemark)
        operation = ReverseGeocodeOperation(location: location, geocoder: geocoder)
    }

    func test__name_is_correct() {
        XCTAssertEqual(operation.name!, "Reverse Geocode")
    }

    func test__reverse_geocode_starts_geocoder() {

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(geocoder.didReverseLookup)
        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.location, location)
        XCTAssertEqual(operation.placemark!, placemark)
    }

    func test__when_geocode_returns_error_operation_fails() {
        geocoder.error = NSError(domain: kCLErrorDomain, code: CLError.GeocodeFoundNoResult.rawValue, userInfo: nil)

        var receivedErrors = [ErrorType]()
        operation.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(geocoder.didReverseLookup)
        XCTAssertTrue(operation.finished)

        if let error = receivedErrors.first as? ReverseGeocodeOperation.Error {
            switch error {
            case .GeocoderError(let underlyingError):
                XCTAssertEqual(underlyingError.code, CLError.GeocodeFoundNoResult.rawValue)
            }
        }
        else {
            XCTFail("Correct error not received.")
        }
    }

    func test__reverse_geocode_cancels_when_operation_cancels() {

        operation.addObserver(BlockObserver(startHandler: { op in
            op.cancel()
        }))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(geocoder.didCancel)
        XCTAssertTrue(operation.cancelled)
    }
}


