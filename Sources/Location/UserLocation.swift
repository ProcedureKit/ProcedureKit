//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch
import CoreLocation
import MapKit

open class UserLocationProcedure: Procedure, OutputProcedure, CLLocationManagerDelegate {
    public typealias CompletionBlock = (CLLocation) -> Void

    public let accuracy: CLLocationAccuracy
    public let completion: CompletionBlock?

    public var output: Pending<ProcedureResult<CLLocation>> = .pending

    public var location: CLLocation? {
        return output.success
    }

    internal var capability = Capability.Location()

    internal lazy var locationManager: LocationServicesRegistrarProtocol & LocationServicesProtocol = CLLocationManager.make()
    internal var manager: LocationServicesRegistrarProtocol & LocationServicesProtocol {
        get { return locationManager }
        set {
            locationManager = newValue
            capability.registrar = newValue
        }
    }

    public init(timeout: TimeInterval = 3.0, accuracy: CLLocationAccuracy = kCLLocationAccuracyThreeKilometers, completion: CompletionBlock? = nil) {
        self.accuracy = accuracy
        self.completion = completion
        super.init()
        add(condition: AuthorizedFor(capability))
        add(condition: MutuallyExclusive<UserLocationProcedure>())
        add(observer: TimeoutObserver(by: timeout))
        addDidCancelBlockObserver { [weak self] _, errors in
            DispatchQueue.main.async {
                self?.stopLocationUpdates()
            }
        }
    }

    deinit {
        stopLocationUpdates()
    }

    open override func execute() {
        manager.pk_set(desiredAccuracy: accuracy)
        manager.pk_set(delegate: self)
        manager.pk_startUpdatingLocation()
    }

    public func stopLocationUpdates() {
        manager.pk_stopUpdatingLocation()
        manager.pk_set(delegate: nil)
    }

    open func shouldFinish(afterReceivingLocation location: CLLocation) -> Bool {
        switch accuracy {
        case _ where accuracy < 0:
            return true
        case _ where location.horizontalAccuracy <= accuracy:
            return true
        default:
            return false
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isFinished, let location = locations.last else { return }
        guard shouldFinish(afterReceivingLocation: location) else {
            output = .ready(.success(location))
            return
        }
        log.info(message: "Updated last location: \(location)")
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self, !weakSelf.isFinished else { return }
            weakSelf.stopLocationUpdates()
            weakSelf.output = .ready(.success(location))
            weakSelf.completion?(location)
            weakSelf.finish()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.stopLocationUpdates()
            let pkerror = ProcedureKitError.component(ProcedureKitLocationComponent(), error: error)
            weakSelf.output = .ready(.failure(pkerror))
            weakSelf.finish(withError: pkerror)
        }
    }
}
