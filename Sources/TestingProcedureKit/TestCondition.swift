//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation
import ProcedureKit

open class TestCondition: Condition {

    let evaluate: () throws -> ConditionResult

    public init(name: String = "TestCondition", producedDependencies: [Operation] = [], evaluate: @escaping () throws -> ConditionResult) {
        self.evaluate = evaluate
        super.init()
        self.name = name
        producedDependencies.forEach(produceDependency)
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

open class AsyncTestCondition: Condition {

    public typealias EvaluateBlock = (@escaping (ConditionResult) -> Void) -> Void
    let evaluate: EvaluateBlock

    public init(name: String = "TestCondition", producedDependencies: [Operation] = [], evaluate: @escaping EvaluateBlock) {
        self.evaluate = evaluate
        super.init()
        self.name = name
        producedDependencies.forEach(produceDependency)
    }

    open override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        evaluate(completion)
    }
}
