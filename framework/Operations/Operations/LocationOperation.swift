//
//  LocationOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CoreLocation



/**
    An `Operation` subclass to request the user's current
    geographic location.
*/

public class LocationOperation: Operation {
    public typealias LocationResponseHandler = (location: CLLocation) -> Void
    private typealias LocationManagerConfiguration = (LocationManager) -> Void

    public enum Error: ErrorType, Equatable {
        case LocationManagerDidFail(NSError)
    }

    private let accuracy: CLLocationAccuracy
    private var manager: LocationManager?
    private let handler: LocationResponseHandler

    public init(accuracy: CLLocationAccuracy, manager: LocationManager? = .None, handler: LocationResponseHandler) {
        self.accuracy = accuracy
        self.manager = manager
        self.handler = handler
        super.init()
        addCondition(LocationCondition(usage: .WhenInUse, manager: manager))
        addCondition(MutuallyExclusive<LocationManager>())
    }

    public override func execute() {

        let configureLocationManager: LocationManagerConfiguration = { manager in
            manager.opr_setDesiredAccuracy(self.accuracy)
            manager.opr_setDelegate(self)
            manager.opr_startUpdatingLocation()
        }

        if var manager = manager {
            configureLocationManager(manager)
        }
        else {
            dispatch_async(Queue.Main.queue) {
                let manager = CLLocationManager()
                configureLocationManager(manager)
                self.manager = manager as LocationManager
            }
        }
    }

    public override func cancel() {
        dispatch_async(Queue.Main.queue) {
            self.stopLocationUpdates()
            super.cancel()
        }
    }

    private func stopLocationUpdates() {
        manager?.opr_stopLocationUpdates()
        manager = .None
    }
}

extension LocationOperation: CLLocationManagerDelegate {

    public func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let locations = locations as? [CLLocation], location = locations.last where location.horizontalAccuracy <= accuracy {
            stopLocationUpdates()
            handler(location: location)
            finish()
        }
    }

    public func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        stopLocationUpdates()
        finish(Error.LocationManagerDidFail(error))
    }
}


public func ==(a: LocationOperation.Error, b: LocationOperation.Error) -> Bool {
    switch (a, b) {
    case let (.LocationManagerDidFail(aError), .LocationManagerDidFail(bError)):
        return aError == bError
    default: return false
    }
}
