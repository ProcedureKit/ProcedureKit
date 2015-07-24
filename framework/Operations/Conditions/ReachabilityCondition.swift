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
    private var observers = [String: Observer]()
    private var isRunning = false
    private var defaultRouteReachability: SCNetworkReachability?
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

    private func isReachable(flags: SCNetworkReachabilityFlags) -> Bool {
//        return flags.contains(.Reachable) // Swift 2.0
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsReachable) != 0
    }

    private func isConnectionRequired(flags: SCNetworkReachabilityFlags) -> Bool {
        return flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsConnectionRequired) != 0
    }

    private func isReachableViaWifi(flags: SCNetworkReachabilityFlags) -> Bool {
//        return isReachable(flags) && !flags.contains(.ConnectionRequired) // Swift 2.0
        return isReachable(flags) && !isConnectionRequired(flags)
    }

    private func isReachableViaWWAN(flags: SCNetworkReachabilityFlags) -> Bool {
//        return isReachable(flags) && flags.contains(.IsWWAN) // Swift 2.0
        return isReachable(flags) && (flags & SCNetworkReachabilityFlags(kSCNetworkReachabilityFlagsIsWWAN) != 0)
    }
}

public protocol SystemReachability {
    func addObserver(observer: Reachability.ObserverBlockType) -> String
    func removeObserverWithToken(token: String)
}

public protocol HostReachability {
    func requestReachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType)
}

extension Reachability: SystemReachability {}
extension Reachability: HostReachability {}

/**
A condition that performs a single-shot reachability check.
Reachability is evaluated once when the operation it is
attached to is asked about its readiness.
*/
public class ReachabilityCondition: OperationCondition {

    public enum Error: ErrorType, Equatable {
        case NotReachable
        case NotReachableWithConnectivity(Reachability.Connectivity)
    }

    public let name = "Reachability"
    public let isMutuallyExclusive = false

    let url: NSURL
    let connectivity: Reachability.Connectivity
    let reachability: HostReachability

    public convenience init(url: NSURL, connectivity: Reachability.Connectivity = .AnyConnectionKind) {
        self.init(url: url, connectivity: connectivity, reachability: Reachability.sharedInstance)
    }

    public init(url: NSURL, connectivity: Reachability.Connectivity = .AnyConnectionKind, reachability: HostReachability) {
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
            case (_, .NotReachable):
                completion(.Failed(Error.NotReachable))
            case (.AnyConnectionKind, _), (.ViaWWAN, _):
                completion(.Satisfied)
            case (.ViaWiFi, .Reachable(.ViaWWAN)):
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



