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

open class ReverseGeocodeProcedure: Procedure, InputProcedure, OutputProcedure {
    public typealias CompletionBlock = (CLPlacemark) -> Void

    public var input: Pending<CLLocation> = .pending
    public var output: Pending<ProcedureResult<CLPlacemark>> = .pending

    public let completion: CompletionBlock?

    public var placemark: CLPlacemark? {
        return output.success
    }

    public var location: CLLocation? {
        return input.value
    }

    internal var geocoder: ReverseGeocodeProtocol & GeocodeProtocol = CLGeocoder.make()

    public init(timeout: TimeInterval = 3.0, location: CLLocation? = nil, completion: CompletionBlock? = nil) {
        self.input = location.flatMap { .ready($0) } ?? .pending
        self.completion = completion
        super.init()
        addCondition(MutuallyExclusive<ReverseGeocodeProcedure>())
        addObserver(TimeoutObserver(by: timeout))
        addDidCancelBlockObserver { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.cancelGeocoder()
                self?.finish()
            }
        }
    }

    deinit {
        cancelGeocoder()
    }

    open override func execute() {

        guard let location = input.value else {
            finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
            return
        }

        geocoder.pk_reverseGeocodeLocation(location: location) { [weak self] results, error in

            // Check that the procedure is still running
            guard let strongSelf = self, !strongSelf.isFinished else { return }

            // Check for placemarks results
            guard let placemarks = results else {
                let error: Error = error ?? ProcedureKitError.component(ProcedureKitLocationComponent(), error: error)
                strongSelf.finish(withResult: .failure(error))
                return
            }

            // Continue if there is a suitable placemark
            if let placemark = strongSelf.shouldFinish(afterReceivingPlacemarks: placemarks) {
                if let block = strongSelf.completion {
                    DispatchQueue.main.async { block(placemark) }
                }
                strongSelf.finish(withResult: .success(placemark))
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
