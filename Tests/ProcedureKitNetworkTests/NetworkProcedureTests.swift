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
        makeNetworkReachable.addDependency(delay)

        wait(forAll: [delay, makeNetworkReachable, procedure])
        PKAssertProcedureFinished(procedure)
    }

    #if os(iOS)
    func test__procedure_waits_until_correct_network_connectivity_is_available() {
        network.flags = .interventionRequired
        let procedure = NetworkReachabilityWaitProcedure(reachability: manager, via: .wifi)

        let delay1 = DelayProcedure(by: 0.1)
        let changeNetwork1 = BlockProcedure {
            self.network.flags = [ .reachable, .isWWAN ]
        }
        changeNetwork1.addDependency(delay1)

        let delay2 = DelayProcedure(by: 0.2)
        let changeNetwork2 = BlockProcedure {
            self.network.flags = .reachable
        }
        changeNetwork2.addDependency(delay2)


        wait(forAll: [delay1, changeNetwork1, delay2, changeNetwork2, procedure])
        PKAssertProcedureFinished(procedure)
    }
    #endif

}

class NetworkProcedureTests: ProcedureKitTestCase {

    typealias Target = NetworkDataProcedure

    var url: URL!
    var request: URLRequest!
    var resilience: DefaultNetworkResilience!
    var session: TestableURLSessionTaskFactory!
    var data: NetworkDataProcedure!
    var network: TestableNetworkReachability!
    var manager: Reachability.Manager!

    override func setUp() {
        super.setUp()
        url = "http://procedure.kit.run"
        request = URLRequest(url: url)
        resilience = DefaultNetworkResilience(backoffStrategy: .constant(1.0), requestTimeout: 1.0)
        session = TestableURLSessionTaskFactory()
        data = NetworkDataProcedure(session: session, request: request)
        network = TestableNetworkReachability()
        manager = Reachability.Manager(network)
    }

    override func tearDown() {
        network = nil
        manager = nil
        super.tearDown()
    }

    func createNetworkProcedure() -> Target {
        return Target(session: session, request: request)
    }

    func test__reachable_network_does_not_start_notifier() {
        let procedure = NetworkProcedure<Target>(body: createNetworkProcedure)
        procedure.reachability = manager
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
        XCTAssertFalse(network.didStartNotifier)
    }

    func test__waits_for_reachability_change_before_retrying() {
        session.returnedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        network.flags = .connectionRequired
        let delay = DelayProcedure(by: 0.1)
        let makeSessionSuccessful = BlockProcedure { self.session.returnedError = nil }
        makeSessionSuccessful.addDependency(delay)
        let makeNetworkReachable = BlockProcedure { self.network.flags = .reachable }
        makeNetworkReachable.addDependency(makeSessionSuccessful)

        let procedure = NetworkProcedure<Target>(resilience: resilience, body: createNetworkProcedure)
        procedure.reachability = manager

        wait(forAll: [procedure, delay, makeSessionSuccessful, makeNetworkReachable])
        PKAssertProcedureFinished(procedure)
        XCTAssertEqual(procedure.count, 2)
        XCTAssertTrue(network.didStopNotifier)
    }

    func test__does_not_wait_for_reachability_if_transient_error() {
        session.returnedError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)

        let delay = DelayProcedure(by: 0.1)
        let makeSessionSuccessful = BlockProcedure { self.session.returnedError = nil }
        makeSessionSuccessful.addDependency(delay)

        let procedure = NetworkProcedure<Target>(resilience: resilience, body: createNetworkProcedure)
        procedure.reachability = manager

        wait(forAll: [procedure, delay, makeSessionSuccessful], withTimeout: 4)
        PKAssertProcedureFinished(procedure)
        XCTAssertEqual(procedure.count, 2)
    }

    func test__retry_server_error() {
        session.returnedResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)

        let delay = DelayProcedure(by: 0.1)
        let makeSessionSuccessful = BlockProcedure { self.session.returnedResponse = HTTPURLResponse(url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil) }
        makeSessionSuccessful.addDependency(delay)

        let procedure = NetworkProcedure<Target>(resilience: resilience, body: createNetworkProcedure)
        procedure.reachability = manager

        wait(forAll: [procedure, delay, makeSessionSuccessful], withTimeout: 4)
        PKAssertProcedureFinished(procedure)
        XCTAssertEqual(procedure.count, 2)
    }

    func test__retry_client_error_too_many_requests() {
        session.returnedResponse = HTTPURLResponse(url: url, statusCode: HTTPStatusCode.tooManyRequests.rawValue, httpVersion: nil, headerFields: nil)

        let delay = DelayProcedure(by: 0.1)
        let makeSessionSuccessful = BlockProcedure { self.session.returnedResponse = HTTPURLResponse(url: self.url, statusCode: 200, httpVersion: nil, headerFields: nil) }
        makeSessionSuccessful.addDependency(delay)

        let procedure = NetworkProcedure<Target>(resilience: resilience, body: createNetworkProcedure)
        procedure.reachability = manager

        wait(forAll: [procedure, delay, makeSessionSuccessful], withTimeout: 4)
        PKAssertProcedureFinished(procedure)
        XCTAssertEqual(procedure.count, 2)
    }

    // Payload Injection

    func test__payload_is_injected() {
        let procedure = NetworkProcedure<Target>(body: createNetworkProcedure)
        var didReceivePayload = false
        let transform = TransformProcedure<Data, Bool> { data in
            didReceivePayload = true
            return true
        }.injectPayload(fromNetwork: procedure)

        wait(for: procedure, transform)
        PKAssertProcedureFinished(procedure)
        XCTAssertTrue(didReceivePayload)
    }

    func test__payload_injection_error() {
        session.returnedData = nil
        let procedure = NetworkProcedure<Target>(body: createNetworkProcedure)
        var didReceivePayload = false
        let transform = TransformProcedure<Data, Bool> { data in
            didReceivePayload = true
            return true
        }.injectPayload(fromNetwork: procedure)

        wait(for: procedure, transform)
        PKAssertProcedureCancelledWithError(transform, ProcedureKitError.dependency(finishedWithError: procedure.error))
        XCTAssertFalse(didReceivePayload)
    }
}
