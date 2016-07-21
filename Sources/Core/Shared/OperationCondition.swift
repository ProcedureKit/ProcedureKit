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
public enum ConditionResult {

    /// Indicates that the condition is satisfied
    case satisfied

    /// Indicates that the condition failed with an associated error.
    case failed(ErrorProtocol)
}

internal extension ConditionResult {

    var error: ErrorProtocol? {
        switch self {
        case .failed(let error):
            return error
        default:
            return .none
        }
    }
}

public typealias OperationConditionResult = ConditionResult

/**
Types which conform to `OperationCondition` can be added to `Procedure`
subclasses before they are added to an `OldOperationQueue`. If the condition
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
    that only one condition can be evaluated at a time. Other `Procedure`
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

    - parameter operation: The `Procedure` to which the condition has been added.
    - returns: An `NSOperation`, if a dependency should be automatically added.
    - note: Only a single operation may be returned.

    */
    func dependencyForOperation(_ operation: Procedure) -> Operation?

    /**
    Evaluate the condition, to see if it has been satisfied.

    - parameter operation: the `Procedure` which this condition is attached to.
    - parameter completion: a closure which receives an `OperationConditionResult`.
    */
    func evaluateForOperation(_ operation: Procedure, completion: (OperationConditionResult) -> Void)
}

internal func evaluateOperationConditions(_ conditions: [OperationCondition], operation: Procedure, completion: ([ErrorProtocol]) -> Void) {

    let group = DispatchGroup()

    var results = [OperationConditionResult?](repeating: .none, count: conditions.count)

    for (index, condition) in conditions.enumerated() {
        group.enter()
        condition.evaluateForOperation(operation) { result in
            results[index] = result
            group.leave()
        }
    }

    group.notify(queue: Queue.default.queue) {

        var failures: [ErrorProtocol] = results.flatMap { $0?.error }

        if operation.isCancelled {
            failures.append(OperationError.conditionFailed)
        }

        completion(failures)
    }
}
