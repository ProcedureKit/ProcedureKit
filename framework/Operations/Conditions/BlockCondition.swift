//
//  BlockCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 22/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public struct BlockCondition: OperationCondition {

    public typealias ConditionBlockType = () -> Bool

    public enum Error: ErrorType {
        case BlockConditionFailed
    }

    public let name = "Block Condition"
    public let isMutuallyExclusive = false

    let condition: ConditionBlockType

    public init(block: ConditionBlockType) {
        condition = block
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(condition() ? .Satisfied : .Failed(Error.BlockConditionFailed))
    }
}


extension BlockCondition.Error: Equatable { }

public func ==(a: BlockCondition.Error, b: BlockCondition.Error) -> Bool {
    switch (a, b) {
    case (.BlockConditionFailed, .BlockConditionFailed): return true
    default: return false
    }
}
