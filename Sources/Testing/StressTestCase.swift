//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

open class StressTestCase: ProcedureKitTestCase {

    public enum StressLevel {
        case low, medium, high

        var batches: Int {
            switch self {
            case .low: return 1
            case .medium: return 10
            case .high: return 100
            }
        }

        var batchSize: Int {
            switch self {
            case .low: return 1_000
            case .medium: return 10_000
            case .high: return 100_000
            }
        }
    }

    class Counter {
        private(set) var count: Int32 = 0

        func increment() -> Int32 {
            return OSAtomicIncrement32(&count)
        }

        func increment_barrier() -> Int32 {
            return OSAtomicIncrement32Barrier(&count)
        }
    }


    public var batches = StressLevel.low.batches

    public var batchSize = StressLevel.medium.batchSize

    public func set(batches stressLevel: StressLevel) {
        batches = stressLevel.batches
    }

    public func set(batchSize stressLevel: StressLevel) {
        batchSize = stressLevel.batchSize
    }

    public func stress(withName name: String = #function, withTimeout timeout: TimeInterval = 5, block: (Int, Int, DispatchGroup) -> Void) {
        let stressTestName = "Stress Test: \(name)"
        let dispatchGroup = DispatchGroup()

        weak var didCompleteStressTestExpectation = expectation(description: stressTestName)

        (0..<batches).forEach { batch in
            (0..<batchSize).forEach { iteration in
                block(batch, iteration, dispatchGroup)
            }
        }

        dispatchGroup.notify(queue: .main) {
            guard let expect = didCompleteStressTestExpectation else { print("stressTestName: Completed after timeout"); return }
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

}
