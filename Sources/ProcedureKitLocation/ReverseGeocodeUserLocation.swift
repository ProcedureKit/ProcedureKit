//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import Foundation
import Dispatch
import CoreLocation
import MapKit

public struct UserLocationPlacemark: Equatable {
    public let location: CLLocation
    public let placemark: CLPlacemark
}

open class ReverseGeocodeUserLocationProcedure: GroupProcedure, OutputProcedure {

    public typealias CompletionBlock = (UserLocationPlacemark) -> Void

    class Finishing: Procedure, OutputProcedure {

        let completion: CompletionBlock?

        var location: Pending<CLLocation> = .pending
        var placemark: Pending<CLPlacemark> = .pending

        var output: Pending<ProcedureResult<UserLocationPlacemark>> = .pending

        init(completion: CompletionBlock? = nil) {
            self.completion = completion
            super.init()
        }

        override func execute() {

            guard
                !isCancelled,
                let location = location.value,
                let placemark = placemark.value
            else {
                finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
                return
            }

            let userLocationPlacemark = UserLocationPlacemark(location: location, placemark: placemark)

            if let block = completion {
                DispatchQueue.main.async {
                    block(userLocationPlacemark)
                }
            }

            finish(withResult: .success(userLocationPlacemark))
        }
    }

    private let finishing: Finishing
    private let userLocation: UserLocationProcedure
    private let reverseGeocodeLocation: ReverseGeocodeProcedure

    public var output: Pending<ProcedureResult<UserLocationPlacemark>> {
        get { return finishing.output }
        set { assertionFailure("\(#function) should not be publically settable.") }
    }

    public init(dispatchQueue: DispatchQueue? = nil, timeout: TimeInterval = 3.0, accuracy: CLLocationAccuracy = kCLLocationAccuracyThreeKilometers, completion: CompletionBlock? = nil) {

        finishing = Finishing(completion: completion)

        userLocation = UserLocationProcedure(timeout: timeout, accuracy: accuracy)

        reverseGeocodeLocation = ReverseGeocodeProcedure(timeout: timeout).injectResult(from: userLocation)

        finishing.inject(dependency: userLocation) { finishing, userLocation, error in
            guard let location = userLocation.location, error == nil else {
                finishing.cancel(with: ProcedureKitError.dependency(finishedWithError: error)); return
            }
            finishing.location = .ready(location)
        }

        finishing.inject(dependency: reverseGeocodeLocation) { finishing, reverseGeocodeLocation, error in
            guard let placemark = reverseGeocodeLocation.placemark, error == nil else {
                finishing.cancel(with: ProcedureKitError.dependency(finishedWithError: error)); return
            }
            finishing.placemark = .ready(placemark)
        }

        super.init(dispatchQueue: dispatchQueue, operations: [userLocation, reverseGeocodeLocation, finishing])
        addObserver(TimeoutObserver(by: timeout))
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
