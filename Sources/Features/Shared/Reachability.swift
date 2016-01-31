//
//  Reachability.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import SystemConfiguration

public struct Reachability {

    /// Errors which can be thrown or returned.
    public enum Error: ErrorType {
        case FailedToCreateDefaultRouteReachability
        case FailedToSetNotifierCallback
        case FailedToScheduleNotifier
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

    typealias ReachabilityDidChange = SCNetworkReachabilityFlags -> Void

    struct Observer {
        let reachabilityDidChange: ObserverBlockType
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

    func whenConnected(conn: Reachability.Connectivity, block: dispatch_block_t)
}

protocol HostReachabilityType: ReachabilityManagerType {

    func reachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType)
}



final class ReachabilityManager {

    typealias Status = Reachability.NetworkStatus

    let queue = Queue.Utility.serial("me.danthorpe.Operations.Reachability")
    var whenConnectedBlock: dispatch_block_t? = .None
    var connectivity: Reachability.Connectivity = .AnyConnectionKind
    var network: NetworkReachabilityType

    required init(_ net: NetworkReachabilityType) {
        network = net
    }
}

extension ReachabilityManager: NetworkReachabilityDelegate {

    func reachabilityDidChange(flags: SCNetworkReachabilityFlags) {
        guard let block = whenConnectedBlock else { return }
        let status = Status(flags: flags)
        if status.isConnected(connectivity) {
            network.stopNotifier()
            dispatch_async(Queue.Main.queue, block)
        }
    }
}

extension ReachabilityManager: SystemReachabilityType {

    func whenConnected(conn: Reachability.Connectivity, block: dispatch_block_t) {
        connectivity = conn
        whenConnectedBlock = block
        network.delegate = self
        try! network.startNotifierOnQueue(queue)
    }
}

extension ReachabilityManager: HostReachabilityType {

    func reachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType) {

        dispatch_async(queue) { [reachabilityFlagsForHostname = network.reachabilityFlagsForHostname] in
            if let host = url.host, flags = reachabilityFlagsForHostname(host) {
                completion(Reachability.NetworkStatus(flags: flags))
            }
            else {
                completion(.NotReachable)
            }
        }
    }
}

class DeviceReachability: NetworkReachabilityType {

    typealias Error = Reachability.Error

    private var __defaultRouteReachability: SCNetworkReachability? = .None

    weak var delegate: NetworkReachabilityDelegate?

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

        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque())

        guard SCNetworkReachabilitySetCallback(reachability, __device_reachability_callback, &context) else {
            throw Error.FailedToSetNotifierCallback
        }

        guard SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes) else {
            throw Error.FailedToScheduleNotifier
        }

        check(reachability, queue: queue)
    }

    func stopNotifier() {
        if let reachability = try? defaultRouteReachability() {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)
            SCNetworkReachabilitySetCallback(reachability, nil, nil)
        }
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

public func ==(a: Reachability.NetworkStatus, b: Reachability.NetworkStatus) -> Bool {
    switch (a, b) {
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

    var isConnectionOnTrafficOrDemand: Bool {
        return isConnectionOnTraffic || isConnectionOnDemand
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

    var isConnectionRequiredOrTransient: Bool {
        return isConnectionRequired || isTransientConnection
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
            return isReachable && isOnWWAN
        #else
            return isReachable
        #endif
    }

    var isReachableViaWiFi: Bool {
        #if os(iOS)
            return !(!isReachable || isConnectionRequiredOrTransient || isOnWWAN)
        #else
            return !(!isReachable || isConnectionRequiredOrTransient)
        #endif
    }
}










