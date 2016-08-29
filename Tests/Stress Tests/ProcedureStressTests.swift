//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class ProcedureStressTest: ProcedureKitTestCase {

    func test__completion_blocks() {
        stress { _, _, dispatchGroup in
            dispatchGroup.enter()
            let procedure = TestProcedure()
            procedure.addCompletionBlock { dispatchGroup.leave() }
            queue.add(operation: procedure)
        }
    }

    // TODO: Conditions
}

