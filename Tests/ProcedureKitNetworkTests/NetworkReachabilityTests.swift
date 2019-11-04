//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import SystemConfiguration
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class ReachabilityManagerTests: ProcedureKitTestCase {

    var network: TestableNetworkReachability!
    var manager: Reachability.Manager!

    override func setUp() {
        super.setUp()
        network = TestableNetworkReachability()
        manager = Reachability.Manager(network)
    }

    override func tearDown() {
        network = nil
        manager = nil
        super.tearDown()
    }

    func test__delegate_is_set() {
        XCTAssertNotNil(network.delegate)
    }

    func test__when_connected_block_is_run() {
        var didRunBlock = false
        let exp = expectation(description: "Test: \(#function)")

        manager.whenReachable(via: .any) {
            didRunBlock = true
            exp.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertTrue(didRunBlock)
        XCTAssertTrue(network.didStopNotifier)
    }
}

class DeviceReachabilityTests: XCTestCase, NetworkReachabilityDelegate {

    var queue: DispatchQueue!
    var device: Reachability.Device!
    var testExpectation: XCTestExpectation? = nil
    var delegateDidReceiveFlags: SCNetworkReachabilityFlags? = nil

    override func setUp() {
        super.setUp()
        queue = DispatchQueue(label: "run.kit.ProcedureKit.Network.Reachability.Testing")
        device = Reachability.Device()
        device.delegate = self
    }

    override func tearDown() {
        queue = nil
        device = nil
        testExpectation = nil
        delegateDidReceiveFlags = nil
        super.tearDown()
    }

    func test__notifierIsRunning_is_true_when_running() {
        device.notifierIsRunning = true
        XCTAssertTrue(device.notifierIsRunning)
    }

    func test__notifierIsRunning_is_false_when_not_running() {
        device.notifierIsRunning = false
        XCTAssertFalse(device.notifierIsRunning)
    }

    func test__did_change_reachability_informs_delegate() {
        device.didChangeReachability(flags: .reachable)
        XCTAssertEqual(delegateDidReceiveFlags ?? .connectionRequired, .reachable)
    }

    func didChangeReachability(flags: SCNetworkReachabilityFlags) {
        delegateDidReceiveFlags = flags
        testExpectation?.fulfill()
    }

    func test__check() {
        testExpectation = expectation(description: "Test: \(#function)")
        let reachability = device.defaultRouteReachability
        device.check(reachability: reachability, on: queue)
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssertNotNil(delegateDidReceiveFlags)
    }
}
