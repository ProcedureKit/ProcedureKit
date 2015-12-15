//
//  BlockObserverTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/12/2015.
//
//

import XCTest
@testable import Operations

class BlockObserverTests: OperationTests {

    var operation: TestOperation!
    
    override func setUp() {
        super.setUp()
        operation = TestOperation()
    }

    override func tearDown() {
        operation = nil
        super.tearDown()
    }
    
    func test__start_handler_is_executed() {

        var counter = 0
        operation.addObserver(BlockObserver(startHandler: { op in
            counter += 1
        }))
        
        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)
        
        XCTAssertEqual(counter, 1)
    }
    
    func test__cancellation_handler_is_executed() {

        var counter = 0
        operation.addObserver(BlockObserver(cancellationHandler: { op in
            counter += 1
        }))
        
        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        operation.cancel()
        operation.cancel() // Deliberately call cancel multiple times.
        waitForExpectationsWithTimeout(3, handler: nil)
        
        XCTAssertEqual(counter, 1)
    }

    func test__produce_handler_is_executed() {
        let produced = TestOperation()
        operation = TestOperation(produced: produced)

        var counter = 0
        operation.addObserver(BlockObserver(produceHandler: { op, pro in
            counter += 1
            XCTAssertEqual(produced, pro)
        }))

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(counter, 1)
    }

    func test__finish_handler_is_executed() {

        var counter = 0
        operation.addObserver(BlockObserver { op, errors in
            counter += 1
        })

        addCompletionBlockToTestOperation(operation, withExpectation: expectationWithDescription("Test: \(__FUNCTION__)"))
        runOperation(operation)
        waitForExpectationsWithTimeout(3, handler: nil)

        XCTAssertEqual(counter, 1)
    }
}
