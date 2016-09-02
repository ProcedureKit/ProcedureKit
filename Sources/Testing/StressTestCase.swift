//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

public class Counter {
    private(set) var _count: Int32 = 0 // swiftlint:disable:this variable_name

    public var count: Int {
        return Int(_count)
    }

    public func increment() -> Int32 {
        return OSAtomicIncrement32(&_count)
    }

    public func barrierIncrement() -> Int32 {
        return OSAtomicIncrement32Barrier(&_count)
    }

    public init() { }
}

public protocol BatchProtocol {
    var startTime: CFAbsoluteTime { get }
    var dispatchGroup: DispatchGroup { get }
    var queue: ProcedureQueue { get }
    var counter: Counter { get }
    var number: Int { get }
    var size: Int { get }
}

open class Batch: BatchProtocol {
    public let startTime = CFAbsoluteTimeGetCurrent()
    public let dispatchGroup = DispatchGroup()
    public let counter = Counter()
    public let queue: ProcedureQueue
    public let number: Int
    public let size: Int

    public init(queue: ProcedureQueue = ProcedureQueue(), number: Int, size: Int) {
        self.queue = queue
        self.number = number
        self.size = size
    }
}

open class StressTestCase: GroupTestCase {

    public enum StressLevel {
        case low, medium, high

        public var batches: Int {
            switch self {
            case .low: return 2
            case .medium: return 3
            case .high: return 5
            }
        }

        public var batchSize: Int {
            switch self {
            case .low: return 10_000
            case .medium: return 15_000
            case .high: return 30_000
            }
        }

        public var batchTimeout: TimeInterval {
            switch self {
            case .low: return 30
            case .medium: return 200
            case .high: return 1_000
            }
        }
    }

    // MARK: Stress Tests

    open func setUpStressTest() {
        queue.delegate = nil
    }

    open func tearDownStressTest() { }

    open func started(batch number: Int, size: Int) -> BatchProtocol {
        return Batch(number: number, size: size)
    }

    open func ended(batch: BatchProtocol) {
        let now = CFAbsoluteTimeGetCurrent()
        let duration = now - batch.startTime
        print("    finished batch: \(batch.number), in \(duration) seconds")
    }

    public func stress(level: StressLevel = .low, withName name: String = #function, withTimeout timeoutOverride: TimeInterval? = nil, block: (BatchProtocol, Int) -> Void) {
        stress(level: level, withName: name, withTimeout: timeoutOverride, iteration: nil, block: block)
    }

    public func measure(level: StressLevel = .low, withName name: String = #function, withTimeout timeoutOverride: TimeInterval? = nil, block: @escaping (BatchProtocol, Int) -> Void) {
        var count: Int = 0
        measure {
            self.stress(level: level, withName: name, withTimeout: timeoutOverride, iteration: count, block: block)
            count = count.advanced(by: 1)
        }
    }

    func stress(level: StressLevel, withName name: String = #function, withTimeout timeoutOverride: TimeInterval? = nil, iteration: Int? = nil, block: (BatchProtocol, Int) -> Void) {
        let measurementDescription = iteration.map { "Measurement: \($0), " } ?? ""
        let stressTestName = "\(measurementDescription)Stress Test: \(name)"
        let timeout: TimeInterval = timeoutOverride ?? level.batchTimeout
        var shouldContinueBatches = true

        print("\(stressTestName)\n  Parameters: \(level.batches) batches, size \(level.batchSize), timeout: \(timeout)")

        setUpStressTest()

        defer {
            tearDownStressTest()
        }

        (0..<level.batches).forEach { batchCount in
            guard shouldContinueBatches else { return }
            autoreleasepool {

                let batch = started(batch: batchCount, size: level.batchSize)
                weak var batchExpectation = expectation(description: stressTestName)

                (0..<level.batchSize).forEach { iteration in
                    block(batch, iteration)
                }

                batch.dispatchGroup.notify(queue: .main) {
                    guard let expect = batchExpectation else { print("\(stressTestName): Completed after timeout"); return }
                    expect.fulfill()
                }

                waitForExpectations(timeout: timeout) { error in
                    if let _ = error {
                        shouldContinueBatches = false
                    }
                }

                ended(batch: batch)

            } // End of autorelease
        } // End of batches
    }
}
