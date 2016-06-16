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
        flags = .reachable
        XCTAssertTrue(flags.isReachable)
    }

    func test__flags_isConnectionRequired() {
        flags = .connectionRequired
        XCTAssertTrue(flags.isConnectionRequired)
    }

    func test__flags_isInterventionRequired() {
        flags = .interventionRequired
        XCTAssertTrue(flags.isInterventionRequired)
    }

    func test__flags_isConnectionOnTraffic() {
        flags = .connectionOnTraffic
        XCTAssertTrue(flags.isConnectionOnTraffic)
    }

    func test__flags_isConnectionOnDemand() {
        flags = .connectionOnDemand
        XCTAssertTrue(flags.isConnectionOnDemand)
    }

    func test__flags_isConnectionOnTrafficOrDemand_when_onTraffic() {
        flags = .connectionOnTraffic
        XCTAssertTrue(flags.isConnectionOnTrafficOrDemand)
    }

    func test__flags_isConnectionOnTrafficOrDemand_when_onDemand() {
        flags = .connectionOnDemand
        XCTAssertTrue(flags.isConnectionOnTrafficOrDemand)
    }

    func test__flags_isTransientConnection() {
        flags = .transientConnection
        XCTAssertTrue(flags.isTransientConnection)
    }

    func test__flags_isLocalAddress() {
        flags = .isLocalAddress
        XCTAssertTrue(flags.isLocalAddress)
    }

    func test__flags_isDirect() {
        flags = .isDirect
        XCTAssertTrue(flags.isDirect)
    }

    func test__flags_isConnectionRequiredOrTransient_whenRequired() {
        flags = .connectionRequired
        XCTAssertTrue(flags.isConnectionRequiredOrTransient)
    }

    func test__flags_isConnectionRequiredOrTransient_whenTransient() {
        flags = .transientConnection
        XCTAssertTrue(flags.isConnectionRequiredOrTransient)
    }

    func test__flags_isOnWWAN() {
        #if os(iOS)
            flags = .iswwan
            XCTAssertTrue(flags.isOnWWAN)
        #else
            flags = .Reachable
            XCTAssertFalse(flags.isOnWWAN)
        #endif
    }

    func test__flags_isReachableViaWifi_true_when_Reachable() {
        flags = .reachable
        XCTAssertTrue(flags.isReachableViaWiFi)
    }

    func test__flags_isReachableViaWiFi_false_when_Reachable_but_ConnectionRequired() {
        flags = [ .reachable, .connectionRequired ]
        XCTAssertFalse(flags.isReachableViaWiFi)
    }

    func test__flags_isReachableViaWWAN() {
        #if os(iOS)
            flags = [ .reachable, .iswwan ]
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
        XCTAssertEqual(Reachability.NetworkStatus.reachable(.anyConnectionKind), Reachability.NetworkStatus.reachable(.anyConnectionKind))
        XCTAssertEqual(Reachability.NetworkStatus.reachable(.viaWiFi), Reachability.NetworkStatus.reachable(.viaWiFi))
        XCTAssertEqual(Reachability.NetworkStatus.reachable(.viaWWAN), Reachability.NetworkStatus.reachable(.viaWWAN))
        XCTAssertEqual(Reachability.NetworkStatus.notReachable, Reachability.NetworkStatus.notReachable)
        XCTAssertNotEqual(Reachability.NetworkStatus.reachable(.anyConnectionKind), Reachability.NetworkStatus.reachable(.viaWiFi))
        XCTAssertNotEqual(Reachability.NetworkStatus.reachable(.viaWiFi), Reachability.NetworkStatus.reachable(.viaWWAN))
        XCTAssertNotEqual(Reachability.NetworkStatus.reachable(.viaWWAN), Reachability.NetworkStatus.reachable(.viaWiFi))
        XCTAssertNotEqual(Reachability.NetworkStatus.notReachable, Reachability.NetworkStatus.reachable(.anyConnectionKind))

    }

    func test__init_flags__reachable_via_wifi() {
        flags = [ .reachable ]
        XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.reachable(.viaWiFi))
    }

    func test__init_flags__reachable_via_wwan() {
        #if os(iOS)
            flags = [ .reachable, .iswwan ]
            XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.reachable(.viaWWAN))
        #endif
    }

    func test__init_flags__not_reachable() {
        flags = [ .connectionRequired ]
        XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.notReachable)
    }

    func test__not_reachable_is_not_connected() {
        let status: Reachability.NetworkStatus = .notReachable
        XCTAssertFalse(status.isConnected(.anyConnectionKind))
    }

    func test__reachable_via_wwan_is_not_connected_for_wifi() {
        let status: Reachability.NetworkStatus = .reachable(.viaWWAN)
        XCTAssertFalse(status.isConnected(.viaWiFi))
    }
}

class TestableNetworkReachability {
    typealias Reachability = String

    var didGetDefaultRouteReachability = false
    var _defaultRouteReachability: Reachability = "Default"
    var flags: SCNetworkReachabilityFlags? = .reachable
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

    func startNotifierOnQueue(_ queue: DispatchQueue) throws {
        didStartNotifier = true
        if let flags = flags {
            delegate?.reachabilityDidChange(flags)
        }
    }

    func stopNotifier() {
        didStopNotifier = true
    }

    func reachabilityFlagsForHostname(_ host: String) -> SCNetworkReachabilityFlags? {
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
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        manager.whenConnected(.anyConnectionKind) {
            blockDidRun = true
            expectation.fulfill()
        }

        waitForExpectations(withTimeout: 3.0, handler: nil)
        XCTAssertTrue(blockDidRun)
        XCTAssertTrue(network.didStopNotifier)
    }
}

class HostReachabilityManagerTests: ReachabilityManagerTests {

    func test__reachabilityForURL__with_no_host__not_reachable() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        var receivedStatus: Reachability.NetworkStatus? = .none
        manager.reachabilityForURL(URL(string: "http://")!) { status in
            receivedStatus = status
            expectation.fulfill()
        }

        waitForExpectations(withTimeout: 3.0, handler: nil)
        XCTAssertEqual(receivedStatus ?? .reachable(.anyConnectionKind), .notReachable)
    }

    func test__reachabilityForURL__without_flags__not_reachable() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        var receivedStatus: Reachability.NetworkStatus? = .none
        network.flags = .none
        manager.reachabilityForURL(URL(string: "http://apple.com")!) { status in
            receivedStatus = status
            expectation.fulfill()
        }

        waitForExpectations(withTimeout: 3.0, handler: nil)
        XCTAssertEqual(receivedStatus ?? .reachable(.anyConnectionKind), .notReachable)
    }

    func test__reachabilityForURL__reachable() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")
        var receivedStatus: Reachability.NetworkStatus? = .none
        manager.reachabilityForURL(URL(string: "http://apple.com")!) { status in
            receivedStatus = status
            expectation.fulfill()
        }

        waitForExpectations(withTimeout: 3.0, handler: nil)
        XCTAssertEqual(receivedStatus ?? .reachable(.anyConnectionKind), .reachable(.viaWiFi))
    }
}

class DeviceReachabilityTests: XCTestCase, NetworkReachabilityDelegate {

    let queue: DispatchQueue = Queue.default.serial("me.danthorpe.Operation.Testing")
    var device: DeviceReachability!
    var expectation: XCTestExpectation? = .none
    var delegateDidReceiveFlags: SCNetworkReachabilityFlags? = .none

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

    func reachabilityDidChange(_ flags: SCNetworkReachabilityFlags) {
        delegateDidReceiveFlags = flags
        expectation?.fulfill()
    }

    func test__reachabilityForHost() {
        XCTAssertNotNil(device.reachabilityForHost("https://apple.com"))
    }

    func test__reachabilityDidChange_informs_delegate() {
        device.reachabilityDidChange(.reachable)
        XCTAssertEqual(delegateDidReceiveFlags ?? .connectionRequired, .reachable)
    }

    func test__check() {
        expectation = self.expectation(withDescription: "Test: \(#function)")
        if let reachability = device.reachabilityForHost("https://apple.com") {
            device.check(reachability, queue: queue)
        }
        waitForExpectations(withTimeout: 3, handler: nil)
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
}
