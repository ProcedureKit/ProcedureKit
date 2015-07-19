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
struct MutuallyExclusive<T>: OperationCondition {

    static var name: String {
        return "MutuallyExclusive<\(T.self)>"
    }

    static var isMutuallyExclusive: Bool {
        return true
    }

    init() { }

    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        completion(.Satisfied)
    }
}

/**
    A non-constructible type to be used with `MutuallyExclusive<T>`
*/
enum Alert { }

/// A condition to indicate that the associated operation may present an alert
typealias AlertPresentation = MutuallyExclusive<Alert>
