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

class TestableLocationManager: TestableLocationRegistrar {

    var desiredAccuracy: CLLocationAccuracy? = .none

    var returnedLocation: CLLocation? = .none
    var returnedError: NSError? = .none

    var didStartUpdatingLocation = false
    var didStopLocationUpdates = false
}

extension TestableLocationManager: LocationManagerType {

    func opr_setDesiredAccuracy(_ desiredAccuracy: CLLocationAccuracy) {
        self.desiredAccuracy = desiredAccuracy
    }

    func opr_startUpdatingLocation() {
        didStartUpdatingLocation = true
        if let error = returnedError {
            delegate.locationManager!(fakeLocationManager, didFailWithError: error)
        }
        else {
            delegate.locationManager!(fakeLocationManager, didUpdateLocations: [returnedLocation!])
        }
    }

    func opr_stopLocationUpdates() {
        didStopLocationUpdates = true
    }
}


class LocationOperationTests: OperationTests {

    let accuracy: CLLocationAccuracy = 10
    var locationManager: TestableLocationManager!
    var location: CLLocation!

    override func setUp() {
        super.setUp()
        location = createLocationWithAccuracy(accuracy)
        locationManager = TestableLocationManager()
        locationManager.authorizationStatus = .authorizedAlways
        locationManager.returnedLocation = location
    }

    override func tearDown() {
        locationManager = nil
        location = nil
        super.tearDown()
    }

    func createLocationWithAccuracy(_ accuracy: CLLocationAccuracy) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2DMake(0.0, 0.0),
            altitude: 100,
            horizontalAccuracy: accuracy,
            verticalAccuracy: accuracy,
            course: 0,
            speed: 0,
            timestamp: Date())
    }

    func createPlacemark(_ coordinate: CLLocationCoordinate2D) -> CLPlacemark {
        return MKPlacemark(coordinate: coordinate, addressDictionary: ["City": "London"])
    }
}

class LocationOperationErrorTests: XCTestCase {

    var errorA: LocationOperationError!
    var errorB: LocationOperationError!

    func test__location_operation_error__both_location_manager_did_fail_error() {
        let underlyingError = NSError(domain: kCLErrorDomain, code: CLError.locationUnknown.rawValue, userInfo: nil)
        errorA = .locationManagerDidFail(underlyingError)
        errorB = .locationManagerDidFail(underlyingError)
        XCTAssertEqual(errorA, errorB)
    }

    func test__location_operation_error__both_location_manager_did_fail_different_errors() {
        errorA = .locationManagerDidFail(NSError(domain: kCLErrorDomain, code: CLError.locationUnknown.rawValue, userInfo: nil))
        errorB = .locationManagerDidFail(NSError(domain: kCLErrorDomain, code: CLError.network.rawValue, userInfo: nil))
        XCTAssertNotEqual(errorA, errorB)
    }

    func test__location_operation_error__both_geocoder_did_fail_error() {
        let underlyingError = NSError(domain: kCLErrorDomain, code: CLError.geocodeFoundPartialResult.rawValue, userInfo: nil)
        errorA = .geocoderError(underlyingError)
        errorB = .geocoderError(underlyingError)
        XCTAssertEqual(errorA, errorB)
    }

    func test__location_operation_error__both_geocoder_did_fail_different_errors() {
        errorA = .geocoderError(NSError(domain: kCLErrorDomain, code: CLError.geocodeFoundPartialResult.rawValue, userInfo: nil))
        errorB = .geocoderError(NSError(domain: kCLErrorDomain, code: CLError.geocodeFoundNoResult.rawValue, userInfo: nil))
        XCTAssertNotEqual(errorA, errorB)
    }

    func test__location_operation_error_different_not_equal() {
        let underlyingError = NSError(domain: kCLErrorDomain, code: CLError.locationUnknown.rawValue, userInfo: nil)
        errorA = .locationManagerDidFail(underlyingError)
        errorB = .geocoderError(underlyingError)
        XCTAssertNotEqual(errorA, errorB)
    }
}

class UserLocationOperationTests: LocationOperationTests {

    func test__operation_name() {
        let operation = _UserLocationOperation(manager: locationManager, accuracy: accuracy, completion: { _ in })
        XCTAssertEqual(operation.name!, "User Location")
    }

    func test__location_operation_received_location_is_set() {

        let operation = _UserLocationOperation(manager: locationManager, accuracy: accuracy, completion: { _ in })

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        guard let receivedLocation = operation.result else {
            XCTFail("Location not set")
            return
        }

        XCTAssertEqual(locationManager.desiredAccuracy!, accuracy)
        XCTAssertEqual(receivedLocation.horizontalAccuracy, accuracy)
        XCTAssertTrue(locationManager.didSetDelegate)
        XCTAssertTrue(locationManager.didStartUpdatingLocation)
        XCTAssertTrue(locationManager.didStopLocationUpdates)
        XCTAssertEqual(location, receivedLocation)
    }

    func test__location_operation_receives_location_in_block() {

        var receivedLocation: CLLocation? = .none

        let operation = _UserLocationOperation(manager: locationManager, accuracy: accuracy) { location in
            receivedLocation = location
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertEqual(locationManager.desiredAccuracy, accuracy)
        XCTAssertEqual(receivedLocation?.horizontalAccuracy, accuracy)
        XCTAssertTrue(locationManager.didSetDelegate)
        XCTAssertTrue(locationManager.didStartUpdatingLocation)
        XCTAssertTrue(locationManager.didStopLocationUpdates)
        XCTAssertEqual(location, receivedLocation)
    }

    func test__location_updates_stopped_when_operation_is_cancelled() {
        let operation = _UserLocationOperation(manager: locationManager, accuracy: accuracy, completion: { _ in })
        operation.stopLocationUpdates()
        XCTAssertTrue(locationManager.didStopLocationUpdates)
    }

    func test__given_location_manager_fails_operation_fails() {
        locationManager.returnedError = NSError(domain: kCLErrorDomain, code: CLError.locationUnknown.rawValue, userInfo: nil)

        let operation = _UserLocationOperation(manager: locationManager, accuracy: accuracy, completion: { _ in })

        var receivedErrors = [ErrorProtocol]()
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        guard let error = receivedErrors.first as? LocationOperationError else {
            XCTFail("Received error was not correct")
            return
        }

        switch error {
        case .locationManagerDidFail(let underlyingError):
            XCTAssertEqual(underlyingError.code, CLError.locationUnknown.rawValue)
        default:
            XCTFail("Received incorrect LocationOperationError: \(error)")
        }
    }
}

class TestableReverseGeocoder: ReverseGeocoderType {

    var didCancel = false
    var didReverseLookup = false

    var placemark: CLPlacemark? = .none
    var error: NSError? = .none

    required init() { }

    func opr_cancel() {
        didCancel = true
    }

    func opr_reverseGeocodeLocation(_ location: CLLocation, completion: ([CLPlacemark], NSError?) -> Void) {
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
        geocoder = TestableReverseGeocoder()
        geocoder.placemark = placemark
    }

    override func tearDown() {
        placemark = nil
        geocoder = nil
        super.tearDown()
    }

    func test__name_is_correct() {
        let operation = _ReverseGeocodeOperation(geocoder: geocoder, location: location, completion: { _ in })
        XCTAssertEqual(operation.name, "Reverse Geocode")
    }

    func test__reverse_geocode_starts_geocoder() {
        let operation = _ReverseGeocodeOperation(geocoder: geocoder, location: location, completion: { _ in })

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(geocoder.didReverseLookup)
        XCTAssertEqual(operation.location, location)
    }

    func test__when_geocode_returns_error_operation_fails() {
        geocoder.placemark = .none
        geocoder.error = NSError(domain: kCLErrorDomain, code: CLError.geocodeFoundNoResult.rawValue, userInfo: nil)

        let operation = _ReverseGeocodeOperation(geocoder: geocoder, location: location, completion: { _ in })

        var receivedErrors = [ErrorProtocol]()
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        guard let error = receivedErrors.first as? LocationOperationError else {
            XCTFail("Received error was not correct")
            return
        }

        XCTAssertTrue(geocoder.didReverseLookup)

        switch error {
        case .geocoderError(let underlyingError):
            XCTAssertEqual(underlyingError.code, CLError.geocodeFoundNoResult.rawValue)
        default:
            XCTFail("Received incorrect LocationOperationError: \(error)")
        }
    }

    func test__reverse_geocode_cancels_when_operation_cancels() {

        let operation = _ReverseGeocodeOperation(geocoder: geocoder, location: location, completion: { _ in })

        operation.addObserver(WillExecuteObserver { op in
            op.cancel()
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(geocoder.didCancel)
        XCTAssertTrue(operation.isCancelled)
    }

    func test__completion_handler_receives_placeholder() {
        var completionBlockDidExecute = false
        let operation = _ReverseGeocodeOperation(geocoder: geocoder, location: location) { placemark in
            completionBlockDidExecute = true
            XCTAssertEqual(self.placemark, placemark)
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(completionBlockDidExecute)

        guard let receivedPlacemark = operation.result else {
            XCTFail("received placemark not given.")
            return
        }

        XCTAssertEqual(receivedPlacemark, placemark)
    }
}

class ReverseGeocodeUserLocationOperationTests: ReverseGeocodeOperationTests {

    func test__reverse_geocode_user_location_starts_geocoder() {

        let operation = _ReverseGeocodeUserLocationOperation(geocoder: geocoder, manager: locationManager, accuracy: accuracy, completion: { _, _ in })

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        guard let receivedPlacemark = operation.result, receivedLocation = operation.location else {
            XCTFail("Operation did not set state")
            return
        }

        XCTAssertTrue(geocoder.didReverseLookup)
        XCTAssertEqual(receivedLocation, location)
        XCTAssertEqual(receivedPlacemark, placemark)
    }

    func test__completion_handler_receives_location_and_placeholder() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")

        var blockLocation: CLLocation? = .none
        var blockPlacemark: CLPlacemark? = .none

        let operation = _ReverseGeocodeUserLocationOperation(geocoder: geocoder, manager: locationManager, accuracy: accuracy) { location, placemark in
            blockLocation = location
            blockPlacemark = placemark
        }

        addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        guard let receivedLocation = blockLocation, receivedPlacemark = blockPlacemark else {
            XCTFail("Completion block not executed.")
            return
        }

        XCTAssertEqual(receivedLocation, location)
        XCTAssertEqual(receivedPlacemark, placemark)
    }
}
