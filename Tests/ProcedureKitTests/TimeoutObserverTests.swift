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
        procedure.cancel()
        wait(for: procedure)
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

    func test__multiple_timeout_observers_on_a_single_procedure() {
        procedure = TestProcedure(delay: 0.5)
        procedure.add(observer: TimeoutObserver(by: 0.1))
        procedure.add(observer: TimeoutObserver(by: 0.1))
        procedure.add(observer: TimeoutObserver(by: 0.2))
        procedure.add(observer: TimeoutObserver(by: 3.0))
        wait(for: procedure)
        XCTAssertProcedureCancelledWithErrors(count: 1)
    }

    func test__add_single_timeout_observer_to_multiple_procedures() {
        let procedure1 = TestProcedure(delay: 0.5)
        let procedure2 = TestProcedure(delay: 0.5)
        let procedure3 = TestProcedure(delay: 0)
        let timeoutObserver = TimeoutObserver(by: 0.1)
        procedure1.add(observer: timeoutObserver)
        procedure2.add(observer: timeoutObserver)
        procedure3.add(observer: timeoutObserver)
        wait(for: procedure1, procedure2, procedure3)
        XCTAssertProcedureCancelledWithErrors(procedure1, count: 1)
        XCTAssertProcedureCancelledWithErrors(procedure2, count: 1)
        XCTAssertProcedureFinishedWithoutErrors(procedure3)
    }
}
