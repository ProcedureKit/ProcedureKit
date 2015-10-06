//
//  NegatedCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
The error type used to indicate failure.
*/
public enum NegatedConditionError: ErrorType, Equatable {

    /**
    When the nested condition succeeds, the negated condition fails. 
    The associated string is the name of the nested conditon.
    */
    case ConditionSatisfied(String)
}

/**
A simple condition with negates the evaluation of
a composed condition.
*/
public struct NegatedCondition<Condition: OperationCondition>: OperationCondition {

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
        return "Not<\(condition.name)>"
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
    The dependencies for a negated condition are the same as those of the
    composed condition.

    - parameter operation: the `Operation` which is getting evaluated.
    */
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return condition.dependencyForOperation(operation)
    }

    /**
    The evaluation results are those of the composed condition but inverted.

    - parameter operation: the `Operation` which is getting evaluated.
    - parameter completion: a block which receives the `OperationConditionResult`.
    */
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        condition.evaluateForOperation(operation) { [conditionName = condition.name] result in
            switch result {
            case .Satisfied:
                completion(.Failed(NegatedConditionError.ConditionSatisfied(conditionName)))
            case .Failed(_):
                completion(.Satisfied)
            }
        }
    }
}

/// Equatable conformance for `NegatedConditionError`
public func ==(a: NegatedConditionError, b: NegatedConditionError) -> Bool {
    switch (a, b) {
    case let (.ConditionSatisfied(aString), .ConditionSatisfied(bString)):
        return aString == bString
    }
}
