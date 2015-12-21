//
//  FunctionalOperationsTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 21/12/2015.
//
//

import XCTest
@testable import Operations

class MapOperationTests: OperationTests {

    func test__map_operation() {
        let source = TestOperation()
        let destination = source.mapOperation { $0.map { "\($0) \($0)" } ?? "Nope" }

        addCompletionBlockToTestOperation(destination, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperations(source, destination)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(destination.result, "Hello World Hello World")
    }

    func test__map_operation_with_error() {
        let source = TestOperation(error: TestOperation.Error.SimulatedError)
        let destination = source.mapOperation { $0.map { "\($0) \($0)" } ?? "Nope" }

        addCompletionBlockToTestOperation(destination, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperations(source, destination)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(destination.cancelled)
    }
}




