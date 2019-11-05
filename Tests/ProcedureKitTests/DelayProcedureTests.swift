//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class DelayProcedureTests: ProcedureKitTestCase {

    func test__with_interval_name() {
        let delay = DelayProcedure(by: 1)
        XCTAssertEqual(delay.name, "Delay for 1.0 seconds")
    }

    func test__with_date_name() {
        let date = Date()
        let delay = DelayProcedure(until: date)
        XCTAssertEqual(delay.name, "Delay until \(DateFormatter().string(from: date))")
    }

    func test__with_negative_time_interval_finishes_immediately() {
        let delay = DelayProcedure(by: -9_000_000)
        wait(for: delay)
        XCTAssertTrue(delay.isFinished)
    }

    func test__with_distant_past_finishes_immediately() {
        let delay = DelayProcedure(until: Date.distantPast)
        wait(for: delay)
        XCTAssertTrue(delay.isFinished)
    }

    func test__completes_after_interval() {
        let interval: TimeInterval = 0.5
        let delay = DelayProcedure(by: interval)
        let started = Date()
        delay.addDidFinishBlockObserver { _, _ in
            let ended = Date()
            let timeTaken = ended.timeIntervalSince(started)
            XCTAssertGreaterThanOrEqual(timeTaken, interval)
            XCTAssertLessThanOrEqual(timeTaken - interval, 1.0)
        }
        wait(for: delay)
        XCTAssertTrue(delay.isFinished)
    }

    func test__timer_is_not_fired_when_cancelled() {
        let interval: TimeInterval = 10
        let delay = DelayProcedure(by: interval)
        let started = Date()
        delay.addDidFinishBlockObserver { _, _ in
            let ended = Date()
            let timeTaken = ended.timeIntervalSince(started)
            XCTAssertLessThanOrEqual(timeTaken, interval)
        }
        delay.cancel()
        wait(for: delay)
        XCTAssertTrue(delay.isCancelled)
    }

    func test__timer_cancelled_after_execute_finishes_immediately() {
        let interval: TimeInterval = 10
        let delay = DelayProcedure(by: interval)
        let started = Date()
        delay.addDidExecuteBlockObserver { delay in
            delay.cancel()
        }
        delay.addDidFinishBlockObserver { _, _ in
            let ended = Date()
            let timeTaken = ended.timeIntervalSince(started)
            XCTAssertLessThanOrEqual(timeTaken, interval)
        }
        wait(for: delay)
        XCTAssertTrue(delay.isCancelled)
    }

    func test__inject_delay_from_procedure_outputing_delay() {
        let interval: TimeInterval = 0.5
        let result = ResultProcedure { Delay.by(interval) }
        let delay = DelayProcedure().injectResult(from: result)
        let started = Date()
        delay.addDidFinishBlockObserver { _, _ in
            let ended = Date()
            let timeTaken = ended.timeIntervalSince(started)
            XCTAssertGreaterThanOrEqual(timeTaken, interval)
            XCTAssertLessThanOrEqual(timeTaken - interval, 1.0)
        }
        wait(for: result, delay)
        XCTAssertTrue(delay.isFinished)

    }

    func test__inject_delay_from_procedure_outputing_interval() {
        let interval: TimeInterval = 0.5
        let result = ResultProcedure { Delay.by(interval) }
        let delay = DelayProcedure().injectDelay(from: result) { $0.interval }
        let started = Date()
        delay.addDidFinishBlockObserver { _, _ in
            let ended = Date()
            let timeTaken = ended.timeIntervalSince(started)
            XCTAssertGreaterThanOrEqual(timeTaken, interval)
            XCTAssertLessThanOrEqual(timeTaken - interval, 1.0)
        }
        wait(for: result, delay)
        XCTAssertTrue(delay.isFinished)

    }
}

