//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

#if !os(watchOS)

#if SWIFT_PACKAGE
    import ProcedureKit
    import Foundation
#endif

import SystemConfiguration

// MARK: - Internal concrete types

extension Reachability {

    final class Manager {
        typealias Status = NetworkStatus

        static let shared = Reachability.Manager(Device())

        let queue = DispatchQueue(label: "run.kit.ProcedureKit.Network.Reachability")
        var network: NetworkReachability
        fileprivate var protectedObservers = Protector(Array<Observer>())

        var observers: [Observer] {
            return protectedObservers.access
        }

        init(_ network: NetworkReachability) {
            self.network = network
            self.network.delegate = self
        }
    }
}

extension Reachability.Manager: NetworkReachabilityDelegate {

    func didChangeReachability(flags: SCNetworkReachabilityFlags) {
        guard observers.count > 0 else { return }

        let status = Status(flags: flags)
        let observersToCheck = observers

        protectedObservers.write { (observers: inout Array<Reachability.Observer>) in

            var observersToBeRemoved = Array<Reachability.Observer>()

            let newObservers = observersToCheck.filter { observer in
                let shouldRemove = status.isConnected(via: observer.connectivity)
                if shouldRemove {
                    observersToBeRemoved.append(observer)
                }
                return !shouldRemove
            }

            if newObservers.count == 0 {
                self.network.stopNotifier()
            }

            if observersToBeRemoved.count > 0 {
                observersToBeRemoved.forEach {
                    DispatchQueue.main.async(execute: $0.didConnectBlock)
                }
            }

            observers = newObservers
        }
    }
}

extension Reachability.Manager: SystemReachability {

    func whenReachable(via connectivity: Reachability.Connectivity, block: @escaping () -> Void) {
        protectedObservers.write { (observers: inout Array<Reachability.Observer>) in
            let observer = Reachability.Observer(connectivity: connectivity, didConnectBlock: block)
            observers.append(observer)
        }
        do {
            try network.startNotifier(onQueue: queue)
        }
        catch {
            print("Caught error: \(error) starting reachability notifier.")
        }
    }

    func reachability(of: URL, block: @escaping (Reachability.NetworkStatus) -> Void) {

    }
}

// MARK: - Device Reachability

extension Reachability {

    final class Device {

        static func makeDefaultRouteReachability() throws -> SCNetworkReachability {
            var zeroAddress = sockaddr()
            zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
            zeroAddress.sa_family = sa_family_t(AF_INET)

            guard let reachability: SCNetworkReachability = withUnsafePointer(to: &zeroAddress, {
                SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
            }) else { throw ReachabilityError.failedToCreateDefaultRouteReachability }

            return reachability
        }

        internal let defaultRouteReachability: SCNetworkReachability
        fileprivate private(set) var threadSafeProtector = Protector(false)
        weak var delegate: NetworkReachabilityDelegate?

        var log: LoggerProtocol

        var notifierIsRunning: Bool {
            get { return threadSafeProtector.access }
            set {
                threadSafeProtector.write { (isRunning: inout Bool) in
                    isRunning = newValue
                }
            }
        }

        init(log logger: LoggerProtocol = Logger()) {
            defaultRouteReachability = try! Device.makeDefaultRouteReachability() // swiftlint:disable:this force_try
            log = logger
        }

        deinit {
            stopNotifier()
        }
    }
}

extension Reachability.Device: NetworkReachability {

    func getFlags(forReachability reachability: SCNetworkReachability) -> SCNetworkReachabilityFlags {
        var flags = SCNetworkReachabilityFlags()
        guard withUnsafeMutablePointer(to: &flags, {
            SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0))
        }) else { return SCNetworkReachabilityFlags() }

        return flags
    }

    func didChangeReachability(flags: SCNetworkReachabilityFlags) {
        delegate?.didChangeReachability(flags: flags)
    }

    func check(reachability: SCNetworkReachability, on queue: DispatchQueue) {
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            let flags = strongSelf.getFlags(forReachability: reachability)
            strongSelf.didChangeReachability(flags: flags)
        }
    }

    func startNotifier(onQueue queue: DispatchQueue) throws {
        precondition(delegate != nil, "Reachability delegate not set.")
        guard !notifierIsRunning else { return }

        notifierIsRunning = true

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard SCNetworkReachabilitySetCallback(defaultRouteReachability, __device_reachability_callback, &context) else {
            stopNotifier()
            throw ReachabilityError.failedToSetNotifierCallback
        }

        guard SCNetworkReachabilitySetDispatchQueue(defaultRouteReachability, queue) else {
            stopNotifier()
            throw ReachabilityError.failedToSetNotifierDispatchQueue
        }

        check(reachability: defaultRouteReachability, on: queue)
    }

    func stopNotifier() {
        SCNetworkReachabilitySetCallback(defaultRouteReachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(defaultRouteReachability, nil)
        notifierIsRunning = false
    }
}

private func __device_reachability_callback(reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
    guard let info = info else { return }
    let deviceReachability = Unmanaged<Reachability.Device>.fromOpaque(info).takeUnretainedValue()
    DispatchQueue.main.async {
        deviceReachability.didChangeReachability(flags: flags)
    }
}

#endif
