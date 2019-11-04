//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

/**
 A Condition that negates the result from a composed Condition.

 Thus:
 - If the composed Condition returns `.success(true)`, the `NegatedCondition` returns `.failure(ProcedureKitError.conditionFailed())`
 - Otherwise, the `NegatedCondition` returns `.success(true)`

 */
public final class NegatedCondition<C: Condition>: ComposedCondition<C> {

    /// Public override of initializer.
    public override init(_ condition: C) {
        super.init(condition)
        name = condition.name.map { "Not<\($0)>" }
    }

    /// Override of public function
    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        super.evaluate(procedure: procedure) { composedResult in
            switch composedResult {
            case .success(true):
                completion(.failure(ProcedureKitError.conditionFailed()))
            case .success(false), .failure:
                completion(.success(true))
            }
        }
    }
}
