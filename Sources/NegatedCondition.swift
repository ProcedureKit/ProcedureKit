//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public final class NegatedCondition<C: Condition>: ComposedCondition<C> {

    /// Public override of initializer.
    public override init(_ condition: C) {
        super.init(condition)
        name = condition.name.map { "Not<\($0)>" }
    }

    /// Override of public function
    public override func evaluate(procedure: Procedure, completion: (ConditionResult) -> Void) {
        super.evaluate(procedure: procedure) { composedResult in
            switch composedResult {
            case .pending: completion(.pending)
            case .satisfied:
                completion(.failed(ProcedureKitError.conditionFailed()))
            case .ignored(_), .failed(_):
                completion(.satisfied)
            }
        }
    }
}
