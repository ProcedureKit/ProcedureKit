//
//  OperationCondition.swift
//  YapDB
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public let OperationConditionKey = "OperationCondition"

public enum OperationConditionResult {
    case Satisfied
    case Failed(ErrorType)
}

public protocol OperationCondition {

    var name: String { get }

     var isMutuallyExclusive: Bool { get }

    /**
    Some conditions may have the ability to satisfy the condition
    if another operation is executed first. Use this method to return
    an operation that (for example) asks for permission to perform 
    the operation.

    - paramter operation: The `Operation` to which the condition has been added.
    - returns: An `NSOperation`, if a dependency should be automatically added.
    - note: Only a single operation may be returned.

    */
    func dependencyForOperation(operation: Operation) -> NSOperation?

    /// Evaluate the condition, to see if it has been satisfied.
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void)
}


struct OperationConditionEvaluator {

    static func evaluate(conditions: [OperationCondition], operation: Operation, completion: [ErrorType] -> Void) {

        let group = dispatch_group_create()

        var results = [OperationConditionResult?](count: conditions.count, repeatedValue: .None)

        for (index, condition) in enumerate(conditions) {
            dispatch_group_enter(group)
            condition.evaluateForOperation(operation) { result in
                results[index] = result
                dispatch_group_leave(group)
            }
        }

        dispatch_group_notify(group, Queue.Default.queue) {

            var failures: [ErrorType] = reduce(results, [ErrorType]()) { (var acc, result) in
                if let error = result?.error {
                    acc.append(error)
                }
                return acc
            }

            if operation.cancelled {
                failures.append(OperationError.ConditionFailed)
            }

            completion(failures)
        }
    }
}


extension OperationConditionResult {

    var error: ErrorType? {
        switch self {
        case .Failed(let error):
            return error
        default:
            return .None
        }
    }
}

