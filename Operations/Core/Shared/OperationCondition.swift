//
//  OperationCondition.swift
//  YapDB
//
//  Created by Daniel Thorpe on 25/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
The result of an OperationCondition. Either the condition is
satisfied, indicated by `.Satisfied` or it has failed. In the
failure case, an `ErrorType` must be associated with the result.
*/
public enum OperationConditionResult {

    /// Indicates that the condition is satisfied
    case Satisfied

    /// Indicates that the condition failed with an associated error.
    case Failed(ErrorType)
}

/**
Types which conform to `OperationCondition` can be added to `Operation` 
subclasses before they are added to an `OperationQueue`. If the condition
returns an `NSOperation` dependency, the dependency relationship will be
set and it is added to the queue automatically.

Evaluation of the condition only occurs once the dependency has executed.

It is possible to support asynchronous evaluation of the condition, as the
results, an `OperationConditionResult` is returned in a completion block.
*/
public protocol OperationCondition {

    /**
    The name of the condition.

    - parameter name: a String
    */
    var name: String { get }

    /**
    A flag to indicate whether this condition is mutually exclusive. Meaning
    that only one condition can be evaluated at a time. Other `Operation` 
    instances which have this condition will wait in a `.Pending` state - i.e.
    not get executed.

    - parameter isMutuallyExclusive: a Bool
    */
    var isMutuallyExclusive: Bool { get }

    /**
    Some conditions may have the ability to satisfy the condition
    if another operation is executed first. Use this method to return
    an operation that (for example) asks for permission to perform 
    the operation.

    - parameter operation: The `Operation` to which the condition has been added.
    - returns: An `NSOperation`, if a dependency should be automatically added.
    - note: Only a single operation may be returned.

    */
    func dependencyForOperation(operation: Operation) -> NSOperation?

    /**
    Evaluate the condition, to see if it has been satisfied.
    
    - parameter operation: the `Operation` which this condition is attached to.
    - parameter completion: a closure which receives an `OperationConditionResult`.
    */
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void)
}


struct OperationConditionEvaluator {

    static func evaluate(conditions: [OperationCondition], operation: Operation, completion: [ErrorType] -> Void) {

        let group = dispatch_group_create()

        var results = [OperationConditionResult?](count: conditions.count, repeatedValue: .None)

        for (index, condition) in conditions.enumerate() {
            dispatch_group_enter(group)
            condition.evaluateForOperation(operation) { result in
                results[index] = result
                dispatch_group_leave(group)
            }
        }

        dispatch_group_notify(group, Queue.Default.queue) {

            var failures: [ErrorType] = results.reduce([ErrorType]()) { (var acc, result) in
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

