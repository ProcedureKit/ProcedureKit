//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CoreLocation
import MapKit

open class ReverseGeocodeProcedure: Procedure, ResultInjectionProtocol {
    public typealias CompletionBlock = (CLPlacemark) -> Void

    public var requirement: PendingValue<CLLocation> = .pending
    public private(set) var result: PendingValue<CLPlacemark> = .pending

    public let completion: CompletionBlock?

    public var placemark: CLPlacemark? {
        return result.value
    }

    public var location: CLLocation? {
        return requirement.value
    }

    internal var geocoder: ReverseGeocodeProtocol & GeocodeProtocol = CLGeocoder.make()

    public init(timeout: TimeInterval = 3.0, location: CLLocation? = nil, completion: CompletionBlock? = nil) {
        self.requirement = location.flatMap { .ready($0) } ?? .pending
        self.completion = completion
        super.init()
        add(condition: MutuallyExclusive<ReverseGeocodeProcedure>())
        add(observer: TimeoutObserver(by: timeout))
        addDidCancelBlockObserver { [weak self] _, errors in
            DispatchQueue.main.async {
                self?.cancelGeocoder()
            }
        }
    }

    deinit {
        cancelGeocoder()
    }

    open override func execute() {

        guard let location = requirement.value else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }

        geocoder.pk_reverseGeocodeLocation(location: location) { [weak self] results, error in

            // Check that the procedure is still running
            guard let strongSelf = self, !strongSelf.isFinished else { return }

            // Defer finishing, potentially with an error
            defer { strongSelf.finish(withError: error.map { ProcedureKitError.component(ProcedureKitLocationComponent(), error: $0) }) }

            // Check for placemarks results
            guard let placemarks = results else { return }

            // Continue if there is a suitable placemark
            if let placemark = strongSelf.shouldFinish(afterReceivingPlacemarks: placemarks) {
                strongSelf.result = .ready(placemark)
                if let block = strongSelf.completion {
                    DispatchQueue.main.async { block(placemark) }
                }
            }
        }
    }

    public func cancelGeocoder() {
        geocoder.pk_cancel()
    }

    open func shouldFinish(afterReceivingPlacemarks placemarks: [CLPlacemark]) -> CLPlacemark? {
        return placemarks.first
    }
}
