//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

/**
 The result of a Condition. Either the condition is satisfied,
 indicated by `.satisfied` or it has failed. In the failure
 case, an `Error` must be associated with the result.
 */
public enum ConditionResult {

    /// Indicates that the condition is pending
    case pending

    /// Indicates that the condition is satisfied
    case satisfied

    /// Indicates that the condition failed, but can be ignored
    case ignored

    /// Indicates that the condition failed with an associated error.
    case failed(Error)
}

public extension ConditionResult {

    var error: Error? {
        guard case .failed(let error) = self else { return nil }
        return error
    }
}

public protocol ConditionProtocol: ProcedureProtocol {

    var mutuallyExclusive: Bool { get set }

    func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void)
}

internal extension ConditionProtocol {

    var category: String {
        return String(describing: type(of: self))
    }
}

// MARK: Condition Errors

public extension ProcedureKitError {

    public struct FalseCondition: Error {
        internal init() { }
    }
}

open class Condition: Procedure, ConditionProtocol {

    public var mutuallyExclusive: Bool = false

    internal weak var procedure: Procedure? = nil {
        didSet {
            if let severity = procedure?.log.severity {
                log.severity = severity
            }
        }
    }

    public var result: ConditionResult = .pending

    open override func execute() {
        guard let procedure = procedure else {
            log.verbose(message: "Condition finishing before evaluation because procedure is nil.")
            finish()
            return
        }
        evaluate(procedure: procedure, completion: finish)
    }

    open func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.failed(ProcedureKitError.programmingError(reason: "Condition must be subclassed, and \(#function) overridden.")))
    }

    internal func finish(withConditionResult conditionResult: ConditionResult) {
        result = conditionResult
        finish(withError: conditionResult.error)
    }
}

public class TrueCondition: Condition {

    public init(name: String = "TrueCondition", mutuallyExclusive: Bool = false) {
        super.init()
        self.name = name
        self.mutuallyExclusive = mutuallyExclusive
    }

    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.satisfied)
    }
}

public class FalseCondition: Condition {

    public init(name: String = "FalseCondition", mutuallyExclusive: Bool = false) {
        super.init()
        self.name = name
        self.mutuallyExclusive = mutuallyExclusive
    }

    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.failed(ProcedureKitError.FalseCondition()))
    }
}

/**
 Class which can be used to compose a Condition, it is designed to be subclassed.

 This can be useful to automatically manage the dependency and automatic
 injection of the composed condition result for evaluation inside your custom subclass.

 - see: NegatedCondition
 - see: SilentCondition
 */
open class ComposedCondition<C: Condition>: Condition {

    /**
     The composed condition.

     - parameter condition: a the composed `Condition`
     */
    public let condition: C

    override var directDependencies: Set<Operation> {
        return super.directDependencies.union(condition.directDependencies)
    }

    public var requirement: ConditionResult = .pending

    override var procedure: Procedure? {
        didSet {
            condition.procedure = procedure
        }
    }

    /**
     Initializer which receives a conditon.

     - parameter [unnamed]: a nested `Condition` type.
     */
    public init(_ condition: C) {
        self.condition = condition
        super.init()
        mutuallyExclusive = condition.mutuallyExclusive
        name = condition.name
        inject(dependency: condition) { procedure, condition, _ in
            procedure.requirement = condition.result
        }
    }

    /// Override of public function
    open override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(requirement)
    }

    override func remove(directDependency: Operation) {
        condition.remove(directDependency: directDependency)
        super.remove(directDependency: directDependency)
    }
}

public class IgnoredCondition<C: Condition>: ComposedCondition<C> {

    /// Public override of initializer.
    public override init(_ condition: C) {
        super.init(condition)
        name = condition.name.map { "Ignored<\($0)>" }
    }

    /// Override of public function
    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        super.evaluate(procedure: procedure) { composedResult in
            if case .failed(_) = composedResult {
                completion(.ignored)
            }
            else {
                completion(composedResult)
            }
        }
    }
}
