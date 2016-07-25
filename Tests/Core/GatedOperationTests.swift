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

    func test__when_gate_is_closed_operation_is_cancelled() {
        let gate = GatedOperation(TestOperation()) { false }

        addCompletionBlockToTestOperation(gate, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(gate)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(gate.finished)
        XCTAssertTrue(gate.operation.cancelled)
        XCTAssertFalse(gate.operation.didExecute)
    }

    func test__when_gate_is_open_operation_is_performed() {
        let gate = GatedOperation(TestOperation()) { true }

        addCompletionBlockToTestOperation(gate, withExpectation: expectationWithDescription("Test: \(#function), Gate"))
        addCompletionBlockToTestOperation(gate.operation, withExpectation: expectationWithDescription("Test: \(#function), Operation"))
        runOperation(gate)

        waitForExpectationsWithTimeout(5, handler: nil)
        XCTAssertTrue(gate.finished)
        XCTAssertTrue(gate.operation.didExecute)
        XCTAssertTrue(gate.operation.finished)
    }

    func test__when_composed_is_dependency_and_gate_is_open__dependent_is_performed_after_composed() {
        let operation = TestOperation()
        let composed = TestOperation()
        operation.addDependency(composed)
        let gate = GatedOperation(composed) { true }

        waitForOperations(operation, gate)

        XCTAssertTrue(gate.finished)
        XCTAssertTrue(composed.didExecute)
        XCTAssertTrue(composed.finished)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.didExecute)
    }

    func test__when_gate_is_dependency_and_gate_is_open__dependent_is_performed_after_gate() {
        let operation = TestOperation()
        let composed = TestOperation()
        let gate = GatedOperation(composed) { true }
        operation.addDependency(gate)

        waitForOperations(operation, gate)

        XCTAssertTrue(gate.finished)
        XCTAssertTrue(composed.didExecute)
        XCTAssertTrue(composed.finished)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.didExecute)
    }

    func test__when_composed_is_dependency_and_gate_is_closed__dependent_is_still_performed() {
        /// - Note - Remember that regardless of how a dependency finishes, dependent operations
        /// will still become ready and execute.

        let composed = TestOperation()
        let operation = TestOperation()
        operation.addDependency(composed)
        let gate = GatedOperation(composed) { false }

        waitForOperations(gate, operation)

        XCTAssertTrue(gate.finished)
        XCTAssertFalse(composed.didExecute)
        XCTAssertTrue(composed.cancelled)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.didExecute)
    }

    func test__when_gate_is_dependency_and_gate_is_closed__dependent_is_still_performed() {
        let operation = TestOperation()
        let composed = TestOperation()
        let gate = GatedOperation(composed) { false }
        operation.addDependency(gate)

        waitForOperations(gate, operation)

        XCTAssertTrue(gate.finished)
        XCTAssertFalse(composed.didExecute)
        XCTAssertTrue(composed.cancelled)

        XCTAssertTrue(operation.finished)
        XCTAssertTrue(operation.didExecute)
    }
}
