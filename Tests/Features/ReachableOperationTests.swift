//
//  ReachableOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class ReachableOperationTests: OperationTests {

    var network: TestableNetworkReachability!
    var manager: ReachabilityManager!
    var operation: ReachableOperation<TestOperation>!

    override func setUp() {
        super.setUp()
        network = TestableNetworkReachability()
        manager = ReachabilityManager(network)
        operation = ReachableOperation(TestOperation())
        operation.reachability = manager
    }

    func test__operation_name() {
        XCTAssertEqual(operation.operationName, "Reachable Operation <Test Operation>")
    }

    func test__connectivity() {
        XCTAssertEqual(operation.connectivity, Reachability.Connectivity.AnyConnectionKind)
    }

    func test__operation_executes_when_network_is_available() {
        waitForOperation(operation)
        XCTAssertTrue(operation.operation.didExecute)
    }
}
