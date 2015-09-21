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
@testable import Operations

class LocationOperationTests: OperationTests {

    let accuracy: CLLocationAccuracy = 10
    var locationManager: TestableLocationManager!
    var location: CLLocation!

    override func setUp() {
        super.setUp()
        location = createLocationWithAccuracy(accuracy)
        locationManager = TestableLocationManager(enabled: true, status: .AuthorizedAlways)
        locationManager.returnedLocation = location
    }

    override func tearDown() {
        locationManager = nil
        location = nil
        super.tearDown()
    }

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

        let operation = UserLocationOperation(accuracy: accuracy, manager: locationManager) { location in
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
        XCTAssertEqual(operation.location!, receivedLocation!)
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

    var placemark: CLPlacemark!
    var geocoder: TestableReverseGeocoder!

    override func setUp() {
        super.setUp()
        placemark = createPlacemark(location.coordinate)
        geocoder = TestableReverseGeocoder(placemark: placemark)
    }

    override func tearDown() {
        placemark = nil
        geocoder = nil
        super.tearDown()
    }

    func test__name_is_correct() {
        let reverseGeocode = ReverseGeocodeOperation(location: location, geocoder: geocoder)
        XCTAssertEqual(reverseGeocode.name, "Reverse Geocode")
    }

    func test__reverse_geocode_starts_geocoder() {
        let reverseGeocode = ReverseGeocodeOperation(location: location, geocoder: geocoder)
        addCompletionBlockToTestOperation(reverseGeocode, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(reverseGeocode)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(geocoder.didReverseLookup)
        XCTAssertEqual(reverseGeocode.location, location)
        XCTAssertEqual(reverseGeocode.placemark!, placemark)
    }

    func test__when_geocode_returns_error_operation_fails() {
        geocoder = TestableReverseGeocoder(placemark: .None, error: NSError(domain: kCLErrorDomain, code: CLError.GeocodeFoundNoResult.rawValue, userInfo: nil))
        let reverseGeocode = ReverseGeocodeOperation(location: location, geocoder: geocoder)

        var receivedErrors = [ErrorType]()
        reverseGeocode.addObserver(BlockObserver { (_, errors) in
            receivedErrors = errors
        })

        addCompletionBlockToTestOperation(reverseGeocode, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(reverseGeocode)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(geocoder.didReverseLookup)

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
        let reverseGeocode = ReverseGeocodeOperation(location: location, geocoder: geocoder)
        reverseGeocode.addObserver(BlockObserver(startHandler: { op in
            op.cancel()
        }))

        addCompletionBlockToTestOperation(reverseGeocode, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(reverseGeocode)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(geocoder.didCancel)
        XCTAssertTrue(reverseGeocode.cancelled)
    }

    func test__completion_handler_receives_placeholder() {
        var completionBlockDidExecute = false
        let reverseGeocode = ReverseGeocodeOperation(location: location, geocoder: geocoder) { placemark in
            completionBlockDidExecute = true
            XCTAssertEqual(self.placemark, placemark)
        }

        addCompletionBlockToTestOperation(reverseGeocode, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(reverseGeocode)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(completionBlockDidExecute)
    }
}

class ReverseGeocodeUserLocationOperationTests: ReverseGeocodeOperationTests {

    func test__reverse_geocode_user_location_starts_geocoder() {
        let reverseGeocodeUserLocation = ReverseGeocodeUserLocationOperation(accuracy: accuracy, manager: locationManager, geocoder: geocoder)
        addCompletionBlockToTestOperation(reverseGeocodeUserLocation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(reverseGeocodeUserLocation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(geocoder.didReverseLookup)
        XCTAssertTrue(reverseGeocodeUserLocation.finished)
        XCTAssertEqual(reverseGeocodeUserLocation.location!, location)
        XCTAssertEqual(reverseGeocodeUserLocation.placemark!, placemark)
    }

    func test__completion_handler_receives_location_and_placeholder() {
        var completionBlockDidExecute = false
        let reverseGeocodeUserLocation = ReverseGeocodeUserLocationOperation(accuracy: accuracy, manager: locationManager, geocoder: geocoder) { location, placemark in
            completionBlockDidExecute = true
            XCTAssertEqual(self.location, location)
            XCTAssertEqual(self.placemark, placemark)
        }

        addCompletionBlockToTestOperation(reverseGeocodeUserLocation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(reverseGeocodeUserLocation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(completionBlockDidExecute)
    }
}
