//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import XCTest
import ProcedureKit

open class ProcedureKitTestCase: XCTestCase {

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

    public var queue: ProcedureQueue!
    public var delegate: QueueTestDelegate!
    open var procedure: TestProcedure!

    open override func setUp() {
        super.setUp()
        queue = ProcedureQueue()
        delegate = QueueTestDelegate()
        queue.delegate = delegate
        procedure = TestProcedure()
    }

    open override func tearDown() {
        procedure.cancel()
        queue.cancelAllOperations()
        delegate = nil
        queue = nil
        procedure = nil
        super.tearDown()
    }

    public func run(operation: Operation) {
        run(operations: [operation])
    }

    public func run(operations: Operation...) {
        run(operations: operations)
    }

    public func run(operations: [Operation]) {
        queue.addOperations(operations, waitUntilFinished: false)
    }

    public func wait(for procedures: Procedure..., withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function) {
        for (i, procedure) in procedures.enumerated() {
            addCompletionBlockTo(procedure: procedure, withExpectationDescription: "\(i), \(expectationDescription)")
        }
        run(operations: procedures)
        waitForExpectations(timeout: timeout, handler: nil)
    }

    public func check<T: Procedure>(procedure: T, withTimeout timeout: TimeInterval = 3, withExpectationDescription expectationDescription: String = #function, checkBeforeWait: (T) -> Void) {
        addCompletionBlockTo(procedure: procedure, withExpectationDescription: expectationDescription)
        run(operations: procedure)
        checkBeforeWait(procedure)
        waitForExpectations(timeout: timeout, handler: nil)
    }

    public func addCompletionBlockTo(procedure: Procedure, withExpectationDescription expectationDescription: String = #function) {
        let _ = addExpectationCompletionBlockTo(procedure: procedure, withExpectationDescription: expectationDescription)
    }

    public func addExpectationCompletionBlockTo(procedure: Procedure, withExpectationDescription expectationDescription: String = #function) -> XCTestExpectation {
        let expect = expectation(description: "Test: \(expectationDescription), \(UUID())")
        add(expectation: expect, to: procedure)
        return expect
    }

    public func add(expectation: XCTestExpectation, to procedure: Procedure) {
        weak var weakExpectation = expectation
        procedure.addDidFinishBlockObserver { _, _ in
            DispatchQueue.main.async {
                weakExpectation?.fulfill()
            }
        }
    }

    // MARK: Stress Tests

    public func stress(at level: StressLevel = .medium, withName name: String = #function, withTimeout timeout: TimeInterval? = nil, block: (Int, Int, DispatchGroup) -> Void) {
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
