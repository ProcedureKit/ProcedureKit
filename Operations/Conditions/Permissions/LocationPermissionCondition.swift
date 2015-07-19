//
//  LocationPermissionCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CoreLocation

internal protocol LocationManager: NSObjectProtocol {

    static func locationServicesEnabled() -> Bool
    static func authorizationStatus() -> CLAuthorizationStatus

    weak var delegate: CLLocationManagerDelegate? { get set }
}

extension CLLocationManager: LocationManager { }

/**
    A condition for verifying access to the user's location.
*/
struct LocationCondition: OperationCondition {

    enum Usage: Int { case WhenInUse = 1, Always }

    enum Error: ErrorType {
        case LocationServicesNotEnabled
        case AuthenticationStatusNotSufficient(CLAuthorizationStatus, Usage)
    }

    private class LocationPermissionOperation: Operation {
        let usage: Usage
        var manager: LocationManager

        init(usage: Usage, manager: LocationManager) {
            self.usage = usage
            self.manager = manager
            super.init()
            addCondition(AlertPresentation())
        }

        private override func execute() {
            let actual = manager.dynamicType.authorizationStatus()
            switch (actual, usage) {
            case (.NotDetermined, _), (.AuthorizedWhenInUse, .Always):
                dispatch_async(Queue.Main.queue, requestPermission)
            default:
                finish()
            }
        }

        private func requestPermission() {
            manager.delegate = self

            
        }
    }

    static let name = "Location"
    static let isMutuallyExclusive = false

    let usage: Usage
    let manager: LocationManager

    init(usage: Usage, manager: LocationManager = CLLocationManager()) {
        self.usage = usage
        self.manager = manager
    }

    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return LocationPermissionOperation(usage: usage, manager: manager)
    }

    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let enabled = manager.dynamicType.locationServicesEnabled()
        let actual = manager.dynamicType.authorizationStatus()

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

extension LocationCondition.LocationPermissionOperation: CLLocationManagerDelegate {

    @objc func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if executing && status != CLAuthorizationStatus.NotDetermined {
            if self.manager.isKindOfClass(CLLocationManager) && (self.manager as! CLLocationManager) == manager {
                finish()
            }
            else if !self.manager.isKindOfClass(CLLocationManager) {
                finish()
            }
        }
    }
}


