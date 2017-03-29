//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import CoreLocation
import MapKit

public enum LocationUsage {
    case whenInUse
    case always
}

extension CLAuthorizationStatus: AuthorizationStatus {

    public func meets(requirement: LocationUsage?) -> Bool {
        if #available(OSX 10.12, iOS 8.0, tvOS 8.0, watchOS 2.0, *) {
            switch (requirement, self) {
            case (.some(.whenInUse), .authorizedWhenInUse), (_, .authorizedAlways): return true
            default: return false
            }
        }
        else {
            #if os(OSX)
                switch (requirement, self) {
                case (_, .authorized): return true
                default: return false
                }
            #else
                return false
            #endif
        }
    }
}

public extension Capability {

    class Location: CapabilityProtocol {

        public private(set) var requirement: LocationUsage?

        internal lazy var registrar: LocationServicesRegistrarProtocol = CLLocationManager.make()

        // Note, that this property is the authorization delegate, however, it is not
        // owned by anything else, so should not be weak referenced.
        private var authorizationDelegate: LocationManagerAuthorizationDelegate? // swiftlint:disable:this weak_delegate

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
