//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import ProcedureKit

open class TestCondition: Condition {

    let evaluate: () throws -> ConditionResult

    public init(name: String = "TestCondition", dependencies: [Operation] = [], evaluate: @escaping () throws -> ConditionResult) {
        self.evaluate = evaluate
        super.init()
        self.name = name
        self.add(dependencies: dependencies)
    }

    open override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        let result: ConditionResult
        do {
            result = try evaluate()
        }
        catch {
            result = .failure(error)
        }
        completion(result)
    }
}
