//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import SystemConfiguration
import ProcedureKit
import TestingProcedureKit
@testable import ProcedureKitNetwork

class NetworkReachabilityWaitProcedureTests: ProcedureKitTestCase {

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

    func test__procedure_waits_until_network_is_reachable() {
        network.flags = .connectionRequired
        let procedure = NetworkReachabilityWaitProcedure(reachability: manager)
        let delay = DelayProcedure(by: 0.1)
        let makeNetworkReachable = BlockProcedure {
            self.network.flags = .reachable
        }
        makeNetworkReachable.add(dependency: delay)

        wait(forAll: [delay, makeNetworkReachable, procedure])
        XCTAssertProcedureFinishedWithoutErrors(procedure)
    }

    #if os(iOS)
    func test__procedure_waits_until_correct_network_connectivity_is_available() {
        network.flags = .interventionRequired
        let procedure = NetworkReachabilityWaitProcedure(reachability: manager, via: .wifi)

        let delay1 = DelayProcedure(by: 0.1)
        let changeNetwork1 = BlockProcedure {
            self.network.flags = [ .reachable, .isWWAN ]
        }
        changeNetwork1.add(dependency: delay1)

        let delay2 = DelayProcedure(by: 0.2)
        let changeNetwork2 = BlockProcedure {
            self.network.flags = .reachable
        }
        changeNetwork2.add(dependency: delay2)


        wait(forAll: [delay1, changeNetwork1, delay2, changeNetwork2, procedure])
        XCTAssertProcedureFinishedWithoutErrors(procedure)
    }
    #endif

}

class NetworkReachableProcedureTests: ProcedureKitTestCase {

    var network: TestableNetworkReachability!
    var manager: Reachability.Manager!

    override func setUp() {
        super.setUp()
        network = TestableNetworkReachability()
        manager = Reachability.Manager(network)
        LogManager.severity = .notice
    }

    override func tearDown() {
        network = nil
        manager = nil
        LogManager.severity = .warning
        super.tearDown()
    }

    func test__reachable_network_does_not_start_notifier() {
        let procedure = NetworkReachableProcedure { TestProcedure() }
        procedure.reachability = manager
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertFalse(network.didStartNotifier)
    }
}
