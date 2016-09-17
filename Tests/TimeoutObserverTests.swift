//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

final class TimeoutObserverTests: ProcedureKitTestCase {

    func test__timeout_observer() {
        procedure = TestProcedure(delay: 0.5)
        procedure.add(observer: TimeoutObserver(by: 0.1))
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 1)
    }

    func test__timeout_observer_with_date() {
        procedure = TestProcedure(delay: 0.5)
        procedure.add(observer: TimeoutObserver(until: Date() + 0.1))
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 1)
    }

    func test__timeout_observer_where_procedure_is_already_cancelled() {
        procedure = TestProcedure(delay: 0.5)
        procedure.add(observer: TimeoutObserver(until: Date() + 0.1))
        check(procedure: procedure) { $0.cancel() }
        XCTAssertProcedureCancelledWithoutErrors()
    }

    func test__timeout_observer_where_procedure_is_already_finished() {
        procedure = TestProcedure()
        procedure.add(observer: TimeoutObserver(by: 0.5))
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors()
    }

    func test__timeout_observer_negative_interval() {
        procedure = TestProcedure()
        procedure.add(observer: TimeoutObserver(by: -0.5))
        wait(for: procedure)
        XCTAssertProcedureFinishedWithoutErrors()
    }
}
