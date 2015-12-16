//
//  LoggingObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import XCTest
@testable import Operations

@available(iOS, deprecated=9, message="Use the log property of Operation directly.")
@available(OSX, deprecated=10.11, message="Use the log property of Operation directly.")
class LoggingObserverTests: OperationTests {

    var operation: TestOperation!
    var observer: LoggingObserver!
    var receivedMessages: [String] = []

    override func setUp() {
        super.setUp()
        configureOperation(TestOperation())
    }

    override func tearDown() {
        super.tearDown()
        observer = nil
        operation = nil
        receivedMessages.removeAll()
    }

    func configureOperation(op: TestOperation) {
        operation = op
        operation.name = "Test Logging Operation"
        observer = LoggingObserver { [unowned self] message in
            self.receivedMessages.append(message)
        }
        operation.addObserver(observer)
    }
}

@available(iOS, deprecated=9, message="Use the log property of Operation directly.")
@available(OSX, deprecated=10.11, message="Use the log property of Operation directly.")
class LoggingObserverWithError: LoggingObserverTests {

    override func setUp() {
        super.setUp()
        configureOperation(TestOperation(error: BlockCondition.Error.BlockConditionFailed))
    }

    func test__logger_outputs_number_of_received_errors() {

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(receivedMessages.count, 2)
        XCTAssertEqual(receivedMessages[1], "Test Logging Operation: finished with error(s): [Operations.BlockCondition.Error.BlockConditionFailed].")
    }
}

@available(iOS, deprecated=9, message="Use the log property of Operation directly.")
@available(OSX, deprecated=10.11, message="Use the log property of Operation directly.")
class LoggingObserverWithCancellation: LoggingObserverTests {

    override func setUp() {
        super.setUp()
        configureOperation(TestOperation(delay: 1))
    }

    func test__logger_outputs_cancellation() {

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        operation.cancel()
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(receivedMessages.count, 2)
        XCTAssertEqual(receivedMessages[0], "Test Logging Operation: did cancel.")
    }
}

@available(iOS, deprecated=9, message="Use the log property of Operation directly.")
@available(OSX, deprecated=10.11, message="Use the log property of Operation directly.")
class LoggingObserverWithProduce: LoggingObserverTests {

    override func setUp() {
        super.setUp()
        configureOperation(TestOperation(produced: TestOperation()))
    }

    func test__logger_outputs_cancellation() {

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        print("*** \(receivedMessages)")

        XCTAssertEqual(receivedMessages.count, 5)
        XCTAssertEqual(receivedMessages[1], "Test Logging Operation: did produce operation: Test Operation.")
    }
}


