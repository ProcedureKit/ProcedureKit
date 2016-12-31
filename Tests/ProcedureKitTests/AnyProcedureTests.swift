//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class Foo: Procedure, InputProcedure, OutputProcedure {
    var input: Pending<String> = .ready("")
    var output: Pending<ProcedureResult<String>> = .pending
    override func execute() {
        if let input = input.value {
            output = .ready(.success("\(input)Foo"))
        }
        finish()
    }
}

class Bar: Procedure, InputProcedure, OutputProcedure {
    var input: Pending<String> = .ready("")
    var output: Pending<ProcedureResult<String>> = .pending
    override func execute() {
        if let input = input.value {
            output = .ready(.success("\(input)Bar"))
        }
        finish()
    }
}

class Baz: Procedure, InputProcedure, OutputProcedure {
    var input: Pending<String> = .ready("")
    var output: Pending<ProcedureResult<String>> = .pending
    override func execute() {
        if let input = input.value {
            output = .ready(.success("\(input)Baz"))
        }
        finish()
    }
}

class AnyProcedureTests: ProcedureKitTestCase {

    func test__any_procedure() {
        let anyProcedure = AnyProcedure(procedure)
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
    }

    func test__any_procedure_get_correct_result() {
        let anyProcedure = AnyProcedure(procedure)
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
        XCTAssertEqual(anyProcedure.output.success, "Hello World")
    }

    func test__array_of_any_procedures() {
        let procedures = [AnyProcedure(Foo()), AnyProcedure(Bar()), AnyProcedure(Baz())]
        let group = GroupProcedure(operations: procedures)
        wait(for: group)
        XCTAssertProcedureFinishedWithoutErrors(group)
        XCTAssertEqual(procedures.map { $0.output.success ?? "" }, ["Foo", "Bar", "Baz"])
    }

    func test__setting_requirement() {
        let foo = Foo()
        let anyProcedure = AnyProcedure(foo)
        anyProcedure.input = .ready("Hello ")
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(foo)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
        XCTAssertEqual(anyProcedure.output.success ?? "Not Hello Foo", "Hello Foo")
    }
}

