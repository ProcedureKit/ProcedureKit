//
//  NoFailedDependenciesCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A condition that specificed that every dependency of the
operation must succeed. If any dependency fails/cancels,
the target operation will be fail.
*/
public struct NoFailedDependenciesCondition: OperationCondition {

    public enum Error: ErrorType, Equatable {
        case CancelledDependencies
        case FailedDependencies
    }

    public let name = "No Cancelled Condition"
    public let isMutuallyExclusive = false

    public init() { }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let dependencies = operation.dependencies as! [NSOperation]

        let cancelled = dependencies.filter { $0.cancelled }
        let failures = dependencies.filter {
            if let operation = $0 as? Operation {
                return operation.failed
            }
            return false
        }

        if !cancelled.isEmpty {
            completion(.Failed(Error.CancelledDependencies))
        }
        else if !failures.isEmpty {
            completion(.Failed(Error.FailedDependencies))
        }
        else {
            completion(.Satisfied)
        }
    }
}

public func ==(a: NoFailedDependenciesCondition.Error, b: NoFailedDependenciesCondition.Error) -> Bool {
    switch (a, b) {
    case (.CancelledDependencies, .CancelledDependencies):
        return true
    case (.FailedDependencies, .FailedDependencies):
        return true
    default:
        return false
    }
}

