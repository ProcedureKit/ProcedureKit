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
    public enum Error: ErrorProtocol {
        case failedToCreateDefaultRouteReachability
        case failedToSetNotifierCallback
        case failedToSetDispatchQueue
    }

    /// The kind of `Reachability` connectivity
    public enum Connectivity {
        case anyConnectionKind, viaWWAN, viaWiFi
    }

    /// The `NetworkStatus`
    public enum NetworkStatus {
        case notReachable
        case reachable(Connectivity)
    }

    /// The ObserverBlockType
    public typealias ObserverBlockType = (NetworkStatus) -> Void

    struct Observer {
        let connectivity: Connectivity
        let whenConnectedBlock: () -> Void
    }
}

protocol NetworkReachabilityDelegate: class {

    func reachabilityDidChange(_ flags: SCNetworkReachabilityFlags)
}

protocol NetworkReachabilityType {

    weak var delegate: NetworkReachabilityDelegate? { get set }

    func startNotifierOnQueue(_ queue: DispatchQueue) throws

    func stopNotifier()

    func reachabilityFlagsForHostname(_ host: String) -> SCNetworkReachabilityFlags?
}

protocol ReachabilityManagerType {

    init(_ network: NetworkReachabilityType)
}

protocol SystemReachabilityType: ReachabilityManagerType {

    func whenConnected(_ conn: Reachability.Connectivity, block: () -> Void)
}

protocol HostReachabilityType: ReachabilityManagerType {

    func reachabilityForURL(_ url: URL, completion: Reachability.ObserverBlockType)
}

final class ReachabilityManager {
    typealias Status = Reachability.NetworkStatus

    static let sharedInstance = ReachabilityManager(DeviceReachability())

    let queue = Queue.utility.serial("me.danthorpe.Operations.Reachability")
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

    func reachabilityDidChange(_ flags: SCNetworkReachabilityFlags) {

        let status = Status(flags: flags)
        let observersToCheck = _observers.read { $0 }

        _observers.write { (mutableObservers: inout Array<Reachability.Observer>) in
            mutableObservers = observersToCheck.filter { observer in
                let shouldRemove = status.isConnected(observer.connectivity)
                if shouldRemove {
                    Queue.main.queue.async(execute: observer.whenConnectedBlock)
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
    func whenConnected(_ conn: Reachability.Connectivity, block: () -> Void) {
        _observers.write({ (mutableObservers: inout [Reachability.Observer]) in
            mutableObservers.append(Reachability.Observer(connectivity: conn, whenConnectedBlock: block))
        }, completion: { try! self.network.startNotifierOnQueue(self.queue) })
    }
    // swiftlint:enable force_try
}

extension ReachabilityManager: HostReachabilityType {

    func reachabilityForURL(_ url: URL, completion: Reachability.ObserverBlockType) {

        queue.async { [reachabilityFlagsForHostname = network.reachabilityFlagsForHostname] in
            if let host = url.host, let flags = reachabilityFlagsForHostname(host) {
                completion(Status(flags: flags))
            }
            else {
                completion(.notReachable)
            }
        }
    }
}

class DeviceReachability: NetworkReachabilityType {

    typealias Error = Reachability.Error

    var __defaultRouteReachability: SCNetworkReachability? = .none
    var threadSafeProtector = Protector(false)
    weak var delegate: NetworkReachabilityDelegate?

    var notifierIsRunning: Bool {
        get { return threadSafeProtector.read { $0 } }
        set {
            threadSafeProtector.write { (isRunning: inout Bool) in
                isRunning = newValue
            }
        }
    }

    init() { }

    @discardableResult
    func defaultRouteReachability() throws -> SCNetworkReachability {

        if let reachability = __defaultRouteReachability { return reachability }

        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let reachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else { throw Error.failedToCreateDefaultRouteReachability }

        __defaultRouteReachability = reachability
        return reachability
    }

    func reachabilityForHost(_ host: String) -> SCNetworkReachability? {
        return SCNetworkReachabilityCreateWithName(nil, (host as NSString).utf8String!)
    }

    func getFlagsForReachability(_ reachability: SCNetworkReachability) -> SCNetworkReachabilityFlags {
        var flags = SCNetworkReachabilityFlags()
        guard withUnsafeMutablePointer(&flags, {
            SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0))
        }) else { return SCNetworkReachabilityFlags() }

        return flags
    }

    func reachabilityDidChange(_ flags: SCNetworkReachabilityFlags) {
        delegate?.reachabilityDidChange(flags)
    }

    func check(_ reachability: SCNetworkReachability, queue: DispatchQueue) {
        queue.async { [weak self] in
            if let delegate = self?.delegate, let flags = self?.getFlagsForReachability(reachability) {
                delegate.reachabilityDidChange(flags)
            }
        }
    }

    func startNotifierOnQueue(_ queue: DispatchQueue) throws {
        assert(delegate != nil, "Reachability Delegate not set.")
        let reachability = try defaultRouteReachability()
        if !notifierIsRunning {
            notifierIsRunning = true
            var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
            context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())

            guard SCNetworkReachabilitySetCallback(reachability, __device_reachability_callback, &context) else {
                stopNotifier()
                throw Error.failedToSetNotifierCallback
            }

            guard SCNetworkReachabilitySetDispatchQueue(reachability, queue) else {
                stopNotifier()
                throw Error.failedToSetDispatchQueue
            }
        }
        check(reachability, queue: queue)
    }

    func stopNotifier() {
        if let reachability = try? defaultRouteReachability() {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue)
            SCNetworkReachabilitySetCallback(reachability, nil, nil)
        }
        notifierIsRunning = false
    }

    func reachabilityFlagsForHostname(_ host: String) -> SCNetworkReachabilityFlags? {
        guard let reachability = reachabilityForHost(host) else { return .none }
        return getFlagsForReachability(reachability)
    }
}

private func __device_reachability_callback(_ reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>?) {
    guard let info = info else { return }

    let handler = Unmanaged<DeviceReachability>.fromOpaque(info).takeUnretainedValue()
    Queue.default.queue.async {
        handler.delegate?.reachabilityDidChange(flags)
    }
}

extension Reachability.NetworkStatus: Equatable { }

public func == (lhs: Reachability.NetworkStatus, rhs: Reachability.NetworkStatus) -> Bool {
    switch (lhs, rhs) {
    case (.notReachable, .notReachable):
        return true
    case let (.reachable(aConnectivity), .reachable(bConnectivity)):
        return aConnectivity == bConnectivity
    default:
        return false
    }
}

extension Reachability.NetworkStatus {

    public init(flags: SCNetworkReachabilityFlags) {
        if flags.isReachableViaWiFi {
            self = .reachable(.viaWiFi)
        }
        else if flags.isReachableViaWWAN {
            #if os(iOS)
            self = .reachable(.viaWWAN)
            #else
            self = .reachable(.anyConnectionKind)
            #endif
        }
        else {
            self = .notReachable
        }
    }

    func isConnected(_ target: Reachability.Connectivity) -> Bool {
        switch (self, target) {
        case (.notReachable, _):
            return false
        case (.reachable(.viaWWAN), .viaWiFi):
            return false
        case (.reachable(_), _):
            return true
        }
    }
}

// MARK: - Conformance

extension SCNetworkReachabilityFlags {

    var isReachable: Bool {
        return contains(.reachable)
    }

    var isConnectionRequired: Bool {
        return contains(.connectionRequired)
    }

    var isInterventionRequired: Bool {
        return contains(.interventionRequired)
    }

    var isConnectionOnTraffic: Bool {
        return contains(.connectionOnTraffic)
    }

    var isConnectionOnDemand: Bool {
        return contains(.connectionOnDemand)
    }

    var isTransientConnection: Bool {
        return contains(.transientConnection)
    }

    var isLocalAddress: Bool {
        return contains(.isLocalAddress)
    }

    var isDirect: Bool {
        return contains(.isDirect)
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
            return contains(.isWWAN)
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
