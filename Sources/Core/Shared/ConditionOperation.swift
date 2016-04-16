//
//  ConditionOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/04/2016.
//
//

import Foundation


/**
 Condition Operation

 Conditions are a core feature of this framework. Multiple
 instances can be attached to an `Operation` subclass, whereby they
 are evaluated to determine whether or not the target operation is
 executed.

 ConditionOperation is also an Operation subclass, which means that it
 also benefits from all the features of Operation, namely dependencies,
 observers, and yes, conditions. This means that your conditions could
 have conditions. This allows for expressing incredibly rich control logic.

 Additionally, conditions are evaluated asynchronously, and indicate
 failure by passing an ConditionResult enum back.

 */
public class ConditionOperation: Operation {
    public typealias CompletionBlockType = ConditionResult -> Void

    public var isMutuallyExclusive: Bool = false

    internal var operation: Operation? = .None

    public final override func execute() {
        guard let operation = operation else {
            assertionFailure("ConditionOperation executed before operation set.")
            finish()
            return
        }
        evaluate(operation, completion: finish)
    }

    /**
     Subclasses must override this method, but should not call super.
     - parameter operation: the Operation instance the condition was attached to
     - parameter completion: a completion block which receives a ConditionResult argument.
    */
    public func evaluate(operation: Operation, completion: CompletionBlockType) {
        assertionFailure("ConditionOperation must be subclasses, and \(#function) overridden.")
        completion(.Failed(OperationError.ConditionFailed))
    }

    internal func finish(result: ConditionResult) {
        finish(result.error)
    }

    internal func dependenciesNotYetAddedToQueue() -> [NSOperation] {
        return dependencies.filter { !$0.executing && !$0.finished }
    }
}

internal class WrappedOperationCondition: ConditionOperation {

    let condition: OperationCondition

    init(_ condition: OperationCondition) {
        self.condition = condition
        super.init()
        isMutuallyExclusive = condition.isMutuallyExclusive
        name = condition.name
    }

    override func evaluate(operation: Operation, completion: CompletionBlockType) {
        condition.evaluateForOperation(operation, completion: completion)
    }
}
