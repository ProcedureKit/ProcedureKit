//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitLocation

class TestableLocationServicesRegistrar {
    let fake = CLLocationManager()

    var servicesEnabled = true
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    weak var delegate: CLLocationManagerDelegate? = nil
    var responseStatus: CLAuthorizationStatus = .authorizedAlways

    var didCheckServiceEnabled = false
    var didCheckAuthorizationStatus = false
    var didSetDelegate = false
    var didRequestAuthorization = false
    var didRequestAuthorizationForUsage: LocationUsage? = nil
}

extension TestableLocationServicesRegistrar: LocationServicesRegristrarProtocol {

    func pk_locationServicesEnabled() -> Bool {
        didCheckServiceEnabled = true
        return servicesEnabled
    }

    func pk_authorizationStatus() -> CLAuthorizationStatus {
        didCheckAuthorizationStatus = true
        return authorizationStatus
    }

    func pk_set(delegate aDelegate: CLLocationManagerDelegate?) {
        didSetDelegate = true
        delegate = aDelegate
    }

    func pk_requestAuthorization(withRequirement requirement: LocationUsage?) {
        didRequestAuthorization = true
        didRequestAuthorizationForUsage = requirement
        // In some cases CLLocationManager will immediately send a .NotDetermined
        delegate?.locationManager!(fake, didChangeAuthorization: .notDetermined)
        delegate?.locationManager!(fake, didChangeAuthorization: responseStatus)
    }
}
