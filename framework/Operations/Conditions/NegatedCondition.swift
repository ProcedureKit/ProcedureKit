//
//  NegatedCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 26/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public enum NegatedConditionError: ErrorType, Equatable {
    case ConditionSatisfied(String)
}

/**
    A simple condition with negates the evaluation of
    a composed condition.
*/
public struct NegatedCondition<Condition: OperationCondition>: OperationCondition {
    
    public let condition: Condition
    
    public var name: String {
        return "Not<\(condition.name)>"
    }
    
    public var isMutuallyExclusive: Bool {
        return condition.isMutuallyExclusive
    }
    
    public init(_ c: Condition) {
        condition = c
    }
    
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return condition.dependencyForOperation(operation)
    }
    
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

public func ==(a: NegatedConditionError, b: NegatedConditionError) -> Bool {
    switch (a, b) {
    case let (.ConditionSatisfied(aString), .ConditionSatisfied(bString)):
        return aString == bString
    default:
        return false
    }
}
