//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

#if !os(watchOS)

import Foundation
import Dispatch
import SystemConfiguration

// MARK: - Public APIs

public struct Reachability {

    public enum Connectivity {
        case any, wwan, wifi
    }

    public enum NetworkStatus: Equatable {
        case notReachable
        case reachable(Connectivity)
    }

    public typealias ObserverBlock = (NetworkStatus) -> Void

    public struct Observer {
        public let connectivity: Connectivity
        public let didConnectBlock: () -> Void

        public init(connectivity: Connectivity, didConnectBlock: @escaping () -> Void) {
            self.connectivity = connectivity
            self.didConnectBlock = didConnectBlock
        }
    }
}

public enum ReachabilityError: Error {
    case failedToCreateDefaultRouteReachability
    case failedToSetNotifierCallback
    case failedToSetNotifierDispatchQueue
}

public protocol NetworkReachabilityDelegate: class {

    func didChangeReachability(flags: SCNetworkReachabilityFlags)
}

public protocol NetworkReachability {

    var delegate: NetworkReachabilityDelegate? { get set }

    func startNotifier(onQueue queue: DispatchQueue) throws

    func stopNotifier()

    //func reachabilityFlags(of: URL) -> SCNetworkReachabilityFlags?
}

public protocol SystemReachability {

    func whenReachable(via: Reachability.Connectivity, block: @escaping () -> Void)

    func reachability(of: URL, block: @escaping (Reachability.NetworkStatus) -> Void)
}

// MARK: Conformance

public extension Reachability.NetworkStatus {

    init(flags: SCNetworkReachabilityFlags) {
        switch flags {
        case _ where flags.isReachableViaWiFi:
            self = .reachable(.wifi)
        case _ where flags.isReachableViaWWAN:
            #if os(iOS)
                self = .reachable(.wwan)
            #else
                self = .reachable(.any)
            #endif
        default:
            self = .notReachable
        }
    }

    func isConnected(via connectivity: Reachability.Connectivity) -> Bool {
        switch (self, connectivity) {
        case (.notReachable, _), (.reachable(.wwan), .wifi):
            return false
        default:
            return true
        }
    }
}

public extension SCNetworkReachabilityFlags {

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

    var isALocalAddress: Bool {
        return contains(.isLocalAddress)
    }

    var isDirectConnection: Bool {
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

#endif
