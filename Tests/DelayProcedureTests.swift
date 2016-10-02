//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
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
}

