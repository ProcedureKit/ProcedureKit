//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import XCTest
import TestingProcedureKit
@testable import ProcedureKit

class RepeatStressTests: StressTestCase {

    func test__repeat_procedure_cancel() {

        stress { batch, i in
            batch.dispatchGroup.enter()
            let repeatProcedure = RepeatProcedure(wait: .immediate, iterator: AnyIterator { TestProcedure(delay: 1) })
            repeatProcedure.qualityOfService = .default
            repeatProcedure.name = "RepeatProcedure \(batch.number), \(i)"
            repeatProcedure.addDidFinishBlockObserver { _, _ in
                batch.dispatchGroup.leave()
            }
            batch.queue.add(operation: repeatProcedure)
            repeatProcedure.cancel()
        }
    }
}
