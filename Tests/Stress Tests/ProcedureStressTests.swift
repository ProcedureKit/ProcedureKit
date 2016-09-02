//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class CompletionBlockStressTest: StressTestCase {

    func test__completion_blocks() {

        measure { batch, iteration in
            batch.dispatchGroup.enter()
            let procedure = TestProcedure()
            procedure.addCompletionBlock { batch.dispatchGroup.leave() }
            batch.queue.add(operation: procedure)
        }
    }
}


// TODO: Conditions
