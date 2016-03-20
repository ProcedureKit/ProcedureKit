//
//  ReachabilityCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

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
    var reachability: HostReachabilityType = ReachabilityManager(DeviceReachability())

    public init(url: NSURL, connectivity: Reachability.Connectivity = .AnyConnectionKind) {
        self.url = url
        self.connectivity = connectivity
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        reachability.reachabilityForURL(url) { status in
            switch (self.connectivity, status) {
            case (.AnyConnectionKind, .Reachable(_)), (.ViaWWAN, .Reachable(_)), (.ViaWiFi, .Reachable(.ViaWiFi)):
                completion(.Satisfied)
            case (.ViaWiFi, .Reachable(.ViaWWAN)):
                completion(.Failed(Error.NotReachableWithConnectivity(self.connectivity)))
            default:
                completion(.Failed(Error.NotReachable))
            }
        }
    }
}

public func == (lhs: ReachabilityCondition.Error, rhs: ReachabilityCondition.Error) -> Bool {
    switch (lhs, rhs) {
    case (.NotReachable, .NotReachable):
        return true
    case let (.NotReachableWithConnectivity(aConnectivity), .NotReachableWithConnectivity(bConnectivity)):
        return aConnectivity == bConnectivity
    default:
        return false
    }
}
