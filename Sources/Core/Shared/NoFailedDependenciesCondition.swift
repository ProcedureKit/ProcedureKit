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
public class NoFailedDependenciesCondition: Condition {

    /// The `ErrorType` returned to indicate the condition failed.
    public enum Error: ErrorType, Equatable {

        /// When some dependencies were cancelled
        case CancelledDependencies

        /// When some dependencies failed with errors
        case FailedDependencies
    }

    /// Options on how to handle cancellation
    enum CancellationOptions {

        /// Indicates that cancelled dependencies
        /// would trigger a failed condition
        case Fail

        /// Indicates that cancelled dependencies
        /// would trigger an ignored condition
        case Ignore
    }

    let cancellationOptions: CancellationOptions

    /// Initializer which takes no parameters.
    public init(ignoreCancellations: Bool = false) {
        cancellationOptions = ignoreCancellations ? .Ignore : .Fail
        super.init()
        name = "No Failed Dependencies"
        mutuallyExclusive = false
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
    public override func evaluate(operation: Operation, completion: CompletionBlockType) {
        let dependencies = operation.dependencies
        let cancelled = dependencies.filter { $0.cancelled }
        let failures = dependencies.filter {
            if let operation = $0 as? Operation {
                return operation.failed
            }
            return false
        }

        switch cancellationOptions {
        case _ where !failures.isEmpty:
            completion(.Failed(Error.FailedDependencies))
        case .Fail where !cancelled.isEmpty:
            completion(.Failed(Error.CancelledDependencies))
        case .Ignore where !cancelled.isEmpty:
            completion(.Ignored)
        default:
            completion(.Satisfied)
        }
    }
}

/// Equatable conformance for `NoFailedDependenciesCondition.Error`
public func == (lhs: NoFailedDependenciesCondition.Error, rhs: NoFailedDependenciesCondition.Error) -> Bool {
    switch (lhs, rhs) {
    case (.CancelledDependencies, .CancelledDependencies), (.FailedDependencies, .FailedDependencies):
        return true
    default:
        return false
    }
}
