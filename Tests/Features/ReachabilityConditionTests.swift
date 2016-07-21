//
//  ReachabilityConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class ReachabilityConditionTests: OperationTests {

    var network: TestableNetworkReachability!
    var manager: ReachabilityManager!

    let url = URL(string: "http://apple.com")!

    override func setUp() {
        super.setUp()
        network = TestableNetworkReachability()
        manager = ReachabilityManager(network)
    }

    func test__condition_name() {
        let condition = ReachabilityCondition(url: url)
        condition.reachability = manager
        XCTAssertEqual(condition.name, "Reachability")
    }

    func test__is_mutually_exclusivity() {
        let condition = ReachabilityCondition(url: url)
        condition.reachability = manager
        XCTAssertFalse(condition.mutuallyExclusive)
    }

    func test__url() {
        let condition = ReachabilityCondition(url: url)
        condition.reachability = manager
        XCTAssertEqual(condition.url, url)
    }


    func test__condition_is_satisfied_when_host_is_reachable_via_wifi() {

        let operation = TestOperation()
        let condition = ReachabilityCondition(url: url)
        condition.reachability = manager
        operation.addCondition(condition)

        waitForOperation(operation)

        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.isFinished)
    }

    func test__condition_fails_with_not_reachable() {

        let expectation = self.expectation(description: "Test: \(#function)")
        let operation = TestOperation()
        let condition = ReachabilityCondition(url: url)
        condition.reachability = manager

        var conditionResult: OperationConditionResult = .satisfied
        network.flags = []
        condition.evaluate(operation) { result in
            conditionResult = result
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)

        guard let error = conditionResult.error as? ReachabilityCondition.Error else {
            XCTFail("Should have an error")
            return
        }

        XCTAssertEqual(error, ReachabilityCondition.Error.notReachable)
    }

    #if os(iOS)
    func test__condition_fails_when_wifi_required_but_only_wwan_available() {

        let expectation = self.expectation(description: "Test: \(#function)")

        let operation = TestOperation()
        let condition = ReachabilityCondition(url: url, connectivity: .viaWiFi)
        condition.reachability = manager
        var conditionResult: OperationConditionResult = .satisfied

        network.flags = [.reachable, .isWWAN]

        condition.evaluate(operation) { result in
            conditionResult = result
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)

        guard let error = conditionResult.error as? ReachabilityCondition.Error else {
            XCTFail("Should have an error")
            return
        }

        XCTAssertEqual(error, ReachabilityCondition.Error.notReachableWithConnectivity(.viaWiFi))
    }

    func test__condition_succeeds_when_only_wifi_accepted_and_only_wifi_available() {
        network.flags = [.reachable]

        let operation = TestOperation()
        let condition = ReachabilityCondition(url: url, connectivity: .viaWiFi)
        condition.reachability = manager
        operation.addCondition(condition)
        waitForOperation(operation)

        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.isFinished)
    }
    #endif
}

class ReachabilityConditionErrorTests: XCTestCase {

    func test__equality__both_not_reachable() {
        XCTAssertEqual(ReachabilityCondition.Error.notReachable, ReachabilityCondition.Error.notReachable)
    }

    func test__equality__both_not_reachable_same_connectivity() {
        XCTAssertEqual(ReachabilityCondition.Error.notReachableWithConnectivity(.anyConnectionKind), ReachabilityCondition.Error.notReachableWithConnectivity(.anyConnectionKind))
    }

    func test__equality__both_not_reachable_different_connectivity() {
        XCTAssertNotEqual(ReachabilityCondition.Error.notReachableWithConnectivity(.viaWWAN), ReachabilityCondition.Error.notReachableWithConnectivity(.viaWiFi))
    }

    func test__equality__different_reachable() {
        XCTAssertNotEqual(ReachabilityCondition.Error.notReachable, ReachabilityCondition.Error.notReachableWithConnectivity(.viaWiFi))
    }

}
