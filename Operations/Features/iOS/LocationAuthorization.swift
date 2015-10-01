//
//  LocationAuthorization.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation
import CoreLocation

public enum LocationUsage: Int { case WhenInUse = 1, Always }

public protocol LocationCapabilityRegistrarType: CapabilityRegistrarType {
    func opr_locationServicesEnabled() -> Bool
    func opr_authorizationStatus() -> CLAuthorizationStatus
    func opr_setDelegate(aDelegate: CLLocationManagerDelegate)
    func opr_requestAuthorizationWithRequirement(requirement: LocationUsage)
}

extension CLLocationManager: LocationCapabilityRegistrarType {

    public func opr_locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    public func opr_authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    public func opr_setDelegate(aDelegate: CLLocationManagerDelegate) {
        self.delegate = aDelegate
    }

    public func opr_requestAuthorizationWithRequirement(requirement: LocationUsage) {
        switch requirement {
        case .WhenInUse:
            requestWhenInUseAuthorization()
        case .Always:
            requestAlwaysAuthorization()
        }
    }
}

extension CLAuthorizationStatus: AuthorizationStatusType {
    public typealias Requirement = LocationUsage

    public func isRequirementMet(requirement: LocationUsage) -> Bool {
        switch (requirement, self) {
        case (.WhenInUse, .AuthorizedWhenInUse), (_, .AuthorizedAlways):
            return true
        default:
            return false
        }
    }
}

public class _LocationCapability<Registrar: LocationCapabilityRegistrarType>: NSObject, CLLocationManagerDelegate, CapabilityType {

    public let name: String
    public let requirement: LocationUsage

    let registrar: Registrar
    var authorizationCompletionBlock: dispatch_block_t?

    public required init(_ requirement: LocationUsage = .WhenInUse, registrar: Registrar = Registrar()) {
        self.name = "Location"
        self.requirement = requirement
        self.registrar = registrar
    }

    public func isAvailable() -> Bool {
        return registrar.opr_locationServicesEnabled()
    }

    public func authorizationStatus() -> CLAuthorizationStatus {
        return registrar.opr_authorizationStatus()
    }

    public func requestAuthorizationWithCompletion(completion: dispatch_block_t) {
        if !registrar.opr_locationServicesEnabled() {
                completion()
        }
        else {
            let status = registrar.opr_authorizationStatus()
            switch (status, requirement) {
            case (.NotDetermined, _), (.AuthorizedWhenInUse, .Always):
                authorizationCompletionBlock = completion
                registrar.opr_setDelegate(self)
                registrar.opr_requestAuthorizationWithRequirement(requirement)
            default:
                completion()
            }
        }
    }

    @objc public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        authorizationCompletionBlock?()
    }
}

public typealias Location = _LocationCapability<CLLocationManager>
