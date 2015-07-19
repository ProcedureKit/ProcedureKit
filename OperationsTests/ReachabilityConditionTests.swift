//
//  ReachabilityConditionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest

@testable
import Operations

class TestableReachability: HostReachability {

    let status: Reachability.NetworkStatus

    init(networkStatus: Reachability.NetworkStatus) {
        status = networkStatus
    }

    func requestReachabilityForURL(url: NSURL, completion: Reachability.ObserverBlockType) {
        completion(status)
    }
}

class ReachabilityConditionTests: OperationTests {

    let url = NSURL(string: "http://apple.com")!

    func test__condition_is_satisfied_when_host_is_reachable_via_wifi() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation(delay: 1)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        let condition = ReachabilityCondition(url: url, reachability: TestableReachability(networkStatus: .ReachableViaWiFi))
        operation.addCondition(condition)

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.finished)
        }
    }

    func test__condition_is_satisfied_when_host_is_reachable_via_wwan() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation(delay: 1)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        let condition = ReachabilityCondition(url: url, connectivity: .ConnectedViaWWAN, reachability: TestableReachability(networkStatus: .ReachableViaWWAN))
        operation.addCondition(condition)

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { error in
            XCTAssertTrue(operation.didExecute)
            XCTAssertTrue(operation.finished)
        }
    }

    func test__condition_fails_when_wifi_is_required_but_only_wwan_available() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation(delay: 1)

        let condition = ReachabilityCondition(url: url, connectivity: .ConnectedViaWiFi, reachability: TestableReachability(networkStatus: .ReachableViaWWAN))
        operation.addCondition(condition)

        var observedErrors = Array<ErrorType>()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            if op == operation {
                observedErrors = errors
            }
            expectation.fulfill()
        }))

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { _ in
            if let error = observedErrors[0] as? ReachabilityCondition.Error {
                XCTAssertTrue(error == ReachabilityCondition.Error.NotReachableWithConnectivity(.ConnectedViaWiFi))
            }
            else {
                XCTFail("No error message was observer")
            }
        }
    }

    func test__condition_fails_when_no_connectivity() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let operation = TestOperation(delay: 1)

        let condition = ReachabilityCondition(url: url, reachability: TestableReachability(networkStatus: .NotConnected))
        operation.addCondition(condition)

        var observedErrors = Array<ErrorType>()
        operation.addObserver(BlockObserver(finishHandler: { (op, errors) in
            if op == operation {
                observedErrors = errors
            }
            expectation.fulfill()
        }))

        runOperation(operation)

        waitForExpectationsWithTimeout(3) { _ in
            if let error = observedErrors[0] as? ReachabilityCondition.Error {
                XCTAssertTrue(error == ReachabilityCondition.Error.NotReachable)
            }
            else {
                XCTFail("No error message was observer")
            }
        }
    }
}



