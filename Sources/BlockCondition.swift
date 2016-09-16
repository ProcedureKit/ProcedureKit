//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/**
 A Condition which will be satisfied if the block returns true. The
 block may throw an error, or return false, both of which are
 intepretated as a condition failure.
 */
public final class BlockCondition: Condition {

    let block: () throws -> Bool

    /**
     Creates a condition with a supplied block.

     - parameter block: a block which returns Bool, to indicate that the condition is satisfied.
    */
    public init(block: @escaping () throws -> Bool) {
        self.block = block
        super.init()
    }

    public override func evaluate(procedure: Procedure, completion: (ConditionResult) -> Void) {
        do {
            let result = try block()
            completion(result ? .satisfied : .failed(ProcedureKitError.conditionFailed()))
        }
        catch {
            completion(.failed(ProcedureKitError.conditionFailed(withErrors: [error])))
        }
    }
}
