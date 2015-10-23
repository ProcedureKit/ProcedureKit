//
//  ReachabilityTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 23/10/2015.
//  Copyright © 2015 Dan Thorpe. All rights reserved.
//

import Foundation
import SystemConfiguration
import XCTest
@testable import Operations

class SCNetworkReachabilityFlagsTests: XCTestCase {

    var flags: SCNetworkReachabilityFlags!

    func test__flags_is_reachable() {
        flags = .Reachable
        XCTAssertTrue(flags.isReachable)
    }

    func test__flags_isConnectionRequired() {
        flags = .ConnectionRequired
        XCTAssertTrue(flags.isConnectionRequired)
    }

    func test__flags_isInterventionRequired() {
        flags = .InterventionRequired
        XCTAssertTrue(flags.isInterventionRequired)
    }

    func test__flags_isConnectionOnTraffic() {
        flags = .ConnectionOnTraffic
        XCTAssertTrue(flags.isConnectionOnTraffic)
    }

    func test__flags_isConnectionOnDemand() {
        flags = .ConnectionOnDemand
        XCTAssertTrue(flags.isConnectionOnDemand)
    }

    func test__flags_isConnectionOnTrafficOrDemand_when_onTraffic() {
        flags = .ConnectionOnTraffic
        XCTAssertTrue(flags.isConnectionOnTrafficOrDemand)
    }

    func test__flags_isConnectionOnTrafficOrDemand_when_onDemand() {
        flags = .ConnectionOnDemand
        XCTAssertTrue(flags.isConnectionOnTrafficOrDemand)
    }

    func test__flags_isTransientConnection() {
        flags = .TransientConnection
        XCTAssertTrue(flags.isTransientConnection)
    }

    func test__flags_isLocalAddress() {
        flags = .IsLocalAddress
        XCTAssertTrue(flags.isLocalAddress)
    }

    func test__flags_isDirect() {
        flags = .IsDirect
        XCTAssertTrue(flags.isDirect)
    }

    func test__flags_isConnectionRequiredOrTransient_whenRequired() {
        flags = .ConnectionRequired
        XCTAssertTrue(flags.isConnectionRequiredOrTransient)
    }

    func test__flags_isConnectionRequiredOrTransient_whenTransient() {
        flags = .TransientConnection
        XCTAssertTrue(flags.isConnectionRequiredOrTransient)
    }

    @available(iOS 8.0, *)
    func test__flags_isOnWWAN() {
        flags = .IsWWAN
        XCTAssertTrue(flags.isOnWWAN)
    }

    @available(iOS 8.0, *)
    func test__flags_isReachableViaWifi_true_when_Reachable() {
        flags = .Reachable
        XCTAssertTrue(flags.isReachableViaWiFi)
    }

    @available(iOS 8.0, *)
    func test__flags_isReachableViaWiFi_false_when_Reachable_but_ConnectionRequired() {
        flags = [ .Reachable, .ConnectionRequired ]
        XCTAssertFalse(flags.isReachableViaWiFi)
    }

    @available(iOS 8.0, *)
    func test__flags_isReachableViaWWAN() {
        flags = [ .Reachable, .IsWWAN ]
        XCTAssertTrue(flags.isReachableViaWWAN)
    }
}


class NetworkStatusTests: XCTestCase {

    var flags: SCNetworkReachabilityFlags!

    func test__equality() {
        XCTAssertEqual(Reachability.NetworkStatus.Reachable(.AnyConnectionKind), Reachability.NetworkStatus.Reachable(.AnyConnectionKind))
        XCTAssertEqual(Reachability.NetworkStatus.Reachable(.ViaWiFi), Reachability.NetworkStatus.Reachable(.ViaWiFi))
        XCTAssertEqual(Reachability.NetworkStatus.Reachable(.ViaWWAN), Reachability.NetworkStatus.Reachable(.ViaWWAN))
        XCTAssertEqual(Reachability.NetworkStatus.NotReachable, Reachability.NetworkStatus.NotReachable)
        XCTAssertNotEqual(Reachability.NetworkStatus.Reachable(.AnyConnectionKind), Reachability.NetworkStatus.Reachable(.ViaWiFi))
        XCTAssertNotEqual(Reachability.NetworkStatus.Reachable(.ViaWiFi), Reachability.NetworkStatus.Reachable(.ViaWWAN))
        XCTAssertNotEqual(Reachability.NetworkStatus.Reachable(.ViaWWAN), Reachability.NetworkStatus.Reachable(.ViaWiFi))
        XCTAssertNotEqual(Reachability.NetworkStatus.NotReachable, Reachability.NetworkStatus.Reachable(.AnyConnectionKind))

    }

    func test__init_flags__reachable_via_wifi() {
        flags = [ .Reachable ]
        XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.Reachable(.ViaWiFi))
    }

    func test__init_flags__reachable_via_wwan() {
        flags = [ .Reachable, .IsWWAN ]
        XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.Reachable(.ViaWWAN))
    }

    func test__init_flags__reachable() {
        flags = [ .Reachable, .TransientConnection ]
        XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.Reachable(.AnyConnectionKind))
    }

    func test__init_flags__not_reachable() {
        flags = [ .ConnectionRequired ]
        XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.NotReachable)
    }
}



