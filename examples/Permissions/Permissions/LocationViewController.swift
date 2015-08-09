//
//  LocationViewController.swift
//  Permissions
//
//  Created by Daniel Thorpe on 28/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import Operations

class LocationViewController: PermissionViewController {

    var mapView: MKMapView!

    var location: CLLocation? = .None {
        didSet {
            if let location = location {
                dispatch_async(Queue.Main.queue) {
                    self.mapView.setRegion(location.region, animated: true)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Location", comment: "Location")

        permissionNotDetermined.informationLabel.text = "We haven't yet asked permission to access your Location."
        permissionGranted.instructionLabel.text = "Perform an operation to get your current Location."
        permissionGranted.button.setTitle("Where am I?", forState: .Normal)
        operationResults.informationLabel.hidden = true

        mapView = MKMapView.newAutoLayoutView()
        operationResults.addSubview(mapView)
        mapView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)

    }

    override func viewWillAppear(animated: Bool) {
        determineAuthorizationStatus()
    }

    override func conditionsForState(state: State, silent: Bool) -> [OperationCondition] {
        return configureConditionsForState(state, silent: silent)(LocationCondition())
    }
    
    func determineAuthorizationStatus(silently: Bool = true) {

        // Create a simple block operation to set the state.
        let authorized = BlockOperation { (continueWithError: BlockOperation.ContinuationBlockType) in
            self.state = .Authorized
            self.mapView.showsUserLocation = true
            continueWithError(error: nil)
        }

        authorized.name = "Authorized Access"

        // Condition the operation so that it will only run if we have
        // permission to access the user's address book.
        let condition = LocationCondition()

        // Additionally, suppress the automatic request if not authorized.
        authorized.addCondition(silently ? SilentCondition(condition) : condition)

        // Attach an observer so that we can inspect any condition errors
        // From here, we can determine the authorization status if not
        // authorized.
        authorized.addObserver(BlockObserver { (_, errors) in
            if let error = errors.first as? LocationCondition.Error {
                switch error {
                case let .AuthenticationStatusNotSufficient(CLAuthorizationStatus.NotDetermined, _):
                    self.state = .Unknown

                case let .AuthenticationStatusNotSufficient(CLAuthorizationStatus.Denied, _):
                    self.state = .Denied

                default:
                    self.state = .Unknown
                }
            }
        })

        queue.addOperation(authorized)
    }

    override func requestPermission() {
        determineAuthorizationStatus(silently: false)
    }

    override func performOperation() {
        let location = LocationOperation() { location in
            self.state = .Completed
            self.location = location
        }
        location.addCondition(LocationCondition())
        queue.addOperation(location)
    }
}

extension CLLocation {

    var region: MKCoordinateRegion {
        get {
            let miles: CLLocationDistance = 12
            let scalingFactor = abs(cos(2.0 * M_PI * coordinate.latitude / 360.0))
            let span = MKCoordinateSpan(latitudeDelta: miles/69.0, longitudeDelta: miles/(scalingFactor*69.0))
            return MKCoordinateRegion(center: coordinate, span: span)
        }
    }
}




