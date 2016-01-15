//
//  ReachableOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TestableSystemReachability: SystemReachabilityType {

    var error: ErrorType? = .None
    var observers = Array<Reachability.ObserverBlockType>()
    var status: Reachability.NetworkStatus {
        didSet {
            observers.forEach { $0(self.status) }
        }
    }

    init(networkStatus: Reachability.NetworkStatus = .Reachable(.ViaWiFi)) {
        status = networkStatus
    }

    func addObserver(observer: Reachability.ObserverBlockType) throws -> String {
        if let error = error {
            throw error
        }
        else {
            let after = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(0.03) * Double(NSEC_PER_SEC)))
            dispatch_after(after, Queue.Default.queue) {
                observer(self.status)
            }
            observers.append(observer)
        }
        return NSUUID().UUIDString
    }

    func removeObserverWithToken(token: String) {
        // no-op
    }
}

class ReachableOperationTests: OperationTests {

    var reachability: TestableSystemReachability!
    var operation: ReachableOperation<TestOperation>!

    override func setUp() {
        super.setUp()
        reachability = TestableSystemReachability()
        operation = ReachableOperation(operation: TestOperation(), reachability: reachability)
    }

    func test__operation_executes_when_network_is_available() {

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        reachability.status = .Reachable(.ViaWiFi)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.operation.didExecute)
    }

    func test__operation_executes_when_network_becomes_available() {
        reachability.status = .NotReachable

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)

        reachability.status = .Reachable(.ViaWWAN)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(operation.operation.didExecute)
    }

    func test__any_connectivity() {
        XCTAssertFalse(operation.checkStatus(.NotReachable))
        XCTAssertTrue(operation.checkStatus(.Reachable(.ViaWWAN)))
        XCTAssertTrue(operation.checkStatus(.Reachable(.ViaWiFi)))
    }

    func test__via_wwan_connectivity() {
        operation = ReachableOperation(operation: TestOperation(), connectivity: .ViaWWAN, reachability: reachability)
        XCTAssertFalse(operation.checkStatus(.NotReachable))
        XCTAssertTrue(operation.checkStatus(.Reachable(.ViaWWAN)))
        XCTAssertTrue(operation.checkStatus(.Reachable(.ViaWiFi)))
    }

    func test__via_wifi_connectivity() {
        operation = ReachableOperation(operation: TestOperation(), connectivity: .ViaWiFi, reachability: reachability)
        XCTAssertFalse(operation.checkStatus(.NotReachable))
        XCTAssertFalse(operation.checkStatus(.Reachable(.ViaWWAN)))
        XCTAssertTrue(operation.checkStatus(.Reachable(.ViaWiFi)))
    }

    func test__operation_finishes_with_error_if_thrown_by_reachability() {
        reachability.error = Reachability.Error.FailedToCreateDefaultRouteReachability

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(operation.finished)
        XCTAssertEqual(operation.errors.count, 1)
        if let error = operation.errors.first as? Reachability.Error {
            switch error {
            case .FailedToCreateDefaultRouteReachability:
                break
            default:
                XCTFail("Incorrect Error: \(operation.errors)")
            }
        }
        else {
            XCTFail("Incorrect Error: \(operation.errors)")
        }
    }
}



