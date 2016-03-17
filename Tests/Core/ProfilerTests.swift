//
//  ProfilerTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/03/2016.
//
//

import XCTest
@testable import Operations

class ProfilerTests: OperationTests {

    override func setUp() {
        super.setUp()
        LogManager.severity = .Info
    }

    override func tearDown() {
        LogManager.severity = .Fatal
        super.tearDown()
    }

    func test_does_it_work() {
        let first = TestOperation(delay: 0.1)
        first.name = "One"
        first.addObserver(OperationProfiler())

        addCompletionBlockToTestOperation(first)
        runOperation(first)
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func test_does_it_work_produce_one() {
        let second = TestOperation(delay: 0.2)
        second.name = "Two"

        let first = TestOperation(delay: 0.1, produced: second)
        first.name = "One"
        first.addObserver(OperationProfiler())

        addCompletionBlockToTestOperation(second)
        addCompletionBlockToTestOperation(first)
        runOperation(first)
        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func test_does_it_work_produce_two() {
        let third = TestOperation(delay: 0.3)
        third.name = "Three"

        let second = TestOperation(delay: 0.2, produced: third)
        second.name = "Two"

        let first = TestOperation(delay: 0.1, produced: second)
        first.name = "One"
        first.addObserver(OperationProfiler())

        addCompletionBlockToTestOperation(third)
        addCompletionBlockToTestOperation(second)
        addCompletionBlockToTestOperation(first)
        runOperation(first)
        waitForExpectationsWithTimeout(3, handler: nil)
    }

}
