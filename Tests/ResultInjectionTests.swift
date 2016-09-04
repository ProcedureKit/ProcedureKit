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

class ResultInjectionTestCase: ProcedureKitTestCase {
    var processing: DataProcessing!

    override func setUp() {
        super.setUp()
        processing = DataProcessing()
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
        procedure.log.severity = .verbose
        processing.log.severity = .verbose
        processing.injectResultFrom(dependency: procedure)
        wait(for: processing, procedure)
        XCTAssertProcedureFinishedWithoutErrors(processing)
    }

    func test__receiver_cancels_with_error_if_dependency_errors() {
        let error = TestError()
        procedure = TestProcedure(error: error)
        processing.injectResultFrom(dependency: procedure)
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
}
