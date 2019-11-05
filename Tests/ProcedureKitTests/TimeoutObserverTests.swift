//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

final class TimeoutObserverTests: ProcedureKitTestCase {

    func test__timeout_observer() {
        procedure = TestProcedure(delay: 0.5)
        procedure.addObserver(TimeoutObserver(by: 0.1))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.timedOut(with: .by(0.1)))
    }

    func test__timeout_observer_with_date() {
        let timestamp = Date() + 0.1
        procedure = TestProcedure(delay: 0.5)
        procedure.addObserver(TimeoutObserver(until: timestamp))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.timedOut(with: .until(timestamp)))
    }

    func test__timeout_observer_where_procedure_is_already_cancelled() {
        procedure = TestProcedure(delay: 0.5)
        procedure.addObserver(TimeoutObserver(until: Date() + 0.1))
        procedure.cancel()
        wait(for: procedure)
        PKAssertProcedureCancelled(procedure)
    }

    func test__timeout_observer_where_procedure_is_already_finished() {
        procedure = TestProcedure()
        procedure.addObserver(TimeoutObserver(by: 0.5))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__timeout_observer_negative_interval() {
        procedure = TestProcedure()
        procedure.addObserver(TimeoutObserver(by: -0.5))
        wait(for: procedure)
        PKAssertProcedureFinished(procedure)
    }

    func test__multiple_timeout_observers_on_a_single_procedure() {
        procedure = TestProcedure(delay: 0.5)
        procedure.addObserver(TimeoutObserver(by: 0.1))
        procedure.addObserver(TimeoutObserver(by: 0.1))
        procedure.addObserver(TimeoutObserver(by: 0.2))
        procedure.addObserver(TimeoutObserver(by: 3.0))
        wait(for: procedure)
        PKAssertProcedureCancelledWithError(procedure, ProcedureKitError.timedOut(with: .by(0.1)))
    }

    func test__add_single_timeout_observer_to_multiple_procedures() {
        let procedure1 = TestProcedure(delay: 0.5)
        let procedure2 = TestProcedure(delay: 0.5)
        let procedure3 = TestProcedure(delay: 0)
        let timeoutObserver = TimeoutObserver(by: 0.1)
        procedure1.addObserver(timeoutObserver)
        procedure2.addObserver(timeoutObserver)
        procedure3.addObserver(timeoutObserver)
        wait(for: procedure1, procedure2, procedure3)
        PKAssertProcedureCancelledWithError(procedure1, ProcedureKitError.timedOut(with: .by(0.1)))
        PKAssertProcedureCancelledWithError(procedure2, ProcedureKitError.timedOut(with: .by(0.1)))
        PKAssertProcedureFinished(procedure3)
    }
}
