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

    func test__flags_isOnWWAN() {
        #if os(iOS)
            flags = .IsWWAN
            XCTAssertTrue(flags.isOnWWAN)
        #else
            flags = .Reachable
            XCTAssertFalse(flags.isOnWWAN)
        #endif
    }

    func test__flags_isReachableViaWifi_true_when_Reachable() {
        flags = .Reachable
        XCTAssertTrue(flags.isReachableViaWiFi)
    }

    func test__flags_isReachableViaWiFi_false_when_Reachable_but_ConnectionRequired() {
        flags = [ .Reachable, .ConnectionRequired ]
        XCTAssertFalse(flags.isReachableViaWiFi)
    }

    func test__flags_isReachableViaWWAN() {
        #if os(iOS)
            flags = [ .Reachable, .IsWWAN ]
            XCTAssertTrue(flags.isReachableViaWWAN)
        #else
            flags = .Reachable
            XCTAssertTrue(flags.isReachableViaWWAN)
        #endif
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
        #if os(iOS)
            flags = [ .Reachable, .IsWWAN ]
            XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.Reachable(.ViaWWAN))
        #endif
    }

    func test__init_flags__not_reachable() {
        flags = [ .ConnectionRequired ]
        XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.NotReachable)
    }
}

class TestableNetworkReachability {
    typealias Reachability = String

    var didGetDefaultRouteReachability = false
    var _defaultRouteReachability: Reachability = "Default"

    var flags: SCNetworkReachabilityFlags = .Reachable

    var didStartNotifier = false
    var didStopNotifier = false

    weak var delegate: NetworkReachabilityDelegate?
}

extension TestableNetworkReachability: NetworkReachabilityType {

    func defaultRouteReachability() throws -> Reachability {
        didGetDefaultRouteReachability = true
        return _defaultRouteReachability
    }

    func startNotifierOnQueue(queue: dispatch_queue_t) throws -> Bool {
        didStartNotifier = true
        delegate?.reachabilityDidChange(flags)
        return true
    }

    func stopNotifier() {
        didStopNotifier = true
    }
}


class ReachabilityManagerTests: XCTestCase {

    var network: TestableNetworkReachability!
    var manager: ReachabilityManager<TestableNetworkReachability>!

    override func setUp() {
        super.setUp()
        network = TestableNetworkReachability()
        manager = ReachabilityManager(network)
    }

    func test__add_observer_new_observer_is_added() {
        let token = try! manager.addObserver { _ in }
        XCTAssertNotNil(manager.observersByID[token])
        XCTAssertTrue(network.didStartNotifier)
    }

    func test__remove_observer_observer_is_removed() {
        let token = try! manager.addObserver { _ in }
        manager.removeObserverWithToken(token)
        XCTAssertNil(manager.observersByID[token])
        XCTAssertTrue(network.didStopNotifier)
        XCTAssertFalse(manager.isRunning)
    }

    func test__add_observer_starts_notifier() {
        try! manager.addObserver { _ in }
        XCTAssertTrue(manager.isRunning)
    }

    func test__notifier_is_only_stopped_when_last_observer_is_removed() {
        let token1 = try! manager.addObserver { _ in }
        XCTAssertTrue(manager.isRunning)
        XCTAssertTrue(network.didStartNotifier)
        let token2 = try! manager.addObserver { _ in }
        manager.removeObserverWithToken(token1)
        XCTAssertFalse(network.didStopNotifier)
        manager.removeObserverWithToken(token2)
        XCTAssertTrue(network.didStopNotifier)
        XCTAssertFalse(manager.isRunning)
    }

    func test__add_observer_triggers_observer_callback() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var networkStatus: Reachability.NetworkStatus? = .None
        let _ = try! manager.addObserver { status in
            networkStatus = status
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertNotNil(networkStatus)
        XCTAssertNotEqual(networkStatus, Reachability.NetworkStatus.NotReachable)
    }
}



