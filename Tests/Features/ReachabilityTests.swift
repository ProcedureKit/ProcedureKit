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

    func test__not_reachable_is_not_connected() {
        let status: Reachability.NetworkStatus = .NotReachable
        XCTAssertFalse(status.isConnected(.AnyConnectionKind))
    }

    func test__reachable_via_wwan_is_not_connected_for_wifi() {
        let status: Reachability.NetworkStatus = .Reachable(.ViaWWAN)
        XCTAssertFalse(status.isConnected(.ViaWiFi))
    }
}

class TestableNetworkReachability {
    typealias Reachability = String

    var didGetDefaultRouteReachability = false
    var _defaultRouteReachability: Reachability = "Default"
    var flags: SCNetworkReachabilityFlags? = .Reachable
    var didStartNotifier = false
    var didStopNotifier = false
    var didGetReachabilityFlagsForHostname = false

    weak var delegate: NetworkReachabilityDelegate?
}

extension TestableNetworkReachability: NetworkReachabilityType {

    func defaultRouteReachability() throws -> Reachability {
        didGetDefaultRouteReachability = true
        return _defaultRouteReachability
    }

    func startNotifierOnQueue(queue: dispatch_queue_t) throws {
        didStartNotifier = true
        if let flags = flags {
            delegate?.reachabilityDidChange(flags)
        }
    }

    func stopNotifier() {
        didStopNotifier = true
    }

    func reachabilityFlagsForHostname(host: String) -> SCNetworkReachabilityFlags? {
        didGetReachabilityFlagsForHostname = true
        return flags
    }
}


class ReachabilityManagerTests: XCTestCase {

    var network: TestableNetworkReachability!
    var manager: ReachabilityManager!

    override func setUp() {
        super.setUp()
        network = TestableNetworkReachability()
        manager = ReachabilityManager(network)
    }
}

class SystemReachabilityManagerTests: ReachabilityManagerTests {

    func test__delegate_is_set() {
        XCTAssertNotNil(network.delegate)
    }

    func test__whenConnected__block_is_run() {
        var blockDidRun = false
        let expectation = expectationWithDescription("Test: \(#function)")
        manager.whenConnected(.AnyConnectionKind) {
            blockDidRun = true
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(3.0, handler: nil)
        XCTAssertTrue(blockDidRun)
        XCTAssertTrue(network.didStopNotifier)
    }
}

class HostReachabilityManagerTests: ReachabilityManagerTests {

    func test__reachabilityForURL__with_no_host__not_reachable() {
        let expectation = expectationWithDescription("Test: \(#function)")
        var receivedStatus: Reachability.NetworkStatus? = .None
        manager.reachabilityForURL(NSURL(string: "http://")!) { status in
            receivedStatus = status
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(3.0, handler: nil)
        XCTAssertEqual(receivedStatus ?? .Reachable(.AnyConnectionKind), .NotReachable)
    }

    func test__reachabilityForURL__without_flags__not_reachable() {
        let expectation = expectationWithDescription("Test: \(#function)")
        var receivedStatus: Reachability.NetworkStatus? = .None
        network.flags = .None
        manager.reachabilityForURL(NSURL(string: "http://apple.com")!) { status in
            receivedStatus = status
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(3.0, handler: nil)
        XCTAssertEqual(receivedStatus ?? .Reachable(.AnyConnectionKind), .NotReachable)
    }

    func test__reachabilityForURL__reachable() {
        let expectation = expectationWithDescription("Test: \(#function)")
        var receivedStatus: Reachability.NetworkStatus? = .None
        manager.reachabilityForURL(NSURL(string: "http://apple.com")!) { status in
            receivedStatus = status
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(3.0, handler: nil)
        XCTAssertEqual(receivedStatus ?? .Reachable(.AnyConnectionKind), .Reachable(.ViaWiFi))
    }
}

class DeviceReachabilityTests: XCTestCase, NetworkReachabilityDelegate {

    let queue: dispatch_queue_t = Queue.Default.serial("me.danthorpe.Operation.Testing")
    var device: DeviceReachability!
    var expectation: XCTestExpectation? = .None
    var delegateDidReceiveFlags: SCNetworkReachabilityFlags? = .None

    override func setUp() {
        super.setUp()
        device = DeviceReachability()
        device.delegate = self
    }

    func test__notifierIsRunning_true_when_running() {
        device.notifierIsRunning = true
        XCTAssertTrue(device.notifierIsRunning)
    }

    func test__notifierIsRunning_false_when_not_running() {
        device.notifierIsRunning = false
        XCTAssertFalse(device.notifierIsRunning)
    }

    func reachabilityDidChange(flags: SCNetworkReachabilityFlags) {
        delegateDidReceiveFlags = flags
        expectation?.fulfill()
    }

    func test__reachabilityForHost() {
        XCTAssertNotNil(device.reachabilityForHost("https://apple.com"))
    }

    func test__reachabilityDidChange_informs_delegate() {
        device.reachabilityDidChange(.Reachable)
        XCTAssertEqual(delegateDidReceiveFlags ?? .ConnectionRequired, .Reachable)
    }

    func test__check() {
        expectation = expectationWithDescription("Test: \(#function)")
        if let reachability = device.reachabilityForHost("https://apple.com") {
            device.check(reachability, queue: queue)
        }
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertNotNil(delegateDidReceiveFlags)
    }

    func test__creates_default_route_reachability() {
        do {
            XCTAssertNil(device.__defaultRouteReachability)
            let _ = try device.defaultRouteReachability()
            XCTAssertNotNil(device.__defaultRouteReachability)
        }
        catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func test__stopNotifier_unschedules_reachability_callbacks_queue() {
        do { try device.startNotifierOnQueue(queue) } catch { XCTFail() }
        device.stopNotifier()
        do { try device.startNotifierOnQueue(queue) } catch { XCTFail() }
    }
}
