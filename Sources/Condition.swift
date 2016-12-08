//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public typealias ConditionResult = ProcedureResult<Bool>

public protocol ConditionProtocol: ProcedureProtocol {

    var mutuallyExclusiveCategory: String? { get }

    func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void)
}

public extension ConditionProtocol {

    var isMutuallyExclusive: Bool {
        return mutuallyExclusiveCategory != nil
    }

    var category: String {
        return mutuallyExclusiveCategory ?? String(describing: type(of: self))
    }
}

// MARK: Condition Errors

public extension ProcedureKitError {

    public struct FailedConditions: Error {
        public let errors: [Error]

        internal init(errors: [Error]) {
            self.errors = errors
        }

        internal func append(error: Error) -> FailedConditions {
            var errors = self.errors
            if let failedConditions = error as? FailedConditions {
                errors.append(contentsOf: failedConditions.errors)
            }
            else {
                errors.append(error)
            }
            return FailedConditions(errors: errors)
        }
    }

    public struct FalseCondition: Error {
        internal init() { }
    }
}

open class Condition: Procedure, ConditionProtocol, OutputProcedure {

    public var mutuallyExclusiveCategory: String? = nil

    internal weak var procedure: Procedure? = nil {
        didSet {
            if let severity = procedure?.log.severity {
                log.severity = severity
            }
        }
    }

    /// The ConditionResult.
    /// Will be Pending.ready(ConditionResult) once the Condition has been evaluated.
    public var output: Pending<ConditionResult> = .pending

    /// Triggers evaluation of the Condition, unless the procedure no longer exists. Cannot be over-ridden
    final public override func execute() {
        guard let procedure = procedure else {
            log.verbose(message: "Condition finishing before evaluation because procedure is nil.")
            finish()
            return
        }
        evaluate(procedure: procedure, completion: finish)
    }

    /// Must be overriden in Condition subclasses.
    /// Must always call `completion` with the result.
    open func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        let reason = "Condition must be subclassed, and \(#function) overridden."
        let result: ConditionResult = .failure(ProcedureKitError.programmingError(reason: reason))
        output = .ready(result)
        completion(result)
    }

    final internal func finish(withConditionResult conditionResult: ConditionResult) {
        output = .ready(conditionResult)
        finish(withError: conditionResult.error)
    }
}

public class TrueCondition: Condition {

    public init(name: String = "TrueCondition", mutuallyExclusiveCategory: String? = nil) {
        super.init()
        self.name = name
        self.mutuallyExclusiveCategory = mutuallyExclusiveCategory
    }

    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.success(true))
    }
}

public class FalseCondition: Condition {

    public init(name: String = "FalseCondition", mutuallyExclusiveCategory: String? = nil) {
        super.init()
        self.name = name
        self.mutuallyExclusiveCategory = mutuallyExclusiveCategory
    }

    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.failure(ProcedureKitError.FalseCondition()))
    }
}

/**
 Class which can be used to compose a Condition, it is designed to be subclassed.

 This can be useful to automatically manage the dependency and automatic
 injection of the composed condition result for evaluation inside your custom subclass.

 - see: NegatedCondition
 - see: SilentCondition
 */
open class ComposedCondition<C: Condition>: Condition, InputProcedure {

    /**
     The composed condition.

     - parameter condition: a the composed `Condition`
     */
    public let condition: C

    override var directDependencies: Set<Operation> {
        return super.directDependencies.union(condition.directDependencies)
    }

    public var input: Pending<ConditionResult> = .pending

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
        mutuallyExclusiveCategory = condition.mutuallyExclusiveCategory
        name = condition.name
        inject(dependency: condition) { procedure, condition, _ in
            procedure.input = condition.output
        }
    }

    /// Override of public function
    open override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        guard let result = input.value else {
            completion(.failure(ProcedureKitError.requirementNotSatisfied()))
            return
        }
        completion(result)
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
            if case .failure(_) = composedResult {
                completion(.success(false))
            }
            else {
                completion(composedResult)
            }
        }
    }
}
