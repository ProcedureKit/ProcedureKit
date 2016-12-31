//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CoreLocation
import MapKit

public enum LocationUsage {
    case whenInUse
    case always
}

extension CLAuthorizationStatus: AuthorizationStatus {

    public func meets(requirement: LocationUsage?) -> Bool {
        switch (requirement, self) {
        case (.some(.whenInUse), .authorizedWhenInUse), (_, .authorizedAlways):
            return true
        default:
            return false
        }
    }
}

public extension Capability {

    class Location: CapabilityProtocol {

        public private(set) var requirement: LocationUsage?

        internal lazy var registrar: LocationServicesRegistrarProtocol = CLLocationManager.make()

        private var authorizationDelegate: LocationManagerAuthorizationDelegate? = nil

        public init(_ requirement: LocationUsage = .whenInUse) {
            self.requirement = requirement
        }

        deinit {
            registrar.pk_set(delegate: nil)
        }

        public func isAvailable() -> Bool {
            return registrar.pk_locationServicesEnabled()
        }

        public func getAuthorizationStatus(_ completion: @escaping (CLAuthorizationStatus) -> Void) {
            completion(registrar.pk_authorizationStatus())
        }

        public func requestAuthorization(withCompletion completion: @escaping () -> Void) {
            guard isAvailable() else {
                completion()
                return
            }

            let status = registrar.pk_authorizationStatus()
            switch (status, requirement) {
            case (.notDetermined, _), (.authorizedWhenInUse, .some(.always)):
                authorizationDelegate = LocationManagerAuthorizationDelegate { _, status in
                    guard status != .notDetermined else { return }
                    completion()
                }
                registrar.pk_set(delegate: authorizationDelegate)
                registrar.pk_requestAuthorization(withRequirement: requirement)
            default:
                completion()
            }
        }
    }
}
