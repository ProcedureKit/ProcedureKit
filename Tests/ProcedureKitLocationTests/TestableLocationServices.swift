//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import MapKit
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitLocation

func createLocation(withAccuracy accuracy: CLLocationAccuracy = 10) -> CLLocation {
    return CLLocation(
        coordinate: CLLocationCoordinate2DMake(0.0, 0.0),
        altitude: 100,
        horizontalAccuracy: accuracy,
        verticalAccuracy: accuracy,
        course: 0,
        speed: 0,
        timestamp: Date()
    )
}

func createPlacemark(coordinate: CLLocationCoordinate2D) -> CLPlacemark {
    return MKPlacemark(coordinate: coordinate, addressDictionary: ["City": "London"])
}

class TestableLocationServicesRegistrar {
    weak var delegate: LocationFetcherDelegate? = nil
    var servicesEnabled = true
    var authStatus: CLAuthorizationStatus = .notDetermined
    var responseStatus: CLAuthorizationStatus = {
        if #available(OSX 10.12, iOS 8.0, tvOS 8.0, watchOS 2.0, *) {
            return CLAuthorizationStatus.authorizedAlways
        }
        else {
            #if os(OSX)
                return CLAuthorizationStatus.authorized
            #else
                return CLAuthorizationStatus.authorizedAlways
            #endif
        }
    }()

    var didCheckServiceEnabled = false
    var didCheckAuthorizationStatus = false
    var didSetDelegate = false
    var didRequestAuthorization = false
    var didRequestAuthorizationForUsage: LocationUsage? = nil
}

extension TestableLocationServicesRegistrar: LocationServicesRegistrar {

    func locationServicesEnabled() -> Bool {
        didCheckServiceEnabled = true
        return servicesEnabled
    }

    func authorizationStatus() -> CLAuthorizationStatus {
        didCheckAuthorizationStatus = true
        return authStatus
    }

    var locationFetcherDelegate: LocationFetcherDelegate? {
        get { return delegate }
        set {
            didSetDelegate = true
            delegate = newValue
        }
    }

    func requestAuthorization(withRequirement requirement: LocationUsage?) {
        didRequestAuthorization = true
        didRequestAuthorizationForUsage = requirement

        // In some cases CLLocationManager will immediately send a .NotDetermined
        delegate?.locationServices(self, didChangeAuthorization: .notDetermined)
        delegate?.locationServices(self, didChangeAuthorization: responseStatus)
    }

    func requestWhenInUseAuthorization() {
        requestAuthorization(withRequirement: .whenInUse)
    }

    func requestAlwaysAuthorization() {
        requestAuthorization(withRequirement: .always)
    }
}

class TestableLocationManager: TestableLocationServicesRegistrar {

    var returnedLocation: CLLocation? = nil
    var returnedError: Error? = nil
    var returnAfterDelay: TimeInterval = 0.001

    var didSetDesiredAccuracy: CLLocationAccuracy? = nil
    var didStartUpdatingLocation = false
    var didStopUpdatingLocation = false

    fileprivate let updatingLocationGroup = DispatchGroup()
    fileprivate let stateLock = PThreadMutex()
    fileprivate var _didStartUpdatingLocationCount = 0

    enum TimeoutResult {
        case success
        case timedOut

        init(dispatchTimeoutResult: DispatchTimeoutResult) {
            switch dispatchTimeoutResult{
            case .success: self = .success
            case .timedOut: self = .timedOut
            }
        }
    }
    func waitForDidStopUpdatingLocation(withTimeout timeout: TimeInterval) -> TimeoutResult {
        let result = updatingLocationGroup.wait(timeout: .now() + timeout)
        return TimeoutResult(dispatchTimeoutResult: result)
    }
}

extension TestableLocationManager: LocationServices {

    var desiredAccuracy: CLLocationAccuracy {
        set { didSetDesiredAccuracy = newValue }
        get { return didSetDesiredAccuracy! }
    }

    func startUpdatingLocation() {
        stateLock.withCriticalScope {
            _didStartUpdatingLocationCount += 1
            updatingLocationGroup.enter()
        }
        didStartUpdatingLocation = true
        if let error = returnedError {
            delegate?.locationFetcher(self, didFailWithError: error)
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + returnAfterDelay) {
                self.delegate?.locationFetcher(self, didUpdateLocations: self.returnedLocation.flatMap { [$0] } ?? [])
            }
        }
    }

    func stopUpdatingLocation() {
        stateLock.withCriticalScope {
            guard _didStartUpdatingLocationCount > 0 else { return }
            _didStartUpdatingLocationCount -= 1
            updatingLocationGroup.leave()
        }
        didStopUpdatingLocation = true
    }
}

class TestableReverseGeocoder: ReverseGeocoder {

    var didCancel = false

    func cancelGeocode() {
        didCancel = true
    }

    var didReverseGeocodeLocation: CLLocation? = nil

    var placemarks: [CLPlacemark]? = nil
    var error: Error? = nil

    func reverseGeocodeLocation(_ location: CLLocation, completionHandler: @escaping CLGeocodeCompletionHandler) {
        didReverseGeocodeLocation = location
        // To replicate CLGeocoder, the completion block must be called on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                fatalError("TestableReverseGeocoder disappeared before completion was called")
            }
            completionHandler(strongSelf.placemarks, strongSelf.error)
        }
    }
}

class LocationProcedureTestCase: ProcedureKitTestCase {

    var location: CLLocation!
    var placemark: CLPlacemark!    
    let accuracy: CLLocationAccuracy = 10
    var locationFetcher: TestableLocationManager!
    var geocoder: TestableReverseGeocoder!

    override func setUp() {
        super.setUp()
        location = createLocation(withAccuracy: accuracy)
        placemark = createPlacemark(coordinate: location.coordinate)
        locationFetcher = TestableLocationManager()
        locationFetcher.authStatus = {
            if #available(OSX 10.12, iOS 8.0, tvOS 8.0, watchOS 2.0, *) {
                return CLAuthorizationStatus.authorizedAlways
            }
            else {
                #if os(OSX)
                    return CLAuthorizationStatus.authorized
                #else
                    return CLAuthorizationStatus.authorizedAlways
                #endif
            }
        }()
        locationFetcher.returnedLocation = location
        geocoder = TestableReverseGeocoder()
    }

    override func tearDown() {
        location = nil
        locationFetcher = nil
        geocoder = nil
        super.tearDown()
    }
}


