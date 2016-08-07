//
//  ConditionOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/04/2016.
//
//

import Foundation

/**
 The result of an OperationCondition. Either the condition is
 satisfied, indicated by `.Satisfied` or it has failed. In the
 failure case, an `ErrorType` must be associated with the result.
 */
public enum ConditionResult {

    /// Indicates that the condition is satisfied
    case Satisfied

    /// Indicates that the condition failed, but can be ignored
    case Ignored

    /// Indicates that the condition failed with an associated error.
    case Failed(ErrorType)
}

internal extension ConditionResult {

    var error: ErrorType? {
        switch self {
        case .Failed(let error):
            return error
        default:
            return .None
        }
    }
}

public protocol ConditionType {

    var mutuallyExclusive: Bool { get set }

    func evaluate(operation: Operation, completion: ConditionResult -> Void)
}

internal extension ConditionType {

    internal var category: String {
        return "\(self.dynamicType)"
    }
}

/// General Errors used by conditions
public enum ConditionError: ErrorType, Equatable {

    /// A FalseCondition may use this as the error
    case FalseCondition

    /**
     If the block returns false, the operation to
     which it is attached will fail with this error.
     */
    case BlockConditionFailed
}

public func == (lhs: ConditionError, rhs: ConditionError) -> Bool {
    switch (lhs, rhs) {
    case (.FalseCondition, .FalseCondition), (.BlockConditionFailed, .BlockConditionFailed):
        return true
    default:
        return false
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
        assertionFailure("ConditionOperation must be subclassed, and \(#function) overridden.")
        completion(.Failed(OperationError.ConditionFailed))
    }

    internal func finish(conditionResult: ConditionResult) {
        self.result = conditionResult
        finish(conditionResult.error)
    }
}

public class TrueCondition: Condition {

    public init(name: String = "True Condition", mutuallyExclusive: Bool = false) {
        super.init()
        self.name = name
        self.mutuallyExclusive = mutuallyExclusive
    }

    public override func evaluate(operation: Operation, completion: CompletionBlockType) {
        completion(.Satisfied)
    }
}

public class FalseCondition: Condition {

    public init(name: String = "False Condition", mutuallyExclusive: Bool = false) {
        super.init()
        self.name = name
        self.mutuallyExclusive = mutuallyExclusive
    }

    public override func evaluate(operation: Operation, completion: CompletionBlockType) {
        completion(.Failed(ConditionError.FalseCondition))
    }
}

/**
 Class which can be used to compose a Condition, it is designed to be subclassed.

 This can be useful to automatically manage the dependency and automatic
 injection of the composed condition result for evaluation inside your custom subclass.

 - see: NegatedCondition
 - see: SilentCondition
 */
public class ComposedCondition<C: Condition>: Condition, AutomaticInjectionOperationType {

    /**
     The composed condition.

     - parameter condition: a the composed `Condition`
     */
    public let condition: C

    override var directDependencies: Set<NSOperation> {
        return super.directDependencies.union(condition.directDependencies)
    }

    /// Conformance to `AutomaticInjectionOperationType`
    public var requirement: ConditionResult! = nil

    override var operation: Operation? {
        didSet {
            condition.operation = operation
        }
    }

    /**
     Initializer which receives a conditon which is to be negated.

     - parameter [unnamed]: a nested `Condition` type.
     */
    public init(_ condition: C) {
        self.condition = condition
        super.init()
        mutuallyExclusive = condition.mutuallyExclusive
        name = condition.name
        injectResultFromDependency(condition) { operation, dependency, _ in
            operation.requirement = dependency.result
        }
    }

    /// Override of public function
    public override func evaluate(operation: Operation, completion: CompletionBlockType) {
        guard let result = requirement else {
            completion(.Failed(AutomaticInjectionError.RequirementNotSatisfied))
            return
        }
        completion(result)
    }

    override func removeDirectDependency(directDependency: NSOperation) {
        condition.removeDirectDependency(directDependency)
        super.removeDirectDependency(directDependency)
    }
}

public class IgnoredCondition<C: Condition>: ComposedCondition<C> {


    /// Public override of initializer.
    public override init(_ condition: C) {
        super.init(condition)
        name = condition.name.map { "Ignored<\($0)>" }
    }

    /// Override of public function
    public override func evaluate(operation: Operation, completion: CompletionBlockType) {
        super.evaluate(operation) { composedResult in
            if case .Failed(_) = composedResult {
                completion(.Ignored)
            }
            else {
                completion(composedResult)
            }
        }
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
