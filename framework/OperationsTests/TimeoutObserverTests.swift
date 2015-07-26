//
//  TimeoutObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations

class TimeoutObserverTests: OperationTests {

    func test__timeout_observer() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        let operation = TestOperation(delay: 3)
        operation.addObserver(TimeoutObserver(timeout: 1.0))
        addCompletionBlockToTestOperation(operation, withExpectation: expectation)

        delegate = TestQueueDelegate { (_, errors) in
            XCTAssertEqual(errors.count, 1)
            expectation.fulfill()
        }

        runOperation(operation)
        waitForExpectationsWithTimeout(6, handler: nil)
        XCTAssertEqual(delegate.did_numberOfErrorThatOperationDidFinish, 1)
    }
}
