//
//  SlientCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A simple condition which suppresses its contained condition to not
enqueue its dependency. This is useful for verifying access to
a resoource without prompting for permission.
*/
public struct SilentCondition<Condition: OperationCondition>: OperationCondition {

    /**
    The composed condition.

    - parameter condition: a type which conforms to `OperationCondition`
    */
    public let condition: Condition

    /**
    The name of the condition wraps the name of the composed
    OperationCondition.

    - parameter name: a String
    */
    public var name: String {
        return "Silent<\(condition.name)>"
    }

    /**
    The mututally exclusivity parameter which wraps the
    composed condition's isMutuallyExclusive property.

    - parameter isMutuallyExclusive: a constant Bool, true.
    */
    public var isMutuallyExclusive: Bool {
        return condition.isMutuallyExclusive
    }

    /**
    Initializer which receives a conditon which is to be negated.

    - parameter [unnamed]: a nested `Condition` type.
    */
    public init(_ c: Condition) {
        condition = c
    }

    /**
    The dependencies for a silent condition are nil. This is because the "active
    impact" of the nested condition is to be removed.

    - parameter operation: the `Operation` which is getting evaluated.
    */
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    /**
    The evaluation results just those of its composed condition.

    - parameter operation: the `Operation` which is getting evaluated.
    - parameter completion: a block which receives the `OperationConditionResult`.
    */
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        condition.evaluateForOperation(operation, completion: completion)
    }
}

