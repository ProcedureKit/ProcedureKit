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

    var serviceEnabled: Bool { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    weak var delegate: CLLocationManagerDelegate! { get set }

    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
}

extension CLLocationManager: LocationManager {
    
    var serviceEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
}

/**
    A condition for verifying access to the user's location.
*/
struct LocationCondition: OperationCondition {

    enum Usage: Int { case WhenInUse = 1, Always }

    enum Error: ErrorType {
        case LocationServicesNotEnabled
        case AuthenticationStatusNotSufficient(CLAuthorizationStatus, Usage)
    }

    let name = "Location"
    let isMutuallyExclusive = false

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
        manager.delegate = self

        let authorizationKey: String

        switch usage {

        case .WhenInUse:
            authorizationKey = "NSLocationWhenInUseUsageDescription"
            manager.requestWhenInUseAuthorization()

        case .Always:
            authorizationKey = "NSLocationAlwaysUsageDescription"
            manager.requestWhenInUseAuthorization()
        }

        // This is helpful when developing the app.
        assert(NSBundle.mainBundle().objectForInfoDictionaryKey(authorizationKey) != nil, "Requesting location permission requires the \(authorizationKey) key in your Info.plist")
    }

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





