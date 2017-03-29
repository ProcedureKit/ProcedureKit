//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

public class ComposedProcedureTests: ProcedureKitTestCase {

    func test__composed_procedure_is_cancelled() {
        let didCancelCalled = DispatchSemaphore(value: 0)
        procedure.addDidCancelBlockObserver { _, _ in
            didCancelCalled.signal()
        }
        let composed = ComposedProcedure(procedure)
        composed.cancel()
        XCTAssertTrue(composed.isCancelled)

        XCTAssertEqual(didCancelCalled.wait(timeout: .now() + 1.0), DispatchTimeoutResult.success)

        XCTAssertTrue(composed.operation.isCancelled)
        XCTAssertTrue(procedure.isCancelled)
    }

    func test__composed_operation_is_executed() {
        var didExecute = false
        let composed = ComposedProcedure(BlockOperation { didExecute = true })
        wait(for: composed)
        XCTAssertProcedureFinishedWithoutErrors(composed)
        XCTAssertTrue(didExecute)
    }

    func test__composed_procedure_is_executed() {
        let composed = ComposedProcedure(procedure)
        wait(for: composed)
        XCTAssertProcedureFinishedWithoutErrors()
    }
}

public class GatedProcedureTests: ProcedureKitTestCase {

    func test__when_gate_is_closed_procedure_is_cancelled() {
        let gated = GatedProcedure(procedure) { false }
        wait(for: gated)
        XCTAssertProcedureCancelledWithoutErrors(gated)
    }

    func test__when_gate_is_open_procedure_is_performed() {
        let gated = GatedProcedure(procedure) { true }
        wait(for: gated)
        XCTAssertProcedureFinishedWithoutErrors(gated)
        XCTAssertProcedureFinishedWithoutErrors(procedure)
    }
}

