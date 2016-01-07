//
//  ComposedOperationTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class ComposedOperationTests: OperationTests {

    func test__composed_operation_is_performed() {
        let composed = ComposedOperation(operation: TestOperation())
        addCompletionBlockToTestOperation(composed, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(composed)

        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(composed.finished)
        XCTAssertTrue(composed.operation.didExecute)
    }
}

