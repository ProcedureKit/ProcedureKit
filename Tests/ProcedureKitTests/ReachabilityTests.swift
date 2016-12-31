//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import SystemConfiguration
@testable import ProcedureKit
import TestingProcedureKit

class SCNetworkReachabilityFlagsTests: XCTestCase {

    var flags: SCNetworkReachabilityFlags!

    override func tearDown() {
        flags = nil
        super.tearDown()
    }

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
        XCTAssertTrue(flags.isALocalAddress)
    }

    func test__flags_isDirect() {
        flags = .isDirect
        XCTAssertTrue(flags.isDirectConnection)
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
            flags = .isWWAN
            XCTAssertTrue(flags.isOnWWAN)
        #else
            flags = .reachable
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
            flags = [ .reachable, .isWWAN ]
            XCTAssertTrue(flags.isReachableViaWWAN)
        #else
            flags = .reachable
            XCTAssertTrue(flags.isReachableViaWWAN)
        #endif
    }
}

class NetworkStatusTests: XCTestCase {
    typealias Status = Reachability.NetworkStatus

    var flags: SCNetworkReachabilityFlags!

    override func tearDown() {
        flags = nil
        super.tearDown()
    }

    func test__equality() {
        XCTAssertEqual(Status.reachable(.any), Status.reachable(.any))
        XCTAssertEqual(Status.reachable(.wifi), Status.reachable(.wifi))
        XCTAssertEqual(Status.reachable(.wwan), Status.reachable(.wwan))
        XCTAssertEqual(Status.notReachable, Status.notReachable)
        XCTAssertNotEqual(Status.reachable(.any), Status.reachable(.wifi))
        XCTAssertNotEqual(Status.reachable(.wifi), Status.reachable(.wwan))
        XCTAssertNotEqual(Status.reachable(.wwan), Status.reachable(.wifi))
        XCTAssertNotEqual(Status.notReachable, Status.reachable(.any))
    }

    func test__init_flags__reachable_via_wifi() {
        flags = [ .reachable ]
        XCTAssertEqual(Status(flags: flags), Status.reachable(.wifi))
    }

    func test__init_flags__reachable_via_wwan() {
        #if os(iOS)
            flags = [ .reachable, .isWWAN ]
            XCTAssertEqual(Reachability.NetworkStatus(flags: flags), Reachability.NetworkStatus.reachable(.wwan))
        #endif
    }

    func test__init_flags__not_reachable() {
        flags = [ .connectionRequired ]
        XCTAssertEqual(Status(flags: flags), Status.notReachable)
    }

    func test__not_reachable_is_not_connected() {
        let status: Status = .notReachable
        XCTAssertFalse(status.isConnected(via: .any))
    }

    func test__reachable_via_wwan_is_not_connected_for_wifi() {
        let status: Status = .reachable(.wwan)
        XCTAssertFalse(status.isConnected(via: .wifi))
    }

    func test__reachable_via_wifi_is_connected_for_wwan() {
        let status: Status = .reachable(.wifi)
        XCTAssertTrue(status.isConnected(via: .wwan))
    }
}

class ReachabilityObserverTests: XCTestCase {

    func test__init() {
        var didRunBlock = false
        let observer = Reachability.Observer(connectivity: .any) { didRunBlock = true }
        observer.didConnectBlock()
        XCTAssertTrue(didRunBlock)
    }
}


