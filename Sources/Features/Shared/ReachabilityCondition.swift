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
public class ReachabilityCondition: Condition {

    public enum Error: ErrorProtocol, Equatable {
        case notReachable
        case notReachableWithConnectivity(Reachability.Connectivity)
    }

    let url: URL
    let connectivity: Reachability.Connectivity
    var reachability: HostReachabilityType = ReachabilityManager(DeviceReachability())

    public init(url: URL, connectivity: Reachability.Connectivity = .anyConnectionKind) {
        self.url = url
        self.connectivity = connectivity
        super.init()
        name = "Reachability"
    }

    public override func evaluate(_ operation: OldOperation, completion: (OperationConditionResult) -> Void) {
        reachability.reachabilityForURL(url) { status in
            switch (self.connectivity, status) {
            case (.anyConnectionKind, .reachable(_)), (.viaWWAN, .reachable(_)), (.viaWiFi, .reachable(.viaWiFi)):
                completion(.satisfied)
            case (.viaWiFi, .reachable(.viaWWAN)):
                completion(.failed(Error.notReachableWithConnectivity(self.connectivity)))
            default:
                completion(.failed(Error.notReachable))
            }
        }
    }
}

public func == (lhs: ReachabilityCondition.Error, rhs: ReachabilityCondition.Error) -> Bool {
    switch (lhs, rhs) {
    case (.notReachable, .notReachable):
        return true
    case let (.notReachableWithConnectivity(aConnectivity), .notReachableWithConnectivity(bConnectivity)):
        return aConnectivity == bConnectivity
    default:
        return false
    }
}
