//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class DataProcessing: Procedure, InputProcedure, OutputProcedure {
    var input: Pending<String> = .pending
    var output: Pending<ProcedureResult<Void>> = pendingVoidResult

    override func execute() {
        guard let output = input.value else {
            finish(with: ProcedureKitError.requirementNotSatisfied())
            return
        }
        log.info.message(output)
        finish()
    }
}

class Printing: Procedure, InputProcedure, OutputProcedure {
    var input: Pending<String> = .ready("Default Requirement")
    var output: Pending<ProcedureResult<Void>> = pendingVoidResult

    override func execute() {
        if let message = input.value {
            log.info.message(message)
        }
        finish()
    }
}

class ResultInjectionTestCase: ProcedureKitTestCase {
    var processing: DataProcessing!
    var printing: Printing!

    override func setUp() {
        super.setUp()
        processing = DataProcessing()
        printing = Printing()
    }
}

class ResultInjectionTests: ResultInjectionTestCase {

    func test__block_is_executed() {
        var injectionBlockDidExecute = false
        processing.inject(dependency: procedure) { processing, dependency, error in
            injectionBlockDidExecute = true
        }
        wait(for: procedure, processing)
        XCTAssertTrue(injectionBlockDidExecute)
    }

    func test__block_passes_through_errors() {
        let expectedError = TestError()
        var receivedError: Error?
        procedure = TestProcedure(error: expectedError)
        processing.inject(dependency: procedure) { processing, dependency, error in
            receivedError = expectedError
        }
        wait(for: procedure, processing)
        guard let error = receivedError as? TestError else {
            XCTFail("Did not receive an error"); return
        }
        XCTAssertEqual(expectedError, error)
    }

    func test__automatic_requirement_is_injected() {
        processing.injectResult(from: procedure)
        wait(for: processing, procedure)
        PKAssertProcedureFinished(processing)
    }

    func test__receiver_cancels_with_error_if_dependency_errors() {
        let expectedError = TestError()
        procedure = TestProcedure(error: expectedError)
        processing.injectResult(from: procedure)
        wait(for: processing, procedure)
        PKAssertProcedureCancelledWithError(processing, ProcedureKitError.dependency(finishedWithError: expectedError))
    }

    func test__receiver_cancels_with_errors_if_requirement_not_met() {
        procedure.output = .pending
        printing.injectResult(from: procedure)
        wait(for: printing, procedure)
        PKAssertProcedureCancelledWithError(printing, ProcedureKitError.requirementNotSatisfied())
    }

    func test__receiver_cancels_if_dependency_is_cancelled() {
        processing.injectResult(from: procedure)
        procedure.cancel()
        wait(for: processing, procedure)
        PKAssertProcedureCancelledWithError(processing, ProcedureKitError.dependenciesCancelled())
    }

    func test__automatic_unwrap_when_result_is_optional_requrement() {
        let hello = ResultProcedure<String?> { "Hello, World" }
        let print = Printing().injectResult(from: hello)
        wait(for: print, hello)
        PKAssertProcedureFinished(print)
    }

    func test__automatic_unwrap_when_result_is_nil_optional_requrement() {
        let hello = ResultProcedure<String?> { nil }
        let printer = Printing().injectResult(from: hello)
        wait(for: printer, hello)
        PKAssertProcedureCancelledWithError(printer, ProcedureKitError.requirementNotSatisfied())
    }

    func test__collection_flatMap() {
        let hello = ResultProcedure { "Hello" }
        let world = ResultProcedure { "World" }
        let mapped = [world, hello].flatMap { $0.uppercased() }
        wait(forAll: [hello, world, mapped])
        PKAssertProcedureFinished(hello)
        PKAssertProcedureFinished(world)
        PKAssertProcedureFinished(mapped)
        PKAssertProcedureOutput(mapped, ["WORLD", "HELLO"])
    }

    func test__collection_reduce() {
        let hello = ResultProcedure { "Hello" }
        let world = ResultProcedure { "World" }
        let helloWorld = [hello, world].reduce("") { accumulator, element in
            guard !accumulator.isEmpty else { return element }
            return "\(accumulator) \(element)"
        }
        wait(forAll: [hello, world, helloWorld])
        PKAssertProcedureFinished(hello)
        PKAssertProcedureFinished(world)
        PKAssertProcedureFinished(helloWorld)
        PKAssertProcedureOutput(helloWorld, "Hello World")
    }

    func test__collection_reduce_which_throws_finishes_with_error() {
        let hello = ResultProcedure { "Hello" }
        let world = ResultProcedure { "World" }
        let error = TestError()
        let helloWorld = [hello, world].reduce("") { _, _ in throw error }
        wait(forAll: [hello, world, helloWorld])
        PKAssertProcedureFinished(hello)
        PKAssertProcedureFinished(world)
        PKAssertProcedureFinishedWithError(helloWorld, error)
        XCTAssertNil(helloWorld.output.success)
    }

    func test__collection_gather() {
        let hello = ResultProcedure { "Hello" }
        let world = ResultProcedure { "World" }
        let gathered = [hello, world].gathered()

        wait(forAll: [hello, world, gathered])
        PKAssertProcedureFinished(hello)
        PKAssertProcedureFinished(world)
        PKAssertProcedureFinished(gathered)
        PKAssertProcedureOutput(gathered, ["Hello", "World"])
    }

    func test__input_binding() {
        let hello = ResultProcedure { "Hello" }
        let world = TransformProcedure<String, String> { "\($0) World" }.injectResult(from: hello)
        let dan = TransformProcedure<String, String> { "\($0) Dan" }
        world.bind(to: dan) // Binds the same input to another procedure
        dan.addDependency(world) // note that bind does not setup any dependencies.

        wait(for: hello, world, dan)
        PKAssertProcedureFinished(hello)
        PKAssertProcedureFinished(world)
        PKAssertProcedureFinished(dan)
        PKAssertProcedureOutput(dan, "Hello Dan")
    }

    func test__binding() {

        class TestGroup: TestGroupProcedure, InputProcedure, OutputProcedure {
            var input: Pending<String> = .pending
            var output: Pending<ProcedureResult<String>> = .pending

            init() {
                let world = TransformProcedure<String, String> { "\($0) World" }
                let result = TransformProcedure<String, String> { "\($0), we are running on ProcedureKit" }
                    .injectResult(from: world)

                super.init(operations: [world, result])

                // Note that we do not need to worry about dependencies here
                // because the child procedures are by definition depending on
                // the group's dependency to have finished.
                bind(to: world)
                bind(from: result)
            }
        }

        let hello = ResultProcedure { "Hello" }
        let group = TestGroup().injectResult(from: hello)

        wait(for: hello, group)
        PKAssertProcedureFinished(hello)
        PKAssertProcedureFinished(group)
        PKAssertProcedureOutput(group, "Hello World, we are running on ProcedureKit")
    }
}


