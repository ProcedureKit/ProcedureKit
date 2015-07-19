//
//  LocationPermissionCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CoreLocation

internal protocol LocationManager {

}

extension CLLocationManager: LocationManager { }

/**
    A condition for verifying access to the user's location.
*/
struct LocationCondition: OperationCondition {

    enum Usage: Int { case WhenInUse = 1, Always }

    private class LocationPermissionOperation: Operation {
        let usage: Usage

        init(usage: Usage) {
            self.usage = usage
            super.init()

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
        return LocationPermissionOperation(usage: usage)
    }

    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {

    }
}



