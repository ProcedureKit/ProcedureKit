//
//  ConditionOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/04/2016.
//
//

import Foundation

public protocol ConditionType {

    var mutuallyExclusive: Bool { get set }

    func evaluate(operation: Operation, completion: ConditionResult -> Void)

}

internal extension ConditionType {

    internal var category: String {
        return "\(self.dynamicType)"
    }
}

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
public class Condition: Operation, ConditionType, ResultOperationType {
    public typealias CompletionBlockType = ConditionResult -> Void

    public var mutuallyExclusive: Bool = false

    internal weak var operation: Operation? = .None

    public var result: ConditionResult! = nil

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

    internal func finish(conditionResult: ConditionResult) {
        self.result = conditionResult
        finish(conditionResult.error)
    }
}

internal class WrappedOperationCondition: Condition {

    let condition: OperationCondition

    var category: String {
        return "\(condition.dynamicType)"
    }

    init(_ condition: OperationCondition) {
        self.condition = condition
        super.init()
        mutuallyExclusive = condition.isMutuallyExclusive
        name = condition.name
    }

    override func evaluate(operation: Operation, completion: CompletionBlockType) {
        condition.evaluateForOperation(operation, completion: completion)
    }
}

extension Array where Element: NSOperation {

    internal var conditions: [Condition] {
        return flatMap { $0 as? Condition }
    }
}
