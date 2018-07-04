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

public protocol LocationFetcherDelegate: class {
    func locationFetcher(_ fetcher: LocationFetcher,
                         didUpdateLocations locations: [CLLocation])

    func locationFetcher(_ fetcher: LocationFetcher,
                         didFailWithError error: Error)

    func locationServices(_ locationServices: LocationServicesRegistrar,
                          didChangeAuthorization status: CLAuthorizationStatus)
}

public extension LocationFetcherDelegate {
    func locationFetcher(_ fetcher: LocationFetcher,
                         didUpdateLocations locations: [CLLocation]) { }

    func locationFetcher(_ fetcher: LocationFetcher,
                         didFailWithError error: Error) { }

    func locationServices(_ locationServices: LocationServicesRegistrar,
                         didChangeAuthorization status: CLAuthorizationStatus) { }
}

public protocol LocationServices {
    func startUpdatingLocation()
    func stopUpdatingLocation()

    var locationFetcherDelegate: LocationFetcherDelegate? { get set }

    var desiredAccuracy: CLLocationAccuracy { get set }
}

public protocol LocationServicesRegistrar {
    var locationFetcherDelegate: LocationFetcherDelegate? { get set }

    func authorizationStatus() -> CLAuthorizationStatus
    func locationServicesEnabled() -> Bool

    @available(iOS 8.0, *)
    func requestAuthorization(withRequirement: LocationUsage?)
}

public typealias LocationFetcher = LocationServices & LocationServicesRegistrar

public extension LocationServicesRegistrar where Self: CLLocationManager {
    @available(iOS 8.0, *)
    public func requestAuthorization(withRequirement requirement: LocationUsage?) {
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


extension CLLocationManager: LocationServicesRegistrar {
    public var locationFetcherDelegate: LocationFetcherDelegate? {
        get { return delegate as! LocationFetcherDelegate? }
        set { delegate = newValue as! CLLocationManagerDelegate? }
    }

    public func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    public func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
}

extension CLLocationManager: LocationServices { }

public protocol LocationAuthorizationDelegate: LocationFetcherDelegate { }
extension LocationAuthorizationDelegate {
    public func locationFetcher(_ fetcher: LocationFetcher, didFailWithError error: Error) { }
    public func locationFetcher(_ fetcher: LocationFetcher, didUpdateLocations locations: [CLLocation]) { }
}

internal class LocationManagerAuthorizationDelegate: NSObject, LocationAuthorizationDelegate, CLLocationManagerDelegate {
    let didChangeAuthorizationStatusBlock: (LocationServicesRegistrar, CLAuthorizationStatus) -> Void

    init(didChangeAuthorizationStatusBlock block: @escaping (LocationServicesRegistrar, CLAuthorizationStatus) -> Void) {
        didChangeAuthorizationStatusBlock = block
    }

    func locationServices(_ locationServices: LocationServicesRegistrar, didChangeAuthorization status: CLAuthorizationStatus) {
        didChangeAuthorizationStatusBlock(locationServices, status)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationServices(manager, didChangeAuthorization: status)
    }
}

public protocol ReverseGeocoder {

    func cancelGeocode()
    func reverseGeocodeLocation(_ location: CLLocation,
                                completionHandler: @escaping CLGeocodeCompletionHandler)
}

extension CLGeocoder: ReverseGeocoder { }
