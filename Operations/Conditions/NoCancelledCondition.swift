//
//  NoCancelledCondition.swift
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
public struct NoCancelledCondition: OperationCondition {

    public enum Error: ErrorType, Equatable {
        case CancelledDependencies
    }

    public let name = "No Cancelled Condition"
    public let isMutuallyExclusive = false

    public init() { }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let cancelled = (operation.dependencies as! [NSOperation]).filter { $0.cancelled }

        if !cancelled.isEmpty {
            completion(.Failed(Error.CancelledDependencies))
        }
        else {
            completion(.Satisfied)
        }
    }
}

public func ==(a: NoCancelledCondition.Error, b: NoCancelledCondition.Error) -> Bool {
    switch (a, b) {
    case (.CancelledDependencies, .CancelledDependencies):
        return true
    default:
        return false
    }
}

