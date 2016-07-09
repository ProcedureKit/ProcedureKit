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

    let url = NSURL(string: "http://apple.com")!

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
        XCTAssertTrue(operation.finished)
    }

    func test__condition_fails_with_not_reachable() {

        let expectation = expectationWithDescription("Test: \(#function)")
        let operation = TestOperation()
        let condition = ReachabilityCondition(url: url)
        condition.reachability = manager

        var conditionResult: OperationConditionResult = .Satisfied
        network.flags = []
        condition.evaluate(operation) { result in
            conditionResult = result
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(3, handler: nil)

        guard let error = conditionResult.error as? ReachabilityCondition.Error else {
            XCTFail("Should have an error")
            return
        }

        XCTAssertEqual(error, ReachabilityCondition.Error.NotReachable)
    }

    #if os(iOS)
    func test__condition_fails_when_wifi_required_but_only_wwan_available() {

        let expectation = expectationWithDescription("Test: \(#function)")

        let operation = TestOperation()
        let condition = ReachabilityCondition(url: url, connectivity: .ViaWiFi)
        condition.reachability = manager
        var conditionResult: OperationConditionResult = .Satisfied

        network.flags = [.Reachable, .IsWWAN]

        condition.evaluate(operation) { result in
            conditionResult = result
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(3, handler: nil)

        guard let error = conditionResult.error as? ReachabilityCondition.Error else {
            XCTFail("Should have an error")
            return
        }

        XCTAssertEqual(error, ReachabilityCondition.Error.NotReachableWithConnectivity(.ViaWiFi))
    }

    func test__condition_succeeds_when_only_wifi_accepted_and_only_wifi_available() {
        network.flags = [.Reachable]

        let operation = TestOperation()
        let condition = ReachabilityCondition(url: url, connectivity: .ViaWiFi)
        condition.reachability = manager
        operation.addCondition(condition)
        waitForOperation(operation)

        XCTAssertTrue(operation.didExecute)
        XCTAssertTrue(operation.finished)
    }
    #endif
}

class ReachabilityConditionErrorTests: XCTestCase {

    func test__equality__both_not_reachable() {
        XCTAssertEqual(ReachabilityCondition.Error.NotReachable, ReachabilityCondition.Error.NotReachable)
    }

    func test__equality__both_not_reachable_same_connectivity() {
        XCTAssertEqual(ReachabilityCondition.Error.NotReachableWithConnectivity(.AnyConnectionKind), ReachabilityCondition.Error.NotReachableWithConnectivity(.AnyConnectionKind))
    }

    func test__equality__both_not_reachable_different_connectivity() {
        XCTAssertNotEqual(ReachabilityCondition.Error.NotReachableWithConnectivity(.ViaWWAN), ReachabilityCondition.Error.NotReachableWithConnectivity(.ViaWiFi))
    }

    func test__equality__different_reachable() {
        XCTAssertNotEqual(ReachabilityCondition.Error.NotReachable, ReachabilityCondition.Error.NotReachableWithConnectivity(.ViaWiFi))
    }

}
