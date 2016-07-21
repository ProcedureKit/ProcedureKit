//
//  ResultInjectionTests.swift
//  Operations
//
//  Created by Daniel Thorpe on 16/12/2015.
//
//

import XCTest
@testable import Operations

class DataProcessing: Procedure, AutomaticInjectionOperationType {

    var requirement: String? = .none

    override init() {
        super.init()
        name = "Data Processing"
    }

    override func execute() {
        let output = requirement ?? "No requirements provided!"
        log.info(output)
        finish()
    }
}

class ResultInjectionTests: OperationTests {

    var retrieval: TestOperation!
    var processing: DataProcessing!

    override func setUp() {
        super.setUp()
        retrieval = TestOperation()
        processing = DataProcessing()
    }
}

class ManualResultInjectionTests: ResultInjectionTests {

    func test__block_is_executed() {
        let _ = processing.injectResultFromDependency(retrieval) { op, dep, errors in
            XCTAssertEqual(dep.result, "Hello World")
        }

        addCompletionBlockToTestOperation(processing, withExpectation: expectation(description: "Test: \(#function)"))
        runOperations(retrieval, processing)
        waitForExpectations(timeout: 3, handler: nil)
    }

    func test__block_passes_through_errors() {
        retrieval = TestOperation(error: TestOperation.Error.simulatedError)
        let _ = processing.injectResultFromDependency(retrieval) { op, dep, errors in
            XCTAssertEqual(errors.count, 1)
            guard let _ = errors.first as? TestOperation.Error else {
                XCTFail("Incorrect error received")
                return
            }
        }

        addCompletionBlockToTestOperation(processing, withExpectation: expectation(description: "Test: \(#function)"))
        runOperations(retrieval, processing)
        waitForExpectations(timeout: 3, handler: nil)
    }
}

class AutomaticResultInjectionTests: ResultInjectionTests {

    func test__requirement_is_injected() {
        let _ = processing.injectResultFromDependency(retrieval)

        addCompletionBlockToTestOperation(processing, withExpectation: expectation(description: "Test: \(#function)"))
        runOperations(retrieval, processing)
        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertEqual(processing.requirement, retrieval.result)
    }

    func test__processing_cancels_with_errors_if_dependency_errors() {
        retrieval = TestOperation(error: TestOperation.Error.simulatedError)
        let _ = processing.injectResultFromDependency(retrieval)
        processing.addObserver(DidCancelObserver { op in
            XCTAssertEqual(op.errors.count, 1)
            guard let error = op.errors.first as? AutomaticInjectionError else {
                XCTFail("Incorrect error received")
                return
            }

            switch error {
            case .dependencyFinishedWithErrors(let errors):
                XCTAssertEqual(errors.count, 1)
                guard let _ = errors.first as? TestOperation.Error else {
                    XCTFail("Incorrect error received")
                    return
                }
            default:
                XCTFail("Incorrect error received")
            }
        })

        addCompletionBlockToTestOperation(processing, withExpectation: expectation(description: "Test: \(#function)"))
        runOperations(retrieval, processing)
        waitForExpectations(timeout: 3, handler: nil)

        XCTAssertTrue(processing.isCancelled)
    }
}

class ExecuteTests: OperationTests {

    class TestExecutor {
        var error: ErrorProtocol? = .none
        var didExecute = false
        var didCancel = false

        func execute(_ finish: (ErrorProtocol?) -> Void) {
            didExecute = true
            finish(error)
        }

        func cancel() {
            didCancel = true
        }
    }

    class GetStringExecutor: TestExecutor, Executor {
        var result: String = "Hello, World!"
        var requirement: Void = Void()
    }

    class DoubleStringExecutor: TestExecutor, Executor {
        var requirement: String = "yup"
        var result: String = "nope"
        override func execute(_ finish: (ErrorProtocol?) -> Void) {
            result = "\(requirement) \(requirement)"
            super.execute(finish)
        }
    }

    func disable_test__add_single_executor() {
        let operation = Execute(GetStringExecutor())
        waitForOperation(operation)
        XCTAssertTrue(operation.executor.didExecute)
        XCTAssertFalse(operation.executor.didCancel)
        XCTAssertEqual(operation.executor.result, "Hello, World!")
    }

    func disable_test__require_result_injection() {
        let get = Execute(GetStringExecutor())
        let double = Execute(DoubleStringExecutor())
        let operation = Execute(DoubleStringExecutor())
        double.requireResultFromDependency(get)
        operation.requireResultFromDependency(double)
        waitForOperations(get, double, operation)
        XCTAssertTrue(operation.executor.didExecute)
        XCTAssertFalse(operation.executor.didCancel)
        XCTAssertEqual(operation.executor.result, "Hello, World! Hello, World! Hello, World! Hello, World!")
    }

    func disable_test__executor_which_throws_error() {
        let executor = GetStringExecutor()
        executor.error = TestOperation.Error.simulatedError

        let operation = Execute(executor)
        waitForOperation(operation)
        XCTAssertTrue(operation.failed)
        XCTAssertEqual(operation.errors.count, 1)
    }

    func disable_test__executor_which_gets_cancelled() {
        let operation = Execute(GetStringExecutor())
        operation.cancel()
        waitForOperation(operation)
        XCTAssertFalse(operation.executor.didExecute)
        XCTAssertTrue(operation.executor.didCancel)
    }
}
