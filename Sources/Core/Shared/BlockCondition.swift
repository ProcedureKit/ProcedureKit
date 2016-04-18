//
//  BlockCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A Condition which will be satisfied if the block returns true. The
 block may throw an error, or return false, both of which are
 intepretated as a condition failure.
*/
public class BlockCondition: Condition {

    /// The block type which returns a Bool.
    public typealias ConditionBlockType = () throws -> Bool

    /// The error used to indicate failure, in the case
    /// of a false return, without a thrown error.
    public enum Error: ErrorType {

        /**
        If the block returns false, the operation to
        which it is attached will fail with this error.
        */
        case BlockConditionFailed
    }

    let block: ConditionBlockType

    /**
    Creates a `BlockCondition` with the supplied block.

    Example like this..

        operation.addCondition(BlockCondition { true })

    Alternatively

        func checkFlag() -> Bool {
            return toDoSomethingOrNot
        }

        operation.addCondition(BlockCondition(block: checkFlag))

    - parameter block: a `ConditionBlockType`.
    */
    public init(name: String = "Block Condition", mutuallyExclusive: Bool = false, block: ConditionBlockType) {
        self.block = block
        super.init()
        self.mutuallyExclusive = mutuallyExclusive
        self.name = name
    }

    /**
    Evaluates the condition, it will execute the block.

    - parameter operation: the attached `Operation`
    - parameter completion: the evaulation completion block, it is given the result.
    */
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        do {
            let result = try block()
            completion(result ? .Satisfied : .Failed(Error.BlockConditionFailed))
        }
        catch {
            completion(.Failed(error))
        }
    }
}

extension BlockCondition.Error: Equatable { }

public func == (_: BlockCondition.Error, _: BlockCondition.Error) -> Bool {
    return true // Only one case in the enum
}

public class TrueCondition: BlockCondition {
    public init(name: String = "True Condition", mutuallyExclusive: Bool = false) {
        super.init(name: name, mutuallyExclusive: mutuallyExclusive, block: { true })
    }
}

public class FalseCondition: BlockCondition {
    public init(name: String = "False Condition", mutuallyExclusive: Bool = false) {
        super.init(name: name, mutuallyExclusive: mutuallyExclusive, block: { false })
    }
}
