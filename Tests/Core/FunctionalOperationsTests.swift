//
//  FunctionalOperationsTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 21/12/2015.
//
//

import XCTest
@testable import Operations

class NumbersOperation: Operations.Operation, ResultOperationType {

    typealias Result = Array<Int>

    var result: [Int] = []
    var error: ErrorProtocol? = .none

    init(error: ErrorProtocol? = .none) {
        self.error = error
        super.init()
        name = "Numbers Test"
    }

    override func execute() {
        if let error = error {
            finish(error)
        }
        else {
            result = [0, 1, 2, 3, 4, 5 , 6 , 7, 8, 9]
            finish()
        }
    }
}

class MapOperationTests: OperationTests {

    func test__map_operation() {
        let source = TestOperation()
        let destination = source.mapOperation { $0.map { "\($0) \($0)" } ?? "Nope" }

        addCompletionBlockToTestOperation(destination, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperations(source, destination)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertEqual(destination.result, "Hello World Hello World")
    }

    func test__map_operation_with_error() {
        let source = TestOperation(error: TestOperation.Error.simulatedError)
        let destination = source.mapOperation { $0.map { "\($0) \($0)" } ?? "Nope" }

        addCompletionBlockToTestOperation(destination, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperations(source, destination)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(destination.isCancelled)
    }

    func test__map_operation_with_no_requirement() {
        let map: MapOperation<String, String> = MapOperation { str in return "\(str) \(str)" }

        addCompletionBlockToTestOperation(map, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(map)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(map.isFinished)
        XCTAssertEqual(map.errors.count, 1)
    }
}

class FilterOperationTests: OperationTests {

    func test__filter_operation() {
        let numbers = NumbersOperation()
        let filtered = numbers.filterOperation { $0 % 2 == 0 }

        addCompletionBlockToTestOperation(filtered, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperations(numbers, filtered)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertEqual(filtered.result, [0, 2, 4, 6, 8])
    }

    func test__filter_operation_with_cancellation() {
        let delay = DelayOperation(interval: 1)
        let numbers = NumbersOperation()
        numbers.addDependency(delay)
        let filtered = numbers.filterOperation { $0 % 2 == 0 }

        addCompletionBlockToTestOperation(filtered, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperations(delay, numbers, filtered)
        numbers.cancel()
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(filtered.isCancelled)
    }

    func test__filter_with_error() {
        let numbers = NumbersOperation(error: TestOperation.Error.simulatedError)
        let filtered = numbers.filterOperation { $0 % 2 == 0 }

        addCompletionBlockToTestOperation(filtered, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperations(numbers, filtered)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(filtered.isCancelled)
    }
}

class ReduceOperationTests: OperationTests {

    func test__reduce_operation() {
        let numbers = NumbersOperation()
        let reduce = numbers.reduceOperation(0) { (sum: Int, element: Int) in
            return sum + element
        }

        addCompletionBlockToTestOperation(reduce, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperations(numbers, reduce)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertEqual(reduce.result, 45)
    }

    func test__reduce_operation_with_cancellation() {
        let delay = DelayOperation(interval: 1)
        let numbers = NumbersOperation()
        numbers.addDependency(delay)
        let reduce = numbers.reduceOperation(0) { (sum: Int, element: Int) in
            return sum + element
        }

        addCompletionBlockToTestOperation(reduce, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperations(delay, numbers, reduce)
        numbers.cancel()
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(reduce.isCancelled)
    }

    func test__reduce_with_error() {
        let numbers = NumbersOperation(error: TestOperation.Error.simulatedError)
        let reduce = numbers.reduceOperation(0) { (sum: Int, element: Int) in
            return sum + element
        }

        addCompletionBlockToTestOperation(reduce, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperations(numbers, reduce)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(reduce.isCancelled)
    }
}

class ResultOperationTests: OperationTests {

    func test__result_executes() {
        let operation = ResultOperation(result: 0)

        addCompletionBlockToTestOperation(operation, withExpectation: expectation(withDescription: "Test: \(#function)"))
        runOperation(operation)
        waitForExpectations(withTimeout: 3, handler: nil)

        XCTAssertTrue(operation.isFinished)
    }
}
