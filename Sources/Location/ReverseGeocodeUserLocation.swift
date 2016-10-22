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

open class ReverseGeocodeUserLocationProcedure: GroupProcedure, ResultInjectionProtocol {

    public typealias CompletionBlock = (UserLocationPlacemark) -> Void

    class Finishing: Procedure {

        let completion: CompletionBlock?

        var location: CLLocation? = nil
        var placemark: CLPlacemark? = nil

        var result: UserLocationPlacemark? {
            get {
                guard let location = location, let placemark = placemark else { return nil }
                return UserLocationPlacemark(location: location, placemark: placemark)
            }
        }

        init(completion: CompletionBlock? = nil) {
            self.completion = completion
            super.init()
        }

        override func execute() {
            var finishingError: Error? = nil
            defer { finish(withError: finishingError) }

            guard let result = result else {
                finishingError = ProcedureKitError.requirementNotSatisfied()
                return
            }

            if let block = completion {
                DispatchQueue.main.async {
                    block(result)
                }
            }
        }
    }

    private let finishing: Finishing
    private let userLocation: UserLocationProcedure
    private let reverseGeocodeLocation: ReverseGeocodeProcedure

    public var requirement: Void = ()

    public var result: UserLocationPlacemark? {
        return finishing.result
    }

    init(underlyingQueue: DispatchQueue? = nil, timeout: TimeInterval = 3.0, accuracy: CLLocationAccuracy = kCLLocationAccuracyThreeKilometers, completion: CompletionBlock? = nil) {

        finishing = Finishing(completion: completion)

        userLocation = UserLocationProcedure(timeout: timeout, accuracy: accuracy)

        reverseGeocodeLocation = ReverseGeocodeProcedure(timeout: timeout).injectResult(from: userLocation)

        finishing.inject(dependency: userLocation) { procedure, userLocation, errors in
            guard let location = userLocation.location, errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            procedure.location = location
        }

        finishing.inject(dependency: reverseGeocodeLocation) { procedure, reverseGeocodeLocation, errors in
            guard let placemark = reverseGeocodeLocation.placemark, errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            procedure.placemark = placemark
        }

        super.init(underlyingQueue: underlyingQueue, operations: [userLocation, reverseGeocodeLocation, finishing])
        add(observer: TimeoutObserver(by: timeout))
    }

    internal func set(manager: LocationServicesRegristrarProtocol & LocationServicesProtocol) -> ReverseGeocodeUserLocationProcedure {
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
