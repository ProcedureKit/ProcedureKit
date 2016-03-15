//
//  ProfilerTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/03/2016.
//
//

import XCTest
@testable import Operations

class ProfilerTests: OperationTests {

    func test_does_it_work() {
        LogManager.severity = .Info
        let operation = TestOperation()
        operation.addObserver(OperationProfiler())
        waitForOperation(operation)
        LogManager.severity = .Fatal
    }
}
