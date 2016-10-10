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
        geocoder.placemarks = [createPlacemark(coordinate: location.coordinate)]
        let procedure = ReverseGeocodeUserLocationProcedure().set(manager: manager).set(geocoder: geocoder)
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertEqual(geocoder.didReverseGeocodeLocation, location)
    }

    func test__completion_blocK_receives_placemark_and_location() {
        geocoder.placemarks = [createPlacemark(coordinate: location.coordinate)]
        let exp = expectation(description: "Test: \(#function)")
        var didReceiveUserLocationPlacemark: UserLocationPlacemark? = nil
        let procedure = ReverseGeocodeUserLocationProcedure { result in
            didReceiveUserLocationPlacemark = result
            exp.fulfill()
        }.set(manager: manager).set(geocoder: geocoder)
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertNotNil(didReceiveUserLocationPlacemark)

    }
}
