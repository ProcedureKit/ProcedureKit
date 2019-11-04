//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

public typealias ThrowingBoolBlock = () throws -> Bool

/**
 A Condition which will be satisfied if the block returns true. If the
 block returns false, this will result in an ignored condition, i.e.
 it will not error, but the attached procedure will not execute either.
 Throwing an error from the block will result in a failed procedure.
 */
public final class BlockCondition: Condition {

    let block: ThrowingBoolBlock

    /**
     Creates a condition with a supplied block.

     - parameter block: a block which returns Bool, to indicate that the condition is satisfied.
    */
    public init(block: @escaping ThrowingBoolBlock) {
        self.block = block
        super.init()
    }

    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        do {
            completion(.success(try block()))
        }
        catch {
            completion(.failure(ProcedureKitError.conditionFailed(with: error)))
        }
    }
}
