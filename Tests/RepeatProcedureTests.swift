//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class RepeatProcedureTests: RepeatTestCase {

    func test__init_with_max_and_custom_iterator() {
        repeatProcedure = RepeatProcedure(max: 2, iterator: createIterator())
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__init_with_max_and_delay_iterator() {
        repeatProcedure = RepeatProcedure(max: 2, delay: Delay.Iterator.immediate, iterator: AnyIterator { TestProcedure() })
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__init_with_max_and_wait_strategy() {
        repeatProcedure = RepeatProcedure(max: 2, wait: .constant(0.001), iterator: AnyIterator { TestProcedure() })
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__init_with_max_and_body() {
        repeatProcedure = RepeatProcedure(max: 2) { TestProcedure() }
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__init_with_no_max_and_delay_iterator() {
        repeatProcedure = RepeatProcedure(delay: Delay.Iterator.immediate, iterator: createIterator(succeedsAfterCount: 2))
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithErrors(repeatProcedure, count: 1)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__init_with_no_max_and_wait_strategy() {
        repeatProcedure = RepeatProcedure(wait: .constant(0.001), iterator: createIterator(succeedsAfterCount: 2))
        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithErrors(repeatProcedure, count: 1)
        XCTAssertEqual(repeatProcedure.count, 2)
    }

    func test__append_configure_block() {

        repeatProcedure = RepeatProcedure() { TestProcedure() }

        var didRunConfigureBlock1 = false
        repeatProcedure.appendConfigureBlock { _ in
            didRunConfigureBlock1 = true
        }

        var didRunConfigureBlock2 = false
        repeatProcedure.appendConfigureBlock { _ in
            didRunConfigureBlock2 = true
        }

        repeatProcedure.configure(TestProcedure())
        XCTAssertTrue(didRunConfigureBlock1)
        XCTAssertTrue(didRunConfigureBlock2)
    }

    func test__replace_configure_block() {
        repeatProcedure = RepeatProcedure() { TestProcedure() }

        repeatProcedure.appendConfigureBlock { _ in
            XCTFail("Configure block should have been replaced.")
        }

        var didRunConfigureBlock = false
        repeatProcedure.replaceConfigureBlock { _ in
            didRunConfigureBlock = true
        }

        repeatProcedure.configure(TestProcedure())
        XCTAssertTrue(didRunConfigureBlock)
    }

    func test__payload_with_configure_block_replaces_configure() {
        var didExecuteConfigureBlock = 0
        repeatProcedure = RepeatProcedure(max: 3, iterator: AnyIterator { RepeatProcedurePayload(operation: TestProcedure()) { _ in
                didExecuteConfigureBlock = didExecuteConfigureBlock + 1
            }
        })

        wait(for: repeatProcedure)
        XCTAssertProcedureFinishedWithoutErrors(repeatProcedure)
        XCTAssertEqual(repeatProcedure.count, 3)
        XCTAssertEqual(didExecuteConfigureBlock, 2)
    }
}

class IteratorTests: XCTestCase {

    func test__finite__limits_are_not_exceeeded() {

        var iterator = FiniteIterator(AnyIterator(stride(from: 0, to: 10, by: 1).makeIterator()), limit: 2)

        guard let _ = iterator.next(), let _ = iterator.next() else {
            XCTFail("Should return values up to a limit."); return
        }

        if let _ = iterator.next() {
            XCTFail("Should not return a value once the limit is reached.")
        }
    }
}

class WaitStrategyTestCase: XCTestCase {

    var strategy: WaitStrategy!
    var iterator: AnyIterator<TimeInterval>!

    func test__constant() {
        strategy = .constant(1.0)
        iterator = strategy.iterator
        XCTAssertEqual(iterator.next(), 1.0)
        XCTAssertEqual(iterator.next(), 1.0)
        XCTAssertEqual(iterator.next(), 1.0)
        XCTAssertEqual(iterator.next(), 1.0)
        XCTAssertEqual(iterator.next(), 1.0)
    }

    func test__incrementing() {
        strategy = .incrementing(initial: 0, increment: 3)
        iterator = strategy.iterator
        XCTAssertEqual(iterator.next(), 0)
        XCTAssertEqual(iterator.next(), 3)
        XCTAssertEqual(iterator.next(), 6)
        XCTAssertEqual(iterator.next(), 9)
        XCTAssertEqual(iterator.next(), 12)
        XCTAssertEqual(iterator.next(), 15)
    }

    func test__fibonacci() {
        strategy = .fibonacci(period: 1, maximum: 30.0)
        iterator = strategy.iterator
        XCTAssertEqual(iterator.next(), 0)
        XCTAssertEqual(iterator.next(), 1)
        XCTAssertEqual(iterator.next(), 1)
        XCTAssertEqual(iterator.next(), 2)
        XCTAssertEqual(iterator.next(), 3)
        XCTAssertEqual(iterator.next(), 5)
        XCTAssertEqual(iterator.next(), 8)
        XCTAssertEqual(iterator.next(), 13)
        XCTAssertEqual(iterator.next(), 21)
        XCTAssertEqual(iterator.next(), 30)
    }

    func test__exponential() {
        strategy = .exponential(power: 2.0, period: 1.0, maximum: 20.0)
        iterator = strategy.iterator
        XCTAssertEqual(iterator.next(), 1)
        XCTAssertEqual(iterator.next(), 2)
        XCTAssertEqual(iterator.next(), 4)
        XCTAssertEqual(iterator.next(), 8)
        XCTAssertEqual(iterator.next(), 16)
        XCTAssertEqual(iterator.next(), 20)
    }
}

class DelayIteratorTests: XCTestCase {
    var iterator: AnyIterator<Delay>!

    func test__constant() {
        iterator = Delay.Iterator.constant(1.0)
        XCTAssertEqual(iterator.next(), .by(1.0))
        XCTAssertEqual(iterator.next(), .by(1.0))
        XCTAssertEqual(iterator.next(), .by(1.0))
        XCTAssertEqual(iterator.next(), .by(1.0))
        XCTAssertEqual(iterator.next(), .by(1.0))
    }

    func test__incrementing() {
        iterator = Delay.Iterator.incrementing(from: 0, by: 3)
        XCTAssertEqual(iterator.next(), .by(0))
        XCTAssertEqual(iterator.next(), .by(3))
        XCTAssertEqual(iterator.next(), .by(6))
        XCTAssertEqual(iterator.next(), .by(9))
        XCTAssertEqual(iterator.next(), .by(12))
        XCTAssertEqual(iterator.next(), .by(15))
    }

    func test__fibonacci() {
        iterator = Delay.Iterator.fibonacci(withPeriod: 1, andMaximum: 30.0)
        XCTAssertEqual(iterator.next(), .by(0))
        XCTAssertEqual(iterator.next(), .by(1))
        XCTAssertEqual(iterator.next(), .by(1))
        XCTAssertEqual(iterator.next(), .by(2))
        XCTAssertEqual(iterator.next(), .by(3))
        XCTAssertEqual(iterator.next(), .by(5))
        XCTAssertEqual(iterator.next(), .by(8))
        XCTAssertEqual(iterator.next(), .by(13))
        XCTAssertEqual(iterator.next(), .by(21))
        XCTAssertEqual(iterator.next(), .by(30))
    }

    func test__exponential() {
        iterator = Delay.Iterator.exponential(power: 2.0, withPeriod: 1, andMaximum: 20.0)
        XCTAssertEqual(iterator.next(), .by(1))
        XCTAssertEqual(iterator.next(), .by(2))
        XCTAssertEqual(iterator.next(), .by(4))
        XCTAssertEqual(iterator.next(), .by(8))
        XCTAssertEqual(iterator.next(), .by(16))
        XCTAssertEqual(iterator.next(), .by(20))
    }
}

class RandomnessTests: StressTestCase {

    func test__random_wait_strategy() {
        let wait: WaitStrategy = .random(minimum: 1.0, maximum: 2.0)
        let iterator = wait.iterator
        stress(level: .custom(1, 100_000)) { batch, iteration in
            guard let interval = iterator.next() else { XCTFail("randomness never stops."); return }
            XCTAssertGreaterThanOrEqual(interval, 1.0)
            XCTAssertLessThanOrEqual(interval, 2.0)
        }
    }

    func test__random_delay_iterator() {
        let iterator = Delay.Iterator.random(withMinimum: 1.0, andMaximum: 2.0)
        stress(level: .custom(1, 100_000)) { batch, iteration in
            guard let delay = iterator.next() else { XCTFail("randomness never stops."); return }
            XCTAssertGreaterThanOrEqual(delay, .by(1.0))
            XCTAssertLessThanOrEqual(delay, .by(2.0))
        }
    }

    func test__random_fail_iterator() {
        var iterator = RandomFailIterator(AnyIterator { true }, probability: 0.2)
        var numberOfSuccess = 0
        stress(level: .custom(1, 100_000)) { batch, iteration in
            if let _ = iterator.next() {
                numberOfSuccess = numberOfSuccess + 1
            }
        }
        let probabilityFailure = Double(100_000 - numberOfSuccess) / 100_000.0
        XCTAssertEqualWithAccuracy(probabilityFailure, iterator.probability, accuracy: 0.10)
    }
}

