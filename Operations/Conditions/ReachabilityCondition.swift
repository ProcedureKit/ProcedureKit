//
//  ReachabilityCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import SystemConfiguration

public final class Reachability {

    public enum NetworkStatus: Int {
        case NotConnected = 1, ReachableViaWiFi, ReachableViaWWAN
    }

    public typealias ObserverBlockType = (NetworkStatus) -> Void

    struct Observer {
        let reachabilityDidChange: ObserverBlockType
    }

    public static let sharedInstance = Reachability()

    public class func addObserver(observer: ObserverBlockType) -> String {
        let token = NSUUID().UUIDString
        sharedInstance.addObserverWithToken(token, observer: observer)
        return token
    }

    public class func removeObserverWithToken(token: String) {
        sharedInstance.removeObserverWithToken(token)
    }

    // Instance

    private var refs = [String: SCNetworkReachability]()
    private let queue = Queue.Utility.serial("me.danthorpe.Operations.Reachability")
    private var observers = [String: Observer]()
    private var isRunning = false
    private var defaultRouteReachability: SCNetworkReachability?
    private var previousReachabilityFlags: SCNetworkReachabilityFlags? = .None
    private var timer: dispatch_source_t?
    private lazy var timerQueue: dispatch_queue_t = Queue.Background.concurrent("me.danthorpe.Operations.Reachabiltiy.Timer")

    private var defaultRouteReachabilityFlags: SCNetworkReachabilityFlags? {
        get {
            if let ref = defaultRouteReachability {
                var flags: SCNetworkReachabilityFlags = []
                if SCNetworkReachabilityGetFlags(ref, &flags) != 0 {
                    return flags
                }
            }
            return .None
        }
    }


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
                var status = NetworkStatus.NotConnected
                if let ref = self.refs[host] ?? SCNetworkReachabilityCreateWithName(nil, (host as NSString).UTF8String) {
                    self.refs[host] = ref

                    var flags: SCNetworkReachabilityFlags = []
                    if SCNetworkReachabilityGetFlags(ref, &flags) != 0 {
                        status = self.networkStatusFromFlags(flags)
                    }
                }
                completion(status)
            }
        }
    }

    // Private

    private func startNotifier() {
        guard isRunning == false else { return }
        isRunning = true

        if let _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue) {
            // Fire every 250 milliseconds, with 250 millisecond leeway
            dispatch_source_set_timer(_timer, dispatch_walltime(nil, 0), 250 * NSEC_PER_MSEC, 250 * NSEC_PER_MSEC)
            dispatch_source_set_event_handler(_timer, timerDidFire)
            dispatch_resume(_timer)
            timer = _timer
        }
    }

    private func stopNotifier() {
        guard observers.count == 0 else { return }

        if let _timer = timer {
            dispatch_source_cancel(_timer)
            timer = nil
        }

        isRunning = false
    }

    private func timerDidFire() {
        if let currentReachabiltiyFlags = defaultRouteReachabilityFlags {
            if let previousReachabilityFlags = previousReachabilityFlags {
                if previousReachabilityFlags != currentReachabiltiyFlags {
                    reachabilityFlagsDidChange(currentReachabiltiyFlags)
                }
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
            return .ReachableViaWiFi
        }
        else if isReachableViaWWAN(flags) {
            return .ReachableViaWWAN
        }
        return .NotConnected
    }

    private func isReachable(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.Reachable)
    }

    private func isReachableViaWifi(flags: SCNetworkReachabilityFlags) -> Bool {
        return isReachable(flags) && !flags.contains(.ConnectionRequired)
    }

    private func isReachableViaWWAN(flags: SCNetworkReachabilityFlags) -> Bool {
        return isReachable(flags) && flags.contains(.IsWWAN)
    }
}

internal protocol HostReachability {
    func requestReachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType)
}

extension Reachability: HostReachability {}

/**
A condition that performs a single-shot reachability check.
Reachability is evaluated once when the operation it is
attached to is asked about its readiness.
*/
public class ReachabilityCondition: OperationCondition {

    public enum Connectivity: Int {
        case AnyConnectionKind = 1, ConnectedViaWWAN, ConnectedViaWiFi
    }

    public enum Error: ErrorType, Equatable {
        case NotReachable
        case NotReachableWithConnectivity(Connectivity)
    }

    public static let name = "Reachability"
    public static let isMutuallyExclusive = false

    let url: NSURL
    let connectivity: Connectivity
    let reachability: HostReachability

    public convenience init(url: NSURL, connectivity: Connectivity = .AnyConnectionKind) {
        self.init(url: url, connectivity: connectivity, reachability: Reachability.sharedInstance)
    }

    internal init(url: NSURL, connectivity: Connectivity = .AnyConnectionKind, reachability: HostReachability) {
        self.url = url
        self.connectivity = connectivity
        self.reachability = reachability
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        reachability.requestReachabilityForURL(url) { kind in
            switch (self.connectivity, kind) {
            case (_, .NotConnected):
                completion(.Failed(Error.NotReachable))
            case (.AnyConnectionKind, _), (.ConnectedViaWWAN, _):
                completion(.Satisfied)
            case (.ConnectedViaWiFi, .ReachableViaWWAN):
                completion(.Failed(Error.NotReachableWithConnectivity(self.connectivity)))
            default:
                completion(.Failed(Error.NotReachable))
            }
        }
    }
}

public func ==(a: ReachabilityCondition.Error, b: ReachabilityCondition.Error) -> Bool {
    switch (a, b) {
    case (.NotReachable, .NotReachable):
        return true
    case let (.NotReachableWithConnectivity(aConnectivity), .NotReachableWithConnectivity(bConnectivity)):
        return aConnectivity == bConnectivity
    default: return false
    }
}



