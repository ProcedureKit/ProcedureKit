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

    public typealias Error = ConditionError

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

    public override func evaluate(operation: Operation, completion: CompletionBlockType) {
        do {
            let result = try block()
            completion(result ? .Satisfied : .Failed(Error.BlockConditionFailed))
        }
        catch {
            completion(.Failed(error))
        }
    }
}
