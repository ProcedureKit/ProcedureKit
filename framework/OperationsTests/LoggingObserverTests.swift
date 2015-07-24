//
//  LoggingObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
import Operations

class LoggingObserverTests: OperationTests {

    func test__logger_receives_messages_when_operation_is_named() {

        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var operation = TestOperation()
        operation.name = "Test Logging Operation"
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)

        var receivedMessages = [String]()
        let logger = LoggingObserver() { message in
            receivedMessages.append(message)
        }
        operation.addObserver(logger)

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(receivedMessages.count, 2)
        XCTAssertEqual(receivedMessages[0], "\(operation.name!): did start.")
        XCTAssertEqual(receivedMessages[1], "\(operation.name!): finished with no errors.")
    }

    func test__logger_outputs_number_of_received_errors() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        var operation = TestOperation(error: CloudContainerCondition.Error.NotAuthenticated)
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)

        var receivedMessages = [String]()
        let logger = LoggingObserver() { message in
            receivedMessages.append(message)
        }
        operation.addObserver(logger)

        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(receivedMessages.count, 2)
        XCTAssertEqual(receivedMessages[1], "\(operation): finished with 1 error(s).")
    }

    func test__logger_receives_messages_from_produced_operation() {
        let expectation = expectationWithDescription("Test: \(__FUNCTION__)")
        let produced = TestOperation(delay: 0)
        produced.name = "Produced Operation"
        var operation = TestOperation(error: CloudContainerCondition.Error.NotAuthenticated, produced: produced)
        operation.name = "Test Operation"
        operation.addCompletionBlockToTestOperation(operation, withExpectation: expectation)

        var receivedMessages = [String]()
        let logger = LoggingObserver() { message in
            receivedMessages.append(message)
        }
        operation.addObserver(logger)

        runOperation(operation)
        waitForExpectationsWithTimeout(5, handler: nil)

        println(receivedMessages)

        XCTAssertEqual(receivedMessages.count, 5)
        XCTAssertEqual(receivedMessages[0], "Test Operation: did start.")
        XCTAssertEqual(receivedMessages[1], "Test Operation: did produce operation: Produced Operation.")
        XCTAssertEqual(receivedMessages[2], "Produced Operation: did start.")
        XCTAssertEqual(receivedMessages[3], "Produced Operation: finished with no errors.")
        XCTAssertEqual(receivedMessages[4], "Test Operation: finished with 1 error(s).")

    }
}

