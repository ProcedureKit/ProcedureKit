//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class ProcedureCompletionBlockStressTest: StressTestCase {

    func test__completion_blocks() {

        measure(level: .high) { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure()
            procedure.addCompletionBlock { batch.dispatchGroup.leave() }
            batch.queue.add(operation: procedure)
        }
    }
}

class ProcedureCancelWithErrorsThreadSafetyStressTests: StressTestCase {

    func test__cancel_with_errors_thread_safety() {

        stress(withTimeout: 50) { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure()
            procedure.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: procedure)
            procedure.cancel(withError: TestError())
        }
    }
}

// TODO: Conditions
