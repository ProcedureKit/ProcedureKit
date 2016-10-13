//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class Foo: Procedure, ResultInjectionProtocol {
    var requirement: String = ""
    var result: String = "Foo"
    override func execute() {
        result = "\(requirement)Foo"
        finish()
    }
}

class Bar: Procedure, ResultInjectionProtocol {
    var requirement: String = ""
    var result: String = "Bar"
    override func execute() {
        result = "\(requirement)Bar"
        finish()
    }
}

class Baz: Procedure, ResultInjectionProtocol {
    var requirement: String = ""
    var result: String = "Baz"
    override func execute() {
        result = "\(requirement)Baz"
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
        XCTAssertEqual(anyProcedure.result, "Hello World")
    }

    func test__array_of_any_procedures() {
        let procedures = [AnyProcedure(Foo()), AnyProcedure(Bar()), AnyProcedure(Baz())]
        let group = GroupProcedure(operations: procedures)
        wait(for: group)
        XCTAssertProcedureFinishedWithoutErrors(group)
        XCTAssertEqual(procedures.map { $0.result }, ["Foo", "Bar", "Baz"])
        XCTAssertEqual(procedures.map { $0.requirement }, ["", "", ""])
    }

    func test__setting_requirement() {
        let foo = Foo()
        let anyProcedure = AnyProcedure(foo)
        anyProcedure.requirement = "Hello "
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(foo)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
        XCTAssertEqual(anyProcedure.result, "Hello Foo")
    }
}

