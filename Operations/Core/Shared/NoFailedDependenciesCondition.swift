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

    /// The `ErrorType` returned to indicate the condition failed.
    public enum Error: ErrorType, Equatable {

        /// When some dependencies were cancelled
        case CancelledDependencies

        /// When some dependencies failed with errors
        case FailedDependencies
    }

    /// A constant name for the condition.
    public let name = "No Cancelled Condition"

    /// A constant flag indicating this condition is not mutually exclusive
    public let isMutuallyExclusive = false

    /// Initializer which takes no parameters.
    public init() { }

    /// Conforms to `OperationCondition` but there are no dependent operations.
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    /**
    Evaluates the operation with respect to the finished status of its dependencies.
    
    The condition first checks if any dependencies were cancelled, in which case it 
    fails with an `NoFailedDependenciesCondition.Error.CancelledDependencies`. Then
    it checks to see if any dependencies failed due to errors, in which case it
    fails with an `NoFailedDependenciesCondition.Error.FailedDependencies`.
    
    The cancelled or failed operations are no associated with the error.

    - parameter operation: the `Operation` which the condition is attached to.
    - parameter completion: the completion block which receives a `OperationConditionResult`.
    */
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let dependencies = operation.dependencies

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

/// Equatable conformance for `NoFailedDependenciesCondition.Error`
public func ==(a: NoFailedDependenciesCondition.Error, b: NoFailedDependenciesCondition.Error) -> Bool {
    switch (a, b) {
    case (.CancelledDependencies, .CancelledDependencies), (.FailedDependencies, .FailedDependencies):
        return true
    default:
        return false
    }
}

