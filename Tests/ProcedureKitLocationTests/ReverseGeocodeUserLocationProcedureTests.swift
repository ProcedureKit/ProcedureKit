//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitLocation

class ReverseGeocodeUserLocationProcedureTests: LocationProcedureTestCase {

    func test__geocoder_starts() {
        geocoder.placemarks = [placemark]
        let procedure = ReverseGeocodeUserLocationProcedure().set(manager: manager).set(geocoder: geocoder)
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertEqual(geocoder.didReverseGeocodeLocation, location)
    }

    func test__completion_block_receives_placemark_and_location() {
        geocoder.placemarks = [placemark]
        let exp = expectation(description: "Test: \(#function)")
        var didReceiveUserLocationPlacemark: UserLocationPlacemark? = nil
        let procedure = ReverseGeocodeUserLocationProcedure { result in
            didReceiveUserLocationPlacemark = result
            exp.fulfill()
        }.set(manager: manager).set(geocoder: geocoder)
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertNotNil(didReceiveUserLocationPlacemark)
        XCTAssertEqual(didReceiveUserLocationPlacemark, UserLocationPlacemark(location: location, placemark: placemark))
    }

    func test__user_location_returns_error_cancels_with_error() {
        manager.returnedError = TestError()
        let procedure = ReverseGeocodeUserLocationProcedure().set(manager: manager).set(geocoder: geocoder)
        wait(for: procedure)
        // There are actually 3 errors here, because the UserLocation fails with
        // an error, the procedures which depend on it then both cancel with errors
        XCTAssertProcedureFinishedWithErrors(procedure, count: 3)
    }

    func test__no_user_location_finishes_with_errors() {
        manager.returnedLocation = nil
        let procedure = ReverseGeocodeUserLocationProcedure(timeout: 1).set(manager: manager).set(geocoder: geocoder)
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(procedure, count: 1)
    }
}
