//
//  LocationCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CoreLocation

public protocol LocationManager: NSObjectProtocol {
    // In Swift 2.0, these can be static properties 
    // as in `CLLocationManager`.
    var serviceEnabled: Bool { get }
    var authorizationStatus: CLAuthorizationStatus { get }

    func opr_requestWhenInUseAuthorization()
    func opr_requestAlwaysAuthorization()

    func opr_startUpdatingLocation()
    func opr_stopLocationUpdates()

    func opr_setDesiredAccuracy(desiredAccuracy: CLLocationAccuracy)
    func opr_setDelegate(aDelegate: CLLocationManagerDelegate)
}

extension CLLocationManager: LocationManager {

    public var serviceEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    public var authorizationStatus: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    public func opr_requestWhenInUseAuthorization() {
        requestWhenInUseAuthorization()
    }

    public func opr_requestAlwaysAuthorization() {
        requestAlwaysAuthorization()
    }

    public func opr_setDesiredAccuracy(accuracy: CLLocationAccuracy) {
        desiredAccuracy = accuracy
    }

    public func opr_setDelegate(aDelegate: CLLocationManagerDelegate) {
        delegate = aDelegate
    }

    public func opr_startUpdatingLocation() {
        startUpdatingLocation()
    }

    public func opr_stopLocationUpdates() {
        stopUpdatingLocation()
    }
}

/**
    A condition for verifying access to the user's location.
*/
public struct LocationCondition: OperationCondition {

    public enum Usage: Int { case WhenInUse = 1, Always }

    public enum Error: ErrorType {
        case LocationServicesNotEnabled
        case AuthenticationStatusNotSufficient(CLAuthorizationStatus, Usage)
    }

    public let name = "Location"
    public let isMutuallyExclusive = false

    let usage: Usage
    let manager: LocationManager

    /**
        This is the true public API, the other public initializer is really just a testing
        interface, and will not be public in Swift 2.0, Operations 2.0
    */
    public init(usage: Usage = .WhenInUse) {
        self.usage = usage
        self.manager = CLLocationManager()
    }

    /**
        This is a testing interface, and will not be public in Swift 2.0, Operations 2.0.
        Instead use init(:Usage)
    */
    public init(usage: Usage, manager: LocationManager? = .None) {
        self.usage = usage
        self.manager = manager ?? CLLocationManager()
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return LocationPermissionOperation(usage: usage, manager: manager)
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let enabled = manager.serviceEnabled
        let actual = manager.authorizationStatus

        switch (enabled, usage, actual) {

        case (true, _, .AuthorizedAlways), (true, .WhenInUse, .AuthorizedWhenInUse):
            // Service is enabled with always authorization, or we
            // require when in use, and it's authorized when in use.
            completion(.Satisfied)

        case (false, _, _):
            completion(.Failed(Error.LocationServicesNotEnabled))

        default:
            completion(.Failed(Error.AuthenticationStatusNotSufficient(actual, usage)))
        }
    }
}

class LocationPermissionOperation: Operation, CLLocationManagerDelegate {
    let usage: LocationCondition.Usage
    var manager: LocationManager

    init(usage: LocationCondition.Usage, manager: LocationManager = CLLocationManager()) {
        self.usage = usage
        self.manager = manager
        super.init()
        addCondition(AlertPresentation())
    }

    override func execute() {
        switch (manager.authorizationStatus, usage) {
        case (.NotDetermined, _), (.AuthorizedWhenInUse, .Always):
            dispatch_async(Queue.Main.queue, requestPermission)
        default:
            finish()
        }
    }

    private func requestPermission() {
        manager.opr_setDelegate(self)

        let authorizationKey: String

        switch usage {

        case .WhenInUse:
            authorizationKey = "NSLocationWhenInUseUsageDescription"
            manager.opr_requestWhenInUseAuthorization()

        case .Always:
            authorizationKey = "NSLocationAlwaysUsageDescription"
            manager.opr_requestAlwaysAuthorization()
        }
    }

    @objc func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if executing && status != CLAuthorizationStatus.NotDetermined {
            if self.manager.isKindOfClass(CLLocationManager) && (self.manager as! CLLocationManager) == manager {
                finish()
            }
                // This is just for test support
            else if !self.manager.isKindOfClass(CLLocationManager) {
                finish()
            }
        }
    }
}





