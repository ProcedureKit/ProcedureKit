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
        waitForOperation(operation)
        XCTAssertTrue(receivedMessages.contains("Test Logging Operation: did finish with error(s): [Operations.ConditionError.BlockConditionFailed]."), "log message: \(receivedMessages)")
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

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        operation.cancel()
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(receivedMessages.contains("Test Logging Operation: did cancel."))
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

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(#function)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        XCTAssertTrue(receivedMessages.contains("Test Logging Operation: did produce operation: Test Operation."))
    }
}
