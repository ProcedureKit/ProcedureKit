//
//  LocationCapability.swift
//  Operations
//
//  Created by Daniel Thorpe on 01/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import CoreLocation

/**
 An enum for LocationUsage

 There are two methods which request authorization for
 CLLocationManager.
*/
public enum LocationUsage: Int {

    /// Request access only when the app is in use
    case whenInUse = 1

    /// Request access always
    case always
}

/**
 A refined CapabilityRegistrarType for Capability.Location. This
 protocol defines functions which the registrar uses to get
 the current authorization status and request access.
 */
public protocol LocationCapabilityRegistrarType: CapabilityRegistrarType {

    /// - returns: a true Bool if the location services is enabled
    func opr_locationServicesEnabled() -> Bool

    /**
     Sets the location manager delegate.

     - parameter aDelegate: a CLLocationManagerDelegate
     */
    func opr_setDelegate(_ aDelegate: CLLocationManagerDelegate?)

    /// - returns: the CLAuthorizationStatus
    func opr_authorizationStatus() -> CLAuthorizationStatus

    /**
     Request access for the given LocationUsage (i.e. the requirement).

     - parameter requirement: the LocationUsage
     */
    func opr_requestAuthorizationWithRequirement(_ requirement: LocationUsage)
}

extension CLLocationManager: LocationCapabilityRegistrarType {

    /// - returns: a true Bool if the location services is enabled
    public func opr_locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    /// - returns: the CLAuthorizationStatus
    public func opr_authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    /**
     Sets the location manager delegate.

     - parameter aDelegate: a CLLocationManagerDelegate
     */
    public func opr_setDelegate(_ aDelegate: CLLocationManagerDelegate?) {
        self.delegate = aDelegate
    }

    /**
     Request access for the given LocationUsage (i.e. the requirement).

     - parameter requirement: the LocationUsage
     */
    public func opr_requestAuthorizationWithRequirement(_ requirement: LocationUsage) {
        switch requirement {
        case .whenInUse:
            requestWhenInUseAuthorization()
        case .always:
            requestAlwaysAuthorization()
        }
    }
}

extension CLAuthorizationStatus: AuthorizationStatusType {

    /**
     Determine whether access has been granted given the LocationUsage.

     - parameter requirement: the required LocationUsage
     - returns: a true Bool for authorized status
     */
    public func isRequirementMet(_ requirement: LocationUsage) -> Bool {
        switch (requirement, self) {
        case (.whenInUse, .authorizedWhenInUse), (_, .authorizedAlways):
            return true
        default:
            return false
        }
    }
}

/**
 The Location capability, which is generic over an LocationCapabilityRegistrarType.

 Framework consumers should not use this directly, but instead
 use Capability.Location. So that its usage is like this:

 ```swift

 GetAuthorizationStatus(Capability.Location(.WhenInUse)) { status in
    // check the status etc.
 }
 ```

 - see: Capability.Location
 */
public class LocationCapability: NSObject, CLLocationManagerDelegate, CapabilityType {

    /// - returns: a String, the name of the capability
    public let name: String

    /// - returns: the EKEntityType, the required type of the capability
    public let requirement: LocationUsage

    var registrar: LocationCapabilityRegistrarType = CLLocationManager()
    var authorizationCompletionBlock: (() -> Void)?

    /**
     Initialize the capability. By default, it requires access .WhenInUse.

     - parameter requirement: the required LocationUsage, defaults to .WhenInUse
     - parameter registrar: the registrar to use. Defauls to creating a Registrar.
     */
    public required init(_ requirement: LocationUsage = .whenInUse) {
        self.name = "Location"
        self.requirement = requirement
        super.init()
    }

    /// - returns: true if location services are enabled
    public func isAvailable() -> Bool {
        return registrar.opr_locationServicesEnabled()
    }

    /**
     Get the current authorization status of Location services from the Registrar.
     - parameter completion: a CLAuthorizationStatus -> Void closure.
     */
    public func authorizationStatus(_ completion: (CLAuthorizationStatus) -> Void) {
        completion(registrar.opr_authorizationStatus())
    }

    /**
     Request authorization to Location services from the Registrar.
     - parameter completion: a dispatch_block_t
     */
    public func requestAuthorizationWithCompletion(_ completion: () -> Void) {
        if !registrar.opr_locationServicesEnabled() {
            completion()
        }
        else {
            let status = registrar.opr_authorizationStatus()
            switch (status, requirement) {
            case (.notDetermined, _), (.authorizedWhenInUse, .always):
                authorizationCompletionBlock = completion
                registrar.opr_setDelegate(self)
                registrar.opr_requestAuthorizationWithRequirement(requirement)
            default:
                completion()
            }
        }
    }

    /**
     Request authorization to Location services from the Registrar.
     - parameter manager: a CLLocationManager
     - parameter status: the CLAuthorizationStatus
     */
    @objc public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }
        authorizationCompletionBlock?()
    }
}

public extension Capability {

    /**
     Capability.Location

     This type represents the app's permission to access CLLocationManager.

     For framework consumers - use with GetAuthorizationStatus, Authorize and
     AuthorizedFor. For example

     Get the current authorization status for accessing the user's calendars:

     ```swift
     GetAuthorizationStatus(Capability.Location(.Always)) { available, status in
         // etc
     }
     ```

    - see: `UserLocationOperation`
    - see: `ReverseGeocodeOperation`
    - see: `ReverseGeocodeUserLocationOperation`

     */
    typealias Location = LocationCapability
}
