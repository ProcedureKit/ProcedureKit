//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//


protocol LocationServicesRegristrarProtocol {

    func pk_locationServicesEnabled() -> Bool

    func pk_authorizationStatus() -> CLAuthorizationStatus

    func pk_set(delegate aDelegate: CLLocationManagerDelegate?)

    @available(iOS 8.0, *)
    func pk_requestAuthorization(withRequirement: LocationUsage?)
}

extension CLLocationManager: LocationServicesRegristrarProtocol {

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

internal extension CLLocationManager {

    static func make() -> CLLocationManager {
        return DispatchQueue.onMain { CLLocationManager() }
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
