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
        addCompletionBlockToTestOperation(gate, withExpectation: expectationWithDescription("Test: \(#function)"))

        runOperation(gate)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(gate.finished)
        XCTAssertFalse(gate.operation.didExecute)
    }

    func test__when_gate_is_open_operation_is_performed() {
        let gate = GatedOperation(TestOperation()) { return true }
        addCompletionBlockToTestOperation(gate, withExpectation: expectationWithDescription("Test: \(#function), Gate"))
        addCompletionBlockToTestOperation(gate.operation, withExpectation: expectationWithDescription("Test: \(#function), Operation"))

        runOperation(gate)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(gate.finished)
        XCTAssertTrue(gate.operation.didExecute)
        XCTAssertTrue(gate.operation.finished)
    }

}
