//
//  GatedOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class GatedOperationTests: OperationTests {

    func test__when_gate_is_closed_operation_is_not_performed() {

        let gate = GatedOperation(TestOperation()) { return false }
        addCompletionBlockToTestOperation(gate, withExpectation: expectation(description: "Test: \(#function)"))

        runOperation(gate)

        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertTrue(gate.isFinished)
        XCTAssertFalse(gate.operation.didExecute)
    }

    func test__when_gate_is_open_operation_is_performed() {
        let gate = GatedOperation(TestOperation()) { return true }
        addCompletionBlockToTestOperation(gate, withExpectation: expectation(description: "Test: \(#function), Gate"))
        addCompletionBlockToTestOperation(gate.operation, withExpectation: expectation(description: "Test: \(#function), OldOperation"))

        runOperation(gate)

        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertTrue(gate.isFinished)
        XCTAssertTrue(gate.operation.didExecute)
        XCTAssertTrue(gate.operation.isFinished)
    }

}
