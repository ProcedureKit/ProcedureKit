//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class Foo: Procedure, ResultInjection {
    var requirement: PendingValue<String> = .ready("")
    var result: PendingValue<String> = .pending
    override func execute() {
        if let requirement = requirement.value {
            result = .ready("\(requirement)Foo")
        }
        finish()
    }
}

class Bar: Procedure, ResultInjection {
    var requirement: PendingValue<String> = .ready("")
    var result: PendingValue<String> = .pending
    override func execute() {
        if let requirement = requirement.value {
            result = .ready("\(requirement)Bar")
        }
        finish()
    }
}

class Baz: Procedure, ResultInjection {
    var requirement: PendingValue<String> = .ready("")
    var result: PendingValue<String> = .pending
    override func execute() {
        if let requirement = requirement.value {
            result = .ready("\(requirement)Baz")
        }
        finish()
    }
}

class AnyProcedureTests: ProcedureKitTestCase {

    func test__any_procedure() {
        let anyProcedure = AnyProcedure(procedure)
        anyProcedure.log.enabled = true
        anyProcedure.log.severity = .verbose
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
    }

    func test__any_procedure_get_correct_result() {
        let anyProcedure = AnyProcedure(procedure)
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
        XCTAssertEqual(anyProcedure.result.value, "Hello World")
    }

    func test__array_of_any_procedures() {
        let procedures = [AnyProcedure(Foo()), AnyProcedure(Bar()), AnyProcedure(Baz())]
        let group = GroupProcedure(operations: procedures)
        wait(for: group)
        XCTAssertProcedureFinishedWithoutErrors(group)
        XCTAssertEqual(procedures.map { $0.result.value ?? "" }, ["Foo", "Bar", "Baz"])
    }

    func test__setting_requirement() {
        let foo = Foo()
        let anyProcedure = AnyProcedure(foo)
        anyProcedure.requirement = .ready("Hello ")
        wait(for: anyProcedure)
        XCTAssertProcedureFinishedWithoutErrors(foo)
        XCTAssertProcedureFinishedWithoutErrors(anyProcedure)
        XCTAssertEqual(anyProcedure.result.value ?? "Not Hello Foo", "Hello Foo")
    }
}

