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
    public typealias ObserverBlockType = (NetworkStatus) -> Void

    struct Observer {
        let reachabilityDidChange: ObserverBlockType
    }

    /**
     Add an observer block which will be executed when the network
     status changes.

     - parameter observer, a `ObserverBlockType` block
     - returns: a unique string, which is used to remove the observer.
     */
    public static func addObserver(observer: ObserverBlockType) throws -> String {
        return try __device_reachability_manager.addObserver(observer)
    }

    /**
     Removes a reachability observer.

     - parameter token, a `String` returned from `addObserver:`
     */
    public static func removeObserverWithToken(token: String) {
        return __device_reachability_manager.removeObserverWithToken(token)
    }
}

protocol SystemReachabilityType {
    func addObserver(observer: Reachability.ObserverBlockType) throws -> String
    func removeObserverWithToken(token: String)
}

protocol HostReachabilityType {
    func requestReachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType)
}

protocol NetworkReachabilityDelegate: class {

    func reachabilityDidChange(flags: SCNetworkReachabilityFlags)
}

protocol NetworkReachabilityType {

    weak var delegate: NetworkReachabilityDelegate? { get set }

    func startNotifierOnQueue(queue: dispatch_queue_t) throws -> Bool

    func stopNotifier()
}



final class ReachabilityManager<NetworkReachability: NetworkReachabilityType>: NetworkReachabilityDelegate {

    typealias NetworkStatus = Reachability.NetworkStatus

    let queue = Queue.Utility.serial("me.danthorpe.Operations.Reachability")
    var network: NetworkReachability
    var observersByID = Dictionary<String,Reachability.Observer>()
    var isRunning = false
    var previousReachabilityFlags: SCNetworkReachabilityFlags? = .None

    init(_ network: NetworkReachability) {
        self.network = network
        self.network.delegate = self
    }

    func didAddObserver(observer: Reachability.Observer) throws {
        if !isRunning {
            isRunning = try network.startNotifierOnQueue(queue)
        }
    }

    func didRemoveObserver(observer: Reachability.Observer) {
        if observersByID.isEmpty {
            network.stopNotifier()
            isRunning = false
        }
    }

    func reachabilityDidChange(flags: SCNetworkReachabilityFlags) {
        if let previous = previousReachabilityFlags {
            if previous != flags {
                updateObservers(flags)
            }
        }
        else {
            updateObservers(flags)
        }
        previousReachabilityFlags = flags
    }

    func updateObservers(flags: SCNetworkReachabilityFlags) {
        let networkStatus = NetworkStatus(flags: flags)
        dispatch_async(Queue.Main.queue) { [observers = observersByID] in
            for (_, observer) in observers {
                observer.reachabilityDidChange(networkStatus)
            }
        }
    }
}

extension ReachabilityManager: SystemReachabilityType {

    func addObserver(observer: Reachability.ObserverBlockType) throws -> String {
        return try addObserverWithToken(NSUUID().UUIDString, observer: observer)
    }

    func addObserverWithToken(token: String, observer block: Reachability.ObserverBlockType) throws -> String {
        let observer = Reachability.Observer(reachabilityDidChange: block)
        observersByID.updateValue(observer, forKey: token)
        try didAddObserver(observer)
        return token
    }

    func removeObserverWithToken(token: String) {
        if let observer = observersByID.removeValueForKey(token) {
            didRemoveObserver(observer)
        }
    }
}

extension ReachabilityManager: HostReachabilityType {

    func requestReachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType) {

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
        dispatch_async(queue) {
            let flags = self.getFlagsForReachability(reachability)
            self.reachabilityDidChange(flags)
        }
    }

    func startNotifierOnQueue(queue: dispatch_queue_t) throws -> Bool {
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

        dispatch_async(queue) {
            let flags = self.getFlagsForReachability(reachability)
            self.delegate!.reachabilityDidChange(flags)
        }

        return true
    }

    func stopNotifier() {
        if let reachability = try? defaultRouteReachability() {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)
            SCNetworkReachabilitySetCallback(reachability, nil, nil)
        }
    }
}

private let __device_reachability_manager = ReachabilityManager(DeviceReachability())

private func __device_reachability_callback(reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutablePointer<Void>) {
    let handler = Unmanaged<DeviceReachability>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()

    dispatch_async(Queue.Default.queue) {
        handler.delegate?.reachabilityDidChange(flags)
    }
}













/**
A `Reachability` class, which performs tasks necessary to manage reachability.
*/
public final class Reachability_ {

    public typealias Connectivity = Reachability.Connectivity
    public typealias NetworkStatus = Reachability.NetworkStatus
    public typealias ObserverBlockType = Reachability.ObserverBlockType
    typealias Observer = Reachability.Observer

    public static let sharedInstance = Reachability_()

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


extension Reachability_: SystemReachabilityType {}
extension Reachability_: HostReachabilityType {}

extension Reachability_.NetworkStatus: Equatable { }

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

extension Reachability_.NetworkStatus {

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










