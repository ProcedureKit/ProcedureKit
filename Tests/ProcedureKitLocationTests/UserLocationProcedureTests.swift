//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import CoreLocation
import MapKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitLocation

class UserLocationProcedureTests: LocationProcedureTestCase {

    func test__received_location_is_set() {
        let procedure = UserLocationProcedure(accuracy: accuracy, locationFetcher: locationFetcher)
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
        XCTAssertEqual(procedure.output.success, location)
        XCTAssertEqual(locationFetcher.didSetDesiredAccuracy, accuracy)
        XCTAssertTrue(locationFetcher.didSetDelegate)
        XCTAssertTrue(locationFetcher.didStartUpdatingLocation)
        XCTAssertTrue(locationFetcher.didStopUpdatingLocation)
    }

    func test__receives_location_in_completion_block() {
        var receivedLocation: CLLocation? = nil
        let procedure = UserLocationProcedure(accuracy: accuracy, locationFetcher: locationFetcher) { location in
            receivedLocation = location
        }
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
        XCTAssertEqual(receivedLocation, location)
        XCTAssertEqual(locationFetcher.didSetDesiredAccuracy, accuracy)
        XCTAssertTrue(locationFetcher.didSetDelegate)
        XCTAssertTrue(locationFetcher.didStartUpdatingLocation)
        XCTAssertTrue(locationFetcher.didStopUpdatingLocation)
    }

    func test__updates_stop_when_cancelled() {
        let procedure = UserLocationProcedure(accuracy: accuracy, locationFetcher: locationFetcher)
        check(procedure: procedure) { $0.cancel() }
        XCTAssertTrue(locationFetcher.didStopUpdatingLocation)
    }

    func test__updates_stop_when_deallocated() {
        var tmp: UserLocationProcedure! = UserLocationProcedure(accuracy: accuracy, locationFetcher: locationFetcher)
        XCTAssertNotNil(tmp)
        tmp = nil
        // because of the asynchronous nature of a Procedure, deinit could occur in
        // another thread that is still finishing up a block and releases the last reference
        // to `tmp` - therefore, wait for a short bit to allow for that case
        XCTAssertEqual(locationFetcher.waitForDidStopUpdatingLocation(withTimeout: 0.5), .success)
    }

    func test__finishes_if_accuracy_is_best() {
        let procedure = UserLocationProcedure(accuracy: kCLLocationAccuracyBestForNavigation, locationFetcher: locationFetcher)
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__finishes_with_error_if_location_manager_fails() {
        let error = TestError()
        locationFetcher.returnedError = error
        let procedure = UserLocationProcedure(accuracy: accuracy, locationFetcher: locationFetcher)
        wait(for: procedure)
        PKAssertProcedureFinishedWithError(procedure, error)
    }

    func test__cancels_with_timeout_if_location_manager_takes_too_long() {
        locationFetcher.returnAfterDelay = 0.2
        let procedure = UserLocationProcedure(timeout: 0.1, accuracy: accuracy, locationFetcher: locationFetcher)
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.timedOut(with: .by(0.1)))
    }
}


