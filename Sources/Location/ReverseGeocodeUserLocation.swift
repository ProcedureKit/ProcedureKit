//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CoreLocation
import MapKit

public struct UserLocationPlacemark: Equatable {
    public static func == (lhs: UserLocationPlacemark, rhs: UserLocationPlacemark) -> Bool {
        return lhs.location == rhs.location && lhs.placemark == rhs.placemark
    }
    public let location: CLLocation
    public let placemark: CLPlacemark
}

open class ReverseGeocodeUserLocationProcedure: GroupProcedure, ResultInjection {

    public typealias CompletionBlock = (UserLocationPlacemark) -> Void

    class Finishing: Procedure {

        let completion: CompletionBlock?

        var location: PendingValue<CLLocation> = .pending
        var placemark: PendingValue<CLPlacemark> = .pending

        var requirement: PendingValue<Void> = .void
        var result: PendingValue<UserLocationPlacemark> = .pending

        init(completion: CompletionBlock? = nil) {
            self.completion = completion
            super.init()
        }

        override func execute() {
            var finishingError: Error? = nil
            defer { finish(withError: finishingError) }

            guard let location = location.value, let placemark = placemark.value else {
                finishingError = ProcedureKitError.requirementNotSatisfied()
                return
            }

            let userLocationPlacemark = UserLocationPlacemark(location: location, placemark: placemark)
            result = .ready(userLocationPlacemark)

            if let block = completion {
                DispatchQueue.main.async {
                    block(userLocationPlacemark)
                }
            }
        }
    }

    private let finishing: Finishing
    private let userLocation: UserLocationProcedure
    private let reverseGeocodeLocation: ReverseGeocodeProcedure

    public var requirement: PendingValue<Void> = .void
    public var result: PendingValue<UserLocationPlacemark> {
        return finishing.result
    }

    init(dispatchQueue: DispatchQueue? = nil, timeout: TimeInterval = 3.0, accuracy: CLLocationAccuracy = kCLLocationAccuracyThreeKilometers, completion: CompletionBlock? = nil) {

        finishing = Finishing(completion: completion)

        userLocation = UserLocationProcedure(timeout: timeout, accuracy: accuracy)

        reverseGeocodeLocation = ReverseGeocodeProcedure(timeout: timeout).injectResult(from: userLocation)

        finishing.inject(dependency: userLocation) { procedure, userLocation, errors in
            guard let location = userLocation.location, errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            procedure.location = .ready(location)
        }

        finishing.inject(dependency: reverseGeocodeLocation) { procedure, reverseGeocodeLocation, errors in
            guard let placemark = reverseGeocodeLocation.placemark, errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            procedure.placemark = .ready(placemark)
        }

        super.init(dispatchQueue: dispatchQueue, operations: [userLocation, reverseGeocodeLocation, finishing])
        add(observer: TimeoutObserver(by: timeout))
    }

    internal func set(manager: LocationServicesRegistrarProtocol & LocationServicesProtocol) -> ReverseGeocodeUserLocationProcedure {
        precondition(!isExecuting)
        userLocation.manager = manager
        return self
    }

    internal func set(geocoder: ReverseGeocodeProtocol & GeocodeProtocol) -> ReverseGeocodeUserLocationProcedure {
        precondition(!isExecuting)
        reverseGeocodeLocation.geocoder = geocoder
        return self
    }
}
