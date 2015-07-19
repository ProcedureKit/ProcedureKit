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
struct SilentCondition<Condition: OperationCondition>: OperationCondition {
    let condiiton: Condition

    static var name: String {
        return "Silent \(Condition.name)"
    }

    static var isMutuallyExclusive: Bool {
        return Condition.isMutuallyExclusive
    }

    init(_ c: Condition) {
        condiiton = c
    }

    func dependencyForOperation(operation: Operation) -> NSOperation? {
        // Returning nil here supresses the enqueing of another operation.
        return .None
    }

    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        condiiton.evaluateForOperation(operation, completion: completion)
    }
}

