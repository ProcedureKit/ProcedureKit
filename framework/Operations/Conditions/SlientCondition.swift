//
//  SlientCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
    A simple condition which suppresses it's contained condition to not
    enqueue its dependency. This is useful for verifying access to
    a resoource without prompting for permission.
*/
public struct SilentCondition<Condition: OperationCondition>: OperationCondition {

    public let condition: Condition

    public var name: String {
        return "Silent \(condition.name)"
    }

    public var isMutuallyExclusive: Bool {
        return condition.isMutuallyExclusive
    }

    public init(_ c: Condition) {
        condition = c
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        // Returning nil here supresses the enqueing of another operation.
        return .None
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        condition.evaluateForOperation(operation, completion: completion)
    }
}

