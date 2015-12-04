//
//  MutuallyExclusive.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A generic condition for describing operations that
cannot be allowed to execute concurrently.
*/
public struct MutuallyExclusive<T>: OperationCondition {

    /**
    The name of the condition wraps the name of the generic
    OperationCondition.

    - parameter name: a String
    */
    public var name: String {
        return "MutuallyExclusive<\(T.self)>"
    }

    /**
    The mututally exclusivity parameter which is always true.

    - parameter isMutuallyExclusive: a constant Bool, true.
    */
    public let isMutuallyExclusive = true

    /// Public constructor
    public init() { }

    /// Conforms to `OperationCondition`, but there are no dependencies, so it returns .None.
    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    /// Conforms to `OperationCondition`, but there is no evaluation, so it just completes with `.Satisfied`.
    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(.Satisfied)
    }
}

/// A non-constructible type to be used with `MutuallyExclusive<T>`
public enum Alert { }

/// A condition to indicate that the associated operation may present an alert
public typealias AlertPresentation = MutuallyExclusive<Alert>
