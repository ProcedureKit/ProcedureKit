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

    typealias Target = NetworkDataProcedure<TestableURLSessionTaskFactory>

    var url: URL!
    var request: URLRequest!
    var session: TestableURLSessionTaskFactory!
    var data: NetworkDataProcedure<TestableURLSessionTaskFactory>!
    var network: TestableNetworkReachability!
    var manager: Reachability.Manager!

    override func setUp() {
        super.setUp()
        url = "http://procedure.kit.run"
        request = URLRequest(url: url)
        session = TestableURLSessionTaskFactory()
        data = NetworkDataProcedure(session: session, request: request)
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

    func createNetworkProcedure() -> Target {
        return Target(session: session, request: request)
    }

    func test__reachable_network_does_not_start_notifier() {
        let procedure = NetworkReachableProcedure<Target>(body: createNetworkProcedure)
        procedure.reachability = manager
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertFalse(network.didStartNotifier)
    }

    func test__waits_for_reachability_change_before_retrying() {
        session.returnedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        network.flags = .connectionRequired
        let delay = DelayProcedure(by: 0.1)
        let makeSessionSuccessful = BlockProcedure { self.session.returnedError = nil }
        makeSessionSuccessful.add(dependency: delay)
        let makeNetworkReachable = BlockProcedure { self.network.flags = .reachable }
        makeNetworkReachable.add(dependency: makeSessionSuccessful)

        let procedure = NetworkReachableProcedure<Target>(body: createNetworkProcedure)
        procedure.reachability = manager

        wait(forAll: [procedure, delay, makeSessionSuccessful, makeNetworkReachable])
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertEqual(procedure.count, 2)
        XCTAssertTrue(network.didStopNotifier)
    }

    func test__does_not_wait_for_reachability_if_transient_error() {
        session.returnedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        let delay = DelayProcedure(by: 0.1)
        let makeSessionSuccessful = BlockProcedure { self.session.returnedError = nil }
        makeSessionSuccessful.add(dependency: delay)

        let procedure = NetworkReachableProcedure<Target>(body: createNetworkProcedure)
        procedure.reachability = manager

        wait(forAll: [procedure, delay, makeSessionSuccessful])
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertEqual(procedure.count, 2)
    }
}
