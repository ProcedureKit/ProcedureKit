//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import CoreLocation
import MapKit

open class ReverseGeocodeProcedure: Procedure, InputProcedure, OutputProcedure {
    public typealias CompletionBlock = (CLPlacemark) -> Void

    public var input: Pending<CLLocation> = .pending
    public private(set) var output: Pending<Result<CLPlacemark>> = .pending

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

        guard let location = input.value else {
            output = .ready(.failure(ProcedureKitError.requirementNotSatisfied()))
            finish(withError: output.error)
            return
        }

        geocoder.pk_reverseGeocodeLocation(location: location) { [weak self] results, error in

            // Check that the procedure is still running
            guard let strongSelf = self, !strongSelf.isFinished else { return }

            // Defer finishing, potentially with an error
            defer { strongSelf.finish(withError: strongSelf.output.error) }

            // Check for placemarks results
            guard let placemarks = results else {
                strongSelf.output = .ready(.failure(ProcedureKitError.component(ProcedureKitLocationComponent(), error: error)))
                return
            }

            // Continue if there is a suitable placemark
            if let placemark = strongSelf.shouldFinish(afterReceivingPlacemarks: placemarks) {
                strongSelf.output = .ready(.success(placemark))
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
