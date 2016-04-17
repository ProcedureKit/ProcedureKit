//
//  StressTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 17/04/2016.
//
//

import Foundation
import XCTest
@testable import Operations

class StressTest: OperationTests {

    let batchSize = 10_000

    func test__completion_blocks() {
        (0..<batchSize).forEach { i in
            let expectation = self.expectationWithDescription("Interation: \(i)")
            let operation = BlockOperation { }
            operation.addCompletionBlock { expectation.fulfill() }
            self.queue.addOperation(operation)
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func test__conditions() {
        let operation = TestOperation()
        (0..<batchSize).forEach { i in
            operation.addCondition(BlockCondition { true })
        }
        addCompletionBlockToTestOperation(operation)
        waitForOperation(operation)
        XCTAssertTrue(operation.didExecute)
    }

    func test__conditions_with_single_dependency() {
        let operation = TestOperation()
        (0..<batchSize).forEach { i in
            let condition = TestCondition(name: "Condition \(i)", isMutuallyExclusive: false, dependency: TestOperation(), condition: { true })
            operation.addCondition(condition)
        }
        addCompletionBlockToTestOperation(operation)
        waitForOperation(operation)
        XCTAssertTrue(operation.didExecute)
    }

}

