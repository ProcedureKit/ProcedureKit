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
    case WhenInUse = 1

    /// Request access always
    case Always
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
    func opr_setDelegate(aDelegate: CLLocationManagerDelegate)

    /// - returns: the CLAuthorizationStatus
    func opr_authorizationStatus() -> CLAuthorizationStatus

    /**
     Request access for the given LocationUsage (i.e. the requirement).

     - parameter requirement: the LocationUsage
     */
    func opr_requestAuthorizationWithRequirement(requirement: LocationUsage)
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
    public func opr_setDelegate(aDelegate: CLLocationManagerDelegate) {
        self.delegate = aDelegate
    }

    /**
     Request access for the given LocationUsage (i.e. the requirement).

     - parameter requirement: the LocationUsage
     */
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

    /**
     Determine whether access has been granted given the LocationUsage.

     - parameter requirement: the required LocationUsage
     - returns: a true Bool for authorized status
     */
    public func isRequirementMet(requirement: LocationUsage) -> Bool {
        switch (requirement, self) {
        case (.WhenInUse, .AuthorizedWhenInUse), (_, .AuthorizedAlways):
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
public class _LocationCapability<Registrar: LocationCapabilityRegistrarType>: NSObject, CLLocationManagerDelegate, CapabilityType {

    /// - returns: a String, the name of the capability
    public let name: String

    /// - returns: the EKEntityType, the required type of the capability
    public let requirement: LocationUsage

    let registrar: Registrar
    var authorizationCompletionBlock: dispatch_block_t?

    /**
     Initialize the capability. By default, it requires access .WhenInUse.

     - parameter requirement: the required LocationUsage, defaults to .WhenInUse
     - parameter registrar: the registrar to use. Defauls to creating a Registrar.
     */
    public required init(_ requirement: LocationUsage = .WhenInUse, registrar: Registrar = Registrar()) {
        self.name = "Location"
        self.requirement = requirement
        self.registrar = registrar
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
    public func authorizationStatus(completion: CLAuthorizationStatus -> Void) {
        completion(registrar.opr_authorizationStatus())
    }

    /**
     Request authorization to Location services from the Registrar.
     - parameter completion: a dispatch_block_t
     */
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

    /**
     Request authorization to Location services from the Registrar.
     - parameter manager: a CLLocationManager
     - parameter status: the CLAuthorizationStatus
     */
    @objc public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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
    typealias Location = _LocationCapability<CLLocationManager>
}

@available(*, unavailable, renamed="AuthorizedFor(Capability.Location(.WhenInUse))")
public typealias LocationCondition = AuthorizedFor<Capability.Location>



