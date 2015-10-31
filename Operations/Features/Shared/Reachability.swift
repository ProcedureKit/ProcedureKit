//
//  Reachability.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import SystemConfiguration

public protocol SystemReachability {
    func addObserver(observer: Reachability.ObserverBlockType) -> String
    func removeObserverWithToken(token: String)
}

public protocol HostReachability {
    func requestReachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType)
}

/**
A `Reachability` class, which performs tasks necessary to manage reachability.
*/
public final class Reachability {

    /// The kind of `Reachability` connectivity
    public enum Connectivity {
        case AnyConnectionKind, ViaWWAN, ViaWiFi
    }

    /// The `NetworkStatus`
    public enum NetworkStatus {
        case NotReachable
        case Reachable(Connectivity)
    }

    public typealias ObserverBlockType = (NetworkStatus) -> Void

    struct Observer {
        let reachabilityDidChange: ObserverBlockType
    }

    public static let sharedInstance = Reachability()

    /**
    Add an observer block which will be executed when the network
    status changes.
    
    :param: observer, a `ObserverBlockType` block
    :returns: a unique string, which is used to remove the observer.
    */
    public class func addObserver(observer: ObserverBlockType) -> String {
        return sharedInstance.addObserver(observer)
    }

    /**
    Removes a reachability observer.

    :param: token, a `String` returned from `addObserver:`
    */
    public class func removeObserverWithToken(token: String) {
        sharedInstance.removeObserverWithToken(token)
    }

    // Instance

    private var refs = [String: SCNetworkReachability]()
    private let queue = Queue.Utility.serial("me.danthorpe.Operations.Reachability")
    private let defaultRouteReachability: SCNetworkReachability?
    private var observers = [String: Observer]()
    private var isRunning = false
    private var previousReachabilityFlags: SCNetworkReachabilityFlags? = .None
    private var timer: dispatch_source_t?
    private lazy var timerQueue: dispatch_queue_t = Queue.Background.concurrent("me.danthorpe.Operations.Reachabiltiy.Timer")

    private var defaultRouteReachabilityFlags: SCNetworkReachabilityFlags? {
        get {
            if let ref = defaultRouteReachability {
                var flags: SCNetworkReachabilityFlags = []
                if SCNetworkReachabilityGetFlags(ref, &flags) {
                    return flags
                }
            }
            return .None
        }
    }

    private var recentNetworkStatus: NetworkStatus? {
        return previousReachabilityFlags.map { NetworkStatus(flags: $0) }
    }

    private let isPhoneDevice: Bool = {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return false
        #else
            return true
        #endif
    }()

    private init() {

        defaultRouteReachability = {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            return withUnsafePointer(&zeroAddress) {
                SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
            }
        }()
    }

    public func addObserver(observer: ObserverBlockType) -> String {
        let token = NSUUID().UUIDString
        addObserverWithToken(token, observer: observer)
        return token
    }

    public func addObserverWithToken(token: String, observer block: ObserverBlockType) {
        let observer = Observer(reachabilityDidChange: block)
        observers.updateValue(observer, forKey: token)
        didAddObserver(observer)
        startNotifier()
    }

    public func removeObserverWithToken(token: String) {
        observers.removeValueForKey(token)
        stopNotifier()
    }

    public func requestReachabilityForURL(url: NSURL, completion: ObserverBlockType) {
        if let host = url.host {
            dispatch_async(queue) {
                var status = NetworkStatus.NotReachable
                if let ref = self.refs[host] ?? SCNetworkReachabilityCreateWithName(nil, (host as NSString).UTF8String) {
                    self.refs[host] = ref

                    var flags: SCNetworkReachabilityFlags = []
                    if SCNetworkReachabilityGetFlags(ref, &flags) {
                        status = NetworkStatus(flags: flags)
                    }
                }
                completion(status)
            }
        }
    }

    // Private

    private func startNotifier() {
        if !isRunning {
            if let _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue) {
                // Fire every 250 milliseconds, with 250 millisecond leeway
                dispatch_source_set_timer(_timer, dispatch_walltime(nil, 0), 250 * NSEC_PER_MSEC, 250 * NSEC_PER_MSEC)
                dispatch_source_set_event_handler(_timer, timerDidFire)
                dispatch_resume(_timer)
                timer = _timer
            }
            isRunning = true
//            print(">> [Reachability]: Started.")
        }
    }

    private func stopNotifier() {
        if observers.count == 0 {
            if let _timer = timer {
                dispatch_source_cancel(_timer)
                timer = nil
                previousReachabilityFlags = .None
            }
            isRunning = false
//            print(">> [Reachability]: Stopped.")
        }
    }

    private func didAddObserver(observer: Observer) {
        if let networkStatus = recentNetworkStatus {
            dispatch_async(Queue.Main.queue) {
                observer.reachabilityDidChange(networkStatus)
            }
        }
    }

    private func timerDidFire() {
        if let currentReachabiltiyFlags = defaultRouteReachabilityFlags {
            if let previousReachabilityFlags = previousReachabilityFlags {
                if previousReachabilityFlags != currentReachabiltiyFlags {
                    reachabilityFlagsDidChange(currentReachabiltiyFlags)
                }
            }
            else {
                reachabilityFlagsDidChange(currentReachabiltiyFlags)
            }
            previousReachabilityFlags = currentReachabiltiyFlags
        }
    }

    private func reachabilityFlagsDidChange(flags: SCNetworkReachabilityFlags) {
        let networkStatus = NetworkStatus(flags: flags)
        dispatch_async(Queue.Main.queue) {
            for (_, observer) in self.observers {
                observer.reachabilityDidChange(networkStatus)
            }
        }
    }
}


extension Reachability: SystemReachability {}
extension Reachability: HostReachability {}

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










