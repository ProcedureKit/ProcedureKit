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

    func test__composed_operation_is_cancelled() {
        let composed = ComposedOperation(TestOperation())
        composed.cancel()
        XCTAssertTrue(composed.cancelled)
        XCTAssertTrue(composed.operation.cancelled)
    }

    func test__composed_nsoperation_is_performed() {
        var didExecute = false
        let composed = ComposedOperation(NSBlockOperation {
            didExecute = true
        })

        let expectation = expectationWithDescription("Test: \(#function)")
        addCompletionBlockToTestOperation(composed, withExpectation: expectation)
        runOperation(composed)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(composed.finished)
        XCTAssertTrue(didExecute)
    }

    func test__composed_operation_is_performed() {
        let composed = ComposedOperation(operation: TestOperation())

        let expectation = expectationWithDescription("Test: \(#function)")
        addCompletionBlockToTestOperation(composed, withExpectation: expectation)
        runOperation(composed)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertTrue(composed.finished)
        XCTAssertTrue(composed.operation.didExecute)
    }
}
