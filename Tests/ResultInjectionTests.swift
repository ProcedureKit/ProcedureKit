//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class DataProcessing: Procedure, ResultInjectionProtocol {
    let result: Void = ()
    var requirement: String? = nil

    override func execute() {
        guard let output = requirement else {
            finish(withError: ProcedureKitError.requirementNotSatisfied())
            return
        }
        log.info(message: output)
        finish()
    }
}

class Printing: Procedure, ResultInjectionProtocol {
    let result: Void = ()
    var requirement: String = "Default Requirement"

    override func execute() {
        log.info(message: requirement)
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
        processing.inject(dependency: procedure) { processing, dependency, errors in
            injectionBlockDidExecute = true
        }
        wait(for: procedure, processing)
        XCTAssertTrue(injectionBlockDidExecute)
    }

    func test__block_passes_through_errors() {
        let error = TestError()
        var receivedErrors: [Error] = []
        procedure = TestProcedure(error: error)
        processing.inject(dependency: procedure) { processing, dependency, errors in
            receivedErrors = errors
        }
        wait(for: procedure, processing)
        XCTAssertTrue(TestError.verify(errors: receivedErrors, contains: error))
    }

    func test__automatic_requirement_is_injected() {
        processing.injectResult(from: procedure)
        wait(for: processing, procedure)
        XCTAssertProcedureFinishedWithoutErrors(processing)
    }

    func test__receiver_cancels_with_error_if_dependency_errors() {
        let error = TestError()
        procedure = TestProcedure(error: error)
        processing.injectResult(from: procedure)
        processing.addDidCancelBlockObserver { processing, errors in
            XCTAssertEqual(errors.count, 1)
            guard let procedureKitError = errors.first as? ProcedureKitError else {
                XCTFail("Incorrect error received"); return
            }
            XCTAssertEqual(procedureKitError.context, .dependencyFinishedWithErrors)
            XCTAssertTrue(TestError.verify(errors: procedureKitError.errors, contains: error))
        }
        wait(for: processing, procedure)
        XCTAssertProcedureCancelledWithErrors(processing, count: 1)
    }

    func test__receiver_cancels_with_error_if_dependency_errors_2() {
        let error = TestError()
        procedure = TestProcedure(error: error)
        printing.requireResult(from: procedure)
        printing.addDidCancelBlockObserver { processing, errors in
            XCTAssertEqual(errors.count, 1)
            guard let procedureKitError = errors.first as? ProcedureKitError else {
                XCTFail("Incorrect error received"); return
            }
            XCTAssertEqual(procedureKitError.context, .dependencyFinishedWithErrors)
            XCTAssertTrue(TestError.verify(errors: procedureKitError.errors, contains: error))
        }
        wait(for: printing, procedure)
        XCTAssertProcedureCancelledWithErrors(printing, count: 1)
    }


    func test__requirement_is_injected() {
        printing.requireResult(from: procedure)
        wait(for: procedure, printing)
        XCTAssertEqual(printing.requirement, procedure.result ?? "not what we expect")
    }

    func test__receiver_cancels_with_errors_if_requirement_not_met() {
        procedure.result = nil
        printing.requireResult(from: procedure)
        printing.addDidCancelBlockObserver { printing, errors in
            XCTAssertEqual(errors.count, 1)
            guard let procedureKitError = errors.first as? ProcedureKitError else {
                XCTFail("Incorrect error received"); return
            }
            XCTAssertEqual(procedureKitError.context, .dependencyFinishedWithErrors)
        }
        wait(for: printing, procedure)
        XCTAssertProcedureCancelledWithErrors(printing, count: 1)
    }

    func test__receiver_cancels_if_dependency_is_cancelled() {
        processing.injectResult(from: procedure)
        processing.addDidCancelBlockObserver { printing, errors in
            XCTAssertEqual(errors.count, 1)
            guard let procedureKitError = errors.first as? ProcedureKitError else {
                XCTFail("Incorrect error received"); return
            }
            XCTAssertEqual(procedureKitError.context, .parentCancelledWithErrors)
        }
        procedure.cancel()
        wait(for: processing, procedure)
        XCTAssertProcedureCancelledWithErrors(processing, count: 1)
    }
}


