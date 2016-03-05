//
//  Reachability.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import SystemConfiguration

// swiftlint:disable variable_name

public struct Reachability {

    /// Errors which can be thrown or returned.
    public enum Error: ErrorType {
        case FailedToCreateDefaultRouteReachability
        case FailedToSetNotifierCallback
        case FailedToSetDispatchQueue
    }

    /// The kind of `Reachability` connectivity
    public enum Connectivity {
        case AnyConnectionKind, ViaWWAN, ViaWiFi
    }

    /// The `NetworkStatus`
    public enum NetworkStatus {
        case NotReachable
        case Reachable(Connectivity)
    }

    /// The ObserverBlockType
    public typealias ObserverBlockType = NetworkStatus -> Void

    struct Observer {
        let connectivity: Connectivity
        let whenConnectedBlock: () -> Void
    }
}

protocol NetworkReachabilityDelegate: class {

    func reachabilityDidChange(flags: SCNetworkReachabilityFlags)
}

protocol NetworkReachabilityType {

    weak var delegate: NetworkReachabilityDelegate? { get set }

    func startNotifierOnQueue(queue: dispatch_queue_t) throws

    func stopNotifier()

    func reachabilityFlagsForHostname(host: String) -> SCNetworkReachabilityFlags?
}

protocol ReachabilityManagerType {

    init(_ network: NetworkReachabilityType)
}

protocol SystemReachabilityType: ReachabilityManagerType {

    func whenConnected(conn: Reachability.Connectivity, block: () -> Void)
}

protocol HostReachabilityType: ReachabilityManagerType {

    func reachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType)
}

final class ReachabilityManager {
    typealias Status = Reachability.NetworkStatus

    static let sharedInstance = ReachabilityManager(DeviceReachability())

    let queue = Queue.Utility.serial("me.danthorpe.Operations.Reachability")
    var network: NetworkReachabilityType
    var _observers = Protector(Array<Reachability.Observer>())

    var observers: [Reachability.Observer] {
        return _observers.read { $0 }
    }

    var numberOfObservers: Int {
        return observers.count
    }

    required init(_ net: NetworkReachabilityType) {
        network = net
        network.delegate = self
    }
}

extension ReachabilityManager: NetworkReachabilityDelegate {

    func reachabilityDidChange(flags: SCNetworkReachabilityFlags) {

        let status = Status(flags: flags)
        let observersToCheck = _observers.read { $0 }

        _observers.write { (inout mutableObservers: Array<Reachability.Observer>) in
            mutableObservers = observersToCheck.filter { observer in
                let shouldRemove = status.isConnected(observer.connectivity)
                if shouldRemove {
                    dispatch_async(Queue.Main.queue, observer.whenConnectedBlock)
                }
                return !shouldRemove
            }
        }

        if numberOfObservers == 0 {
            network.stopNotifier()
        }
    }
}

extension ReachabilityManager: SystemReachabilityType {

    // swiftlint:disable force_try
    func whenConnected(conn: Reachability.Connectivity, block: () -> Void) {
        _observers.write({ (inout mutableObservers: [Reachability.Observer]) in
            mutableObservers.append(Reachability.Observer(connectivity: conn, whenConnectedBlock: block))
        }, completion: { try! self.network.startNotifierOnQueue(self.queue) })
    }
    // swiftlint:enable force_try
}

extension ReachabilityManager: HostReachabilityType {

    func reachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType) {

        dispatch_async(queue) { [reachabilityFlagsForHostname = network.reachabilityFlagsForHostname] in
            if let host = url.host, flags = reachabilityFlagsForHostname(host) {
                completion(Status(flags: flags))
            }
            else {
                completion(.NotReachable)
            }
        }
    }
}

class DeviceReachability: NetworkReachabilityType {

    typealias Error = Reachability.Error

    var __defaultRouteReachability: SCNetworkReachability? = .None
    var threadSafeProtector = Protector(false)
    weak var delegate: NetworkReachabilityDelegate?

    var notifierIsRunning: Bool {
        get { return threadSafeProtector.read { $0 } }
        set {
            threadSafeProtector.write { (inout isRunning: Bool) in
                isRunning = newValue
            }
        }
    }

    init() { }

    func defaultRouteReachability() throws -> SCNetworkReachability {

        if let reachability = __defaultRouteReachability { return reachability }

        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let reachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { throw Error.FailedToCreateDefaultRouteReachability }

        __defaultRouteReachability = reachability
        return reachability
    }

    func reachabilityForHost(host: String) -> SCNetworkReachability? {
        return SCNetworkReachabilityCreateWithName(nil, (host as NSString).UTF8String)
    }

    func getFlagsForReachability(reachability: SCNetworkReachability) -> SCNetworkReachabilityFlags {
        var flags = SCNetworkReachabilityFlags()
        guard withUnsafeMutablePointer(&flags, {
            SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0))
        }) else { return SCNetworkReachabilityFlags() }

        return flags
    }

    func reachabilityDidChange(flags: SCNetworkReachabilityFlags) {
        delegate?.reachabilityDidChange(flags)
    }

    func check(reachability: SCNetworkReachability, queue: dispatch_queue_t) {
        dispatch_async(queue) { [weak self] in
            if let delegate = self?.delegate, flags = self?.getFlagsForReachability(reachability) {
                delegate.reachabilityDidChange(flags)
            }
        }
    }

    func startNotifierOnQueue(queue: dispatch_queue_t) throws {
        assert(delegate != nil, "Reachability Delegate not set.")
        let reachability = try defaultRouteReachability()
        if !notifierIsRunning {
            notifierIsRunning = true
            var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
            context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())

            guard SCNetworkReachabilitySetCallback(reachability, __device_reachability_callback, &context) else {
                stopNotifier()
                throw Error.FailedToSetNotifierCallback
            }

            guard SCNetworkReachabilitySetDispatchQueue(reachability, queue) else {
                stopNotifier()
                throw Error.FailedToSetDispatchQueue
            }
        }
        check(reachability, queue: queue)
    }

    func stopNotifier() {
        if let reachability = try? defaultRouteReachability() {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)
            SCNetworkReachabilitySetCallback(reachability, nil, nil)
        }
        notifierIsRunning = false
    }

    func reachabilityFlagsForHostname(host: String) -> SCNetworkReachabilityFlags? {
        guard let reachability = reachabilityForHost(host) else { return .None }
        return getFlagsForReachability(reachability)
    }
}

private func __device_reachability_callback(reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>) {
    let handler = Unmanaged<DeviceReachability>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()
    dispatch_async(Queue.Default.queue) {
        handler.delegate?.reachabilityDidChange(flags)
    }
}

extension Reachability.NetworkStatus: Equatable { }

public func == (lhs: Reachability.NetworkStatus, rhs: Reachability.NetworkStatus) -> Bool {
    switch (lhs, rhs) {
    case (.NotReachable, .NotReachable):
        return true
    case let (.Reachable(aConnectivity), .Reachable(bConnectivity)):
        return aConnectivity == bConnectivity
    default:
        return false
    }
}

extension Reachability.NetworkStatus {

    public init(flags: SCNetworkReachabilityFlags) {
        if flags.isReachableViaWiFi {
            self = .Reachable(.ViaWiFi)
        }
        else if flags.isReachableViaWWAN {
            #if os(iOS)
            self = .Reachable(.ViaWWAN)
            #else
            self = .Reachable(.AnyConnectionKind)
            #endif
        }
        else {
            self = .NotReachable
        }
    }

    func isConnected(target: Reachability.Connectivity) -> Bool {
        switch (self, target) {
        case (.NotReachable, _):
            return false
        case (.Reachable(.ViaWWAN), .ViaWiFi):
            return false
        case (.Reachable(_), _):
            return true
        }
    }
}

// MARK: - Conformance

extension SCNetworkReachabilityFlags {

    var isReachable: Bool {
        return contains(.Reachable)
    }

    var isConnectionRequired: Bool {
        return contains(.ConnectionRequired)
    }

    var isInterventionRequired: Bool {
        return contains(.InterventionRequired)
    }

    var isConnectionOnTraffic: Bool {
        return contains(.ConnectionOnTraffic)
    }

    var isConnectionOnDemand: Bool {
        return contains(.ConnectionOnDemand)
    }

    var isTransientConnection: Bool {
        return contains(.TransientConnection)
    }

    var isLocalAddress: Bool {
        return contains(.IsLocalAddress)
    }

    var isDirect: Bool {
        return contains(.IsDirect)
    }

    var isConnectionOnTrafficOrDemand: Bool {
        return isConnectionOnTraffic || isConnectionOnDemand
    }

    var isConnectionRequiredOrTransient: Bool {
        return isConnectionRequired || isTransientConnection
    }

    var isConnected: Bool {
        return isReachable && !isConnectionRequired
    }

    var isOnWWAN: Bool {
        #if os(iOS)
            return contains(.IsWWAN)
        #else
            return false
        #endif
    }

    var isReachableViaWWAN: Bool {
        #if os(iOS)
            return isConnected && isOnWWAN
        #else
            return isReachable
        #endif
    }

    var isReachableViaWiFi: Bool {
        #if os(iOS)
            return isConnected && !isOnWWAN
        #else
            return isConnected
        #endif
    }
}

// swiftlint:enable variable_name
