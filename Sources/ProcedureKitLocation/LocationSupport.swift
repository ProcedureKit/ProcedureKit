//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import Dispatch
import CoreLocation
import MapKit

struct ProcedureKitLocationComponent: ProcedureKitComponent {
    let name = "ProcedureKitLocation"
}

internal extension CLLocationManager {

    static func make() -> CLLocationManager {
        return DispatchQueue.onMain { CLLocationManager() }
    }
}

internal extension CLGeocoder {

    static func make() -> CLGeocoder {
        return DispatchQueue.onMain { CLGeocoder() }
    }
}

protocol LocationServicesRegistrarProtocol {

    func pk_locationServicesEnabled() -> Bool

    func pk_authorizationStatus() -> CLAuthorizationStatus

    func pk_set(delegate aDelegate: CLLocationManagerDelegate?)

    @available(iOS 8.0, *)
    func pk_requestAuthorization(withRequirement: LocationUsage?)
}

extension CLLocationManager: LocationServicesRegistrarProtocol {

    func pk_locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    func pk_authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    func pk_set(delegate aDelegate: CLLocationManagerDelegate?) {
        self.delegate = aDelegate
    }

    @available(iOS 8.0, *)
    func pk_requestAuthorization(withRequirement requirement: LocationUsage?) {
        #if os(iOS) || os(watchOS)
            switch requirement {
            case .some(.always):
                requestAlwaysAuthorization()
            case _:
                requestWhenInUseAuthorization()
            }
        #endif

        #if os(tvOS)
            requestWhenInUseAuthorization()
        #endif
    }
}

protocol LocationServicesProtocol {

    func pk_set(desiredAccuracy: CLLocationAccuracy)

    func pk_startUpdatingLocation()

    func pk_stopUpdatingLocation()
}

extension CLLocationManager: LocationServicesProtocol {

    func pk_set(desiredAccuracy accuracy: CLLocationAccuracy) {
        desiredAccuracy = accuracy
    }

    func pk_startUpdatingLocation() {
        #if os(iOS) || os(watchOS)
            startUpdatingLocation()
        #endif

        #if os(tvOS)
            requestLocation()
        #endif
    }

    func pk_stopUpdatingLocation() {
        stopUpdatingLocation()
    }
}

internal class LocationManagerAuthorizationDelegate: NSObject, CLLocationManagerDelegate {

    let didChangeAuthorizationStatusBlock: (CLLocationManager, CLAuthorizationStatus) -> Void

    init(didChangeAuthorizationStatusBlock block: @escaping (CLLocationManager, CLAuthorizationStatus) -> Void) {
        didChangeAuthorizationStatusBlock = block
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        didChangeAuthorizationStatusBlock(manager, status)
    }
}

protocol GeocodeProtocol {

    func pk_cancel()
}

extension CLGeocoder: GeocodeProtocol {

    func pk_cancel() {
        cancelGeocode()
    }
}

protocol ReverseGeocodeProtocol {

    func pk_reverseGeocodeLocation(location: CLLocation, completionHandler completion: @escaping CLGeocodeCompletionHandler)
}

extension CLGeocoder: ReverseGeocodeProtocol {

    func pk_reverseGeocodeLocation(location: CLLocation, completionHandler completion: @escaping CLGeocodeCompletionHandler) {
        reverseGeocodeLocation(location, completionHandler: completion)
    }
}
