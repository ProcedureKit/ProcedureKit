//
//  TimeoutObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest

@testable
import Operations

class TimeoutObserverTests: XCTestCase {

    var queue: OperationQueue!
    var delegate: TestQueueDelegate!

    override func setUp() {
        super.setUp()
        queue = OperationQueue()
    }


    override func tearDown() {
        queue = nil
        delegate = nil
        super.tearDown()
    }

    func test__timeout_observer() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")

        let operation = TestOperation(delay: 3)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        operation.addObserver(TimeoutObserver(timeout: 2.0))

        delegate = TestQueueDelegate { (_, errors) in
            XCTAssertEqual(errors.count, 1)
            expectation.fulfill()
        }
        queue.delegate = delegate
        queue.addOperation(operation)

        waitForExpectationsWithTimeout(4, handler: nil)

        XCTAssertEqual(delegate.did_numberOfErrorThatOperationDidFinish, 1)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
