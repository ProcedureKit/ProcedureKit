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

        public var batches: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 5
            }
        }

        public var batchSize: Int {
            switch self {
            case .low: return 10_000
            case .medium: return 50_000
            case .high: return 100_000
            }
        }

        public var timeout: TimeInterval {
            switch self {
            case .low: return 5
            case .medium: return 10
            case .high: return 100
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

    public var level: StressLevel = .medium

    public func stress(withName name: String = #function, withTimeout timeout: TimeInterval? = nil, block: (Int, Int, DispatchGroup) -> Void) {
        let stressTestName = "Stress Test: \(name)"
        let dispatchGroup = DispatchGroup()

        weak var didCompleteStressTestExpectation = expectation(description: stressTestName)

        (0..<level.batches).forEach { batch in
            (0..<level.batchSize).forEach { iteration in
                block(batch, iteration, dispatchGroup)
            }
        }

        dispatchGroup.notify(queue: .main) {
            guard let expect = didCompleteStressTestExpectation else { print("stressTestName: Completed after timeout"); return }
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout ?? level.timeout, handler: nil)
    }

}
