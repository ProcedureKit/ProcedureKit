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
        } else {
            output = .ready(.failure(ProcedureKitError.requirementNotSatisfied()))
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
        } else {
            output = .ready(.failure(ProcedureKitError.requirementNotSatisfied()))
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
        } else {
            output = .ready(.failure(ProcedureKitError.requirementNotSatisfied()))
        }
        finish()
    }
}

class BaseAnyProcedureTests: ProcedureKitTestCase {
    func test__any_procedure(_ anyProcedure: Procedure) {
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
    }

    func test__any_procedure_get_correct_result<P: OutputProcedure>(_ anyProcedure: P) where P: Procedure, P.Output == String {
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
        XCTAssertEqual(anyProcedure.output.success, "Hello World")
    }

    func test__array_of_any_procedures<P: OutputProcedure>(_ procedures: [P]) where P: Procedure, P.Output == String {
        let group = GroupProcedure(operations: procedures)
        wait(for: group)
        XCTAssertProcedureFinishedWithoutErrors(group)
        XCTAssertEqual(procedures.map { $0.output.success ?? "" }, ["Foo", "Bar", "Baz"])
    }

    func test__setting_requirement<A: InputProcedure, P: InputProcedure>(anyProcedure: A, boxedProcedure: P)
                                                                where A: Procedure, P: Procedure , A.Input == String{
        anyProcedure.input = .ready("Hello ")
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(boxedProcedure)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
    }

    func test__not_setting_requirement<A: InputProcedure, P: InputProcedure>(anyProcedure: A, boxedProcedure: P)
        where A: Procedure, P: Procedure {
            anyProcedure.input = .pending
            wait(for: anyProcedure)
            XCTAssertProcedureFinishedWithoutErrors(boxedProcedure)
            XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
    }
}

class AnyProcedureTests: BaseAnyProcedureTests {

    func test__any_procedure() {
        let anyProcedure = AnyProcedure(procedure)
        self.test__any_procedure(anyProcedure)
    }

    func test__any_procedure_get_correct_result() {
        let anyProcedure = AnyProcedure(procedure)
        self.test__any_procedure_get_correct_result(anyProcedure)
    }

    func test__array_of_any_procedures() {
        let procedures = [AnyProcedure(Foo()), AnyProcedure(Bar()), AnyProcedure(Baz())]
        self.test__array_of_any_procedures(procedures)
    }

    func test__setting_requirement() {
        let foo = Foo()
        let anyProcedure = AnyProcedure(foo)
        test__setting_requirement(anyProcedure: anyProcedure, boxedProcedure: foo)
    }

    func test__not_setting_requirement() {
        let foo = Foo()
        let anyProcedure = AnyProcedure(foo)
        self.test__not_setting_requirement(anyProcedure: anyProcedure, boxedProcedure: foo)
    }
}

class AnyInputProcedureTests: BaseAnyProcedureTests {

    func test__any_procedure() {
        let anyProcedure = AnyInputProcedure(procedure)
        self.test__any_procedure(anyProcedure)
    }

    func test__setting_requirement() {
        let foo = Foo()
        let anyProcedure = AnyInputProcedure(foo)
        test__setting_requirement(anyProcedure: anyProcedure, boxedProcedure: foo)
    }

    func test__not_setting_requirement() {
        let foo = Foo()
        let anyProcedure = AnyInputProcedure(foo)
        self.test__not_setting_requirement(anyProcedure: anyProcedure, boxedProcedure: foo)
    }
}

class AnyOutputProcedureTests: BaseAnyProcedureTests {

    func test__any_procedure() {
        let anyProcedure = AnyOutputProcedure(procedure)
        self.test__any_procedure(anyProcedure)
    }

    func test__any_procedure_get_correct_result() {
        let anyProcedure = AnyOutputProcedure(procedure)
        self.test__any_procedure_get_correct_result(anyProcedure)
    }

    func test__array_of_any_procedures() {
        let procedures = [AnyOutputProcedure(Foo()), AnyOutputProcedure(Bar()), AnyOutputProcedure(Baz())]
        self.test__array_of_any_procedures(procedures)
    }
}


