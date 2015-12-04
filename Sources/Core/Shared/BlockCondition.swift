//
//  BlockCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
An `OperationCondition` which will be satisfied if the block returns true.
*/
public struct BlockCondition: OperationCondition {

    /// The block type which returns a Bool.
    public typealias ConditionBlockType = () -> Bool

    /// The error used to indicate failure.
    public enum Error: ErrorType {

        /**
        If the block returns false, the operation to
        which it is attached will fail with this error.
        */
        case BlockConditionFailed
    }

    /**
    The name of the condition.
    
    - parameter name: a constant String `Block Condition`.
    */
    public let name = "Block Condition"

    /**
    The mutual exclusivity of the condition, which is false.

    - parameter isMutuallyExclusive: a constant Bool, false.
    */
    public let isMutuallyExclusive = false

    let condition: ConditionBlockType

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
    public init(block: ConditionBlockType) {
        condition = block
    }

    /// Conforms to `OperationCondition`, but there are no dependencies, so it returns .None.
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    /**
    Evaluates the condition, it will execute the block.
    
    - parameter operation: the attached `Operation`
    - parameter completion: the evaulation completion block, it is given the result.
    */
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(condition() ? .Satisfied : .Failed(Error.BlockConditionFailed))
    }
}

extension BlockCondition.Error: Equatable { }

public func ==(a: BlockCondition.Error, b: BlockCondition.Error) -> Bool {
    return true // Only one case in the enum
}
