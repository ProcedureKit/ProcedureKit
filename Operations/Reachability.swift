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

public final class Reachability {

    public enum Connectivity {
        case AnyConnectionKind, ViaWWAN, ViaWiFi
    }

    public enum NetworkStatus {
        case NotReachable
        case Reachable(Connectivity)
    }

    public typealias ObserverBlockType = (NetworkStatus) -> Void

    struct Observer {
        let reachabilityDidChange: ObserverBlockType
    }

    public static let sharedInstance = Reachability()

    public class func addObserver(observer: ObserverBlockType) -> String {
        return sharedInstance.addObserver(observer)
    }

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
                var flags: SCNetworkReachabilityFlags = 0
                if SCNetworkReachabilityGetFlags(ref, &flags) != 0 {
                    return flags
                }
            }
            return .None
        }
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
                SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
            }
        }()
    }

    public func addObserver(observer: ObserverBlockType) -> String {
        let token = NSUUID().UUIDString
        addObserverWithToken(token, observer: observer)
        return token
    }

    public func addObserverWithToken(token: String, observer: ObserverBlockType) {
        observers.updateValue(Observer(reachabilityDidChange: observer), forKey: token)
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
                let ref = self.refs[host] ?? SCNetworkReachabilityCreateWithName(nil, (host as NSString).UTF8String).takeRetainedValue()

                self.refs[host] = ref

                var flags: SCNetworkReachabilityFlags = 0
                if SCNetworkReachabilityGetFlags(ref, &flags) != 0 {
                    status = self.networkStatusFromFlags(flags)
                }

                completion(status)
            }
        }
    }

    // Private

    private func startNotifier() {
        if !isRunning {
            isRunning = true

            if let _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue) {
                // Fire every 250 milliseconds, with 250 millisecond leeway
                dispatch_source_set_timer(_timer, dispatch_walltime(nil, 0), 250 * NSEC_PER_MSEC, 250 * NSEC_PER_MSEC)
                dispatch_source_set_event_handler(_timer, timerDidFire)
                dispatch_resume(_timer)
                timer = _timer
            }
        }
    }

    private func stopNotifier() {
        if observers.count == 0 {
            if let _timer = timer {
                dispatch_source_cancel(_timer)
                timer = nil
            }
            isRunning = false
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
        let networkStatus = networkStatusFromFlags(flags)
        dispatch_async(Queue.Main.queue) {
            for (_, observer) in self.observers {
                observer.reachabilityDidChange(networkStatus)
            }
        }
    }

    private func networkStatusFromFlags(flags: SCNetworkReachabilityFlags) -> NetworkStatus {
        if isReachableViaWifi(flags) {
            return .Reachable(.ViaWiFi)
        }
        else if isReachableViaWWAN(flags) {
            return .Reachable(.ViaWWAN)
        }
        return .NotReachable
    }

    private func isReachableViaWifi(flags: SCNetworkReachabilityFlags) -> Bool {
        if !isReachable(flags) {
            return false
        }

        if isConnectionRequiredOrTransient(flags) {
            return false
        }

        if isOnWWAN(flags) {
            return false
        }

        return true
    }

    private func isReachableViaWWAN(flags: SCNetworkReachabilityFlags) -> Bool {
        if !isReachable(flags) {
            return false
        }

        return isOnWWAN(flags)
    }

    private func isOnWWAN(flags: SCNetworkReachabilityFlags) -> Bool {
        #if os(iOS)
            return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsIsWWAN) != 0
            #else
            return false
        #endif
    }

    private func isReachable(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsReachable) != 0
    }
    private func isConnectionRequired(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionRequired) != 0
    }
    private func isInterventionRequired(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsInterventionRequired) != 0
    }
    private func isConnectionOnTraffic(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0
    }
    private func isConnectionOnDemand(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionOnDemand) != 0
    }
    func isConnectionOnTrafficOrDemand(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionOnTraffic | kSCNetworkReachabilityFlagsConnectionOnDemand) != 0
    }
    private func isTransientConnection(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsTransientConnection) != 0
    }
    private func isLocalAddress(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsIsLocalAddress) != 0
    }
    private func isDirect(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsIsDirect) != 0
    }
    private func isConnectionRequiredOrTransient(flags: SCNetworkReachabilityFlags) -> Bool {
        let testcase = SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionRequired | kSCNetworkReachabilityFlagsTransientConnection)
        return flags & testcase == testcase
    }
}


extension Reachability: SystemReachability {}
extension Reachability: HostReachability {}

extension Reachability.NetworkStatus: Printable {

    public var description: String {
        switch self {
        case .NotReachable:
            return ".NotReachable"
        case .Reachable(.ViaWiFi):
            return ".Reachable(.ViaWifi)"
        case .Reachable(.ViaWWAN):
            return ".Reachable(.ViaWWAN)"
        case .Reachable(_):
            return ".Reachable other"
        }
    }
}


