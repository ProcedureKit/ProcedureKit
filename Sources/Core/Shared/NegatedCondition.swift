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
    case ConditionSatisfied(String?)
}

/**
A simple condition with negates the evaluation of
a composed condition.
*/
public final class NegatedCondition<C: Condition>: ComposedCondition<C> {

    /// Public override of initializer.
    public override init(_ condition: C) {
        super.init(condition)
        name = condition.name.map { "Not<\($0)>" }
    }

    /// Override of public function
    public override func evaluate(operation: Operation, completion: CompletionBlockType) {
        super.evaluate(operation) { [name = self.condition.name] composedResult in
            switch composedResult {
            case .Satisfied:
                completion(.Failed(NegatedConditionError.ConditionSatisfied(name)))
            case .Ignored(_):
                completion(composedResult)
            case .Failed(_):
                completion(.Satisfied)
            }
        }
    }
}

/// Equatable conformance for `NegatedConditionError`
public func == (lhs: NegatedConditionError, rhs: NegatedConditionError) -> Bool {
    switch (lhs, rhs) {
    case let (.ConditionSatisfied(aString), .ConditionSatisfied(bString)):
        return aString == bString
    }
}
