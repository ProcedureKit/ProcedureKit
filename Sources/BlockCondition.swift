//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

public typealias ThrowingBoolBlock = () throws -> Bool

/**
 A Condition which will be satisfied if the block returns true. The
 block may throw an error, or return false, both of which are
 intepretated as a condition failure.
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
            let result = try block()
            completion(result ? .satisfied : .failed(ProcedureKitError.conditionFailed()))
        }
        catch {
            completion(.failed(ProcedureKitError.conditionFailed(withErrors: [error])))
        }
    }
}
