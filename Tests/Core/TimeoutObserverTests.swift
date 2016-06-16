//
//  TimeoutObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

class TimeoutObserverTests: OperationTests {

    func test__timeout_observer() {
        let expectation = self.expectation(withDescription: "Test: \(#function)")

        let operation = TestOperation(delay: 0.5)
        operation.addObserver(TimeoutObserver(timeout: 0.1))

        var receivedErrors: [ErrorProtocol] = []
        operation.addObserver(DidFinishObserver { _, errors in
            receivedErrors = errors
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectation)
        runOperation(operation)
        waitForExpectations(withTimeout: 2, handler: nil)

        XCTAssertEqual(receivedErrors.count, 1)
    }
}
