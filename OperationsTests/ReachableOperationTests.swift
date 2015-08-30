//
//  ReachableOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations

class TestableSystemReachability: SystemReachability {

    var observers = Array<Reachability.ObserverBlockType>()
    var status: Reachability.NetworkStatus {
        didSet {
            observers.forEach { $0(self.status) }
        }
    }

    init(networkStatus: Reachability.NetworkStatus = .Reachable(.ViaWiFi)) {
        status = networkStatus
    }

    func addObserver(observer: Reachability.ObserverBlockType) -> String {
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(0.3) * Double(NSEC_PER_SEC)))
        dispatch_after(after, Queue.Default.queue) {
            observer(self.status)
        }
        observers.append(observer)
        return NSUUID().UUIDString
    }

    func removeObserverWithToken(token: String) {
        // no-op
    }
}

class ReachableOperationTests: OperationTests {

    var reachability: TestableSystemReachability!

    override func setUp() {
        super.setUp()
        reachability = TestableSystemReachability()
    }

    func test__operation_executes_when_network_is_available() {

        let operation = ReachableOperation(operation: TestOperation(), reachability: reachability)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        reachability.status = .Reachable(.ViaWiFi)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.operation.didExecute)
    }

    func test__operation_executes_when_network_becomes_available() {
        reachability.status = .NotReachable
        let operation = ReachableOperation(operation: TestOperation(), reachability: reachability)

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        reachability.status = .Reachable(.ViaWWAN)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.operation.didExecute)
    }

}

