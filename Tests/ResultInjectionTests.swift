//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class DataProcessing: Procedure {
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

class ManualResultInjectionTests: ResultInjectionTestCase {

    func test__block_is_executed() {
        var injectionBlockDidExecute = false
        let _ = processing.inject(dependency: procedure) { processing, dependency, errors in
            injectionBlockDidExecute = true
        }
        wait(for: procedure, processing)
        XCTAssertTrue(injectionBlockDidExecute)
    }

    func test__block_passes_through_errors() {
        let error = TestError()
        var receivedErrors: [Error] = []
        procedure = TestProcedure(error: error)
        let _ = processing.inject(dependency: procedure) { processing, dependency, errors in
            receivedErrors = errors
        }
        wait(for: procedure, processing)
        XCTAssertEqual(error, (receivedErrors.first as? TestError) ?? TestError())
    }
}

