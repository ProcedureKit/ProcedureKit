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

    public var name: String {
        return "MutuallyExclusive<\(T.self)>"
    }

    public var isMutuallyExclusive = true

    public init() { }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(.Satisfied)
    }
}

/**
    A non-constructible type to be used with `MutuallyExclusive<T>`
*/
public enum Alert { }

/// A condition to indicate that the associated operation may present an alert
public typealias AlertPresentation = MutuallyExclusive<Alert>
