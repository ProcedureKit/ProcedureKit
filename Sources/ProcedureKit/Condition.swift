//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

// swiftlint:disable file_length

import Foundation

/**
 ConditionResult encompasses 3 states:
 1. `.success(true)`
 2. `.success(false)`
 3. `.failure(let error)`

 Generally:
 - If a Condition succeeds, return `.success(true)`.
 - If a Condition *fails*, return `.failure(error)` with a unique error
 defined for your Condition.

 In some situations, it can be beneficial for a Procedure to not collect an
 error if an attached condition fails. You can use `IgnoredCondition` to
 suppress the error associated with any Condition. This is generally
 preferred to returning `.success(false)` directly.
 */
public typealias ConditionResult = ProcedureResult<Bool>

public protocol ConditionProtocol: Hashable {

    /// Dependencies to produce and wait on.
    ///
    /// The framework will automatically schedule these dependencies to run
    /// after all dependencies on the attached Procedure, and will wait for
    /// these dependencies to finish before the Condition's
    /// `evaluate(procedure:completion:)` function is called.
    ///
    /// It is programmer error to add an Operation to the `producedDependencies`
    /// this is already scheduled for execution or executing, or that will be
    /// scheduled for execution elsewhere.
    var producedDependencies: Set<Operation> { get }

    /// Dependencies to wait on.
    ///
    /// The framework will wait for these dependencies to finish
    /// before the Condition's `evaluate(procedure:completion:)`
    /// function is called.
    var dependencies: Set<Operation> { get }

    /// Mutually exclusive categories to apply to the attached Procedure.
    ///
    /// Only one Procedure with a particular mutuallyExclusiveCategory may
    /// execute at a time.
    var mutuallyExclusiveCategories: Set<String> { get }

    /// Called before a Condition is added to a Procedure.
    ///
    /// - Parameter procedure: the Procedure to which the Condition is being added
    func willAttach(to procedure: Procedure)

    /// Called to evaluate the Condition on a Procedure.
    /// Must always call `completion` with the result.
    func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void)
}

public extension ConditionProtocol {

    var isMutuallyExclusive: Bool {
        return !mutuallyExclusiveCategories.isEmpty
    }
}

// MARK: Condition Errors

public extension ProcedureKitError {

    struct FailedConditions: Error {
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

    struct FalseCondition: Error, Equatable {
        public init() { }
    }

    struct ConditionEvaluationCancelled: Error {
        public init() { }
    }

    struct ConditionDependenciesFailed: Error, Equatable, CustomStringConvertible {

        public let condition: Condition

        internal init(condition: Condition) {
            self.condition = condition
        }

        public var description: String {
            return "ProcedureKitError.ConditionDependenciesFailed(condition: \(condition))"
        }
    }

    struct ConditionDependenciesCancelled: Error, Equatable, CustomStringConvertible {

        public let condition: Condition

        internal init(condition: Condition) {
            self.condition = condition
        }

        public var description: String {
            return "ProcedureKitError.ConditionDependenciesCancelled(condition: \(condition))"
        }
    }
}

/**
 Conditions are attached to a Procedure. Before a Procedure executes, it will
 asynchronously evaluate all of its conditions. If a condition fails, the
 Procedure cancels with an error instead of executing.

 For example:
 ```swift
 procedure.add(condition: BlockCondition {
     // procedure will cancel instead of executing if this is false
     return trueOrFalse
 })
 ```

 Conditions are evaluated after all of the Procedure's dependencies have finished.

 A Condition can also produce its own dependencies, which are executed after the
 Procedure's dependencies have finished, but _prior_ to evaluating the Condition.
 Thus, if a crucial detail must be set to satisfy the condition, it can be
 performed in its own Operation / Procedure.

 ProcedureKit has several built-in Conditions, like `BlockCondition` and
 `MutuallyExclusive<T>`. It is also easy to implement your own.

 ## Implementing a Custom Condition

 First, subclass `Condition`. Then, override `evaluate(procedure:completion:)`.
 Here is a simple example - a FalseCondition that always fails:

 ```swift
 public class FalseCondition: Condition {
     public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.failure(ProcedureKitError.FalseCondition()))
     }
 }
 ```

 ### Calling the Completion Block

 Your `evaluate(procedure:completion:)` override *must* eventually call the
 completion block with a `ConditionResult`. (Although it may, of course, be
 called asynchronously.)

 `ConditionResult` encompasses 3 states:
 1. `.success(true)`
 2. `.success(false)`
 3. `.failure(let error: Error)`

 Generally:
 - If a Condition *succeeds*, return `.success(true)`.
 - If a Condition *fails*, return `.failure(error)` with a unique error
 defined for your Condition.

 In some situations, it can be beneficial for a Procedure to not collect an
 error if an attached condition fails. You can use `IgnoredCondition` to
 suppress the error associated with any Condition. This is generally
 preferred to returning `.success(false)` directly.
 */
open class Condition: ConditionProtocol, Hashable {

    /// Requirements to be verified of all Condition dependencies once they are finished
    /// (and before the Condition's evaluate method is called).
    ///
    /// Failures are evaluated before cancellations. Thus, if [.noFailed, .noCancelled] is specified:
    /// 1. You will receive `ProcedureKitError.ConditionDependenciesFailed` if any Conditions finished
    /// with errors (i.e. failed).
    /// 2. If not, you will receive `ProcedureKitError.ConditionDependenciesCancelled` if any
    /// dependencies are cancelled.
    ///
    /// - noFailed: Verifies that no dependencies have finished with errors. If any dependencies have, the Condition fails with a `ProcedureKitError.ConditionDependenciesFailed` error.
    /// - ignoreFailedIfCancelled: Does not consider a dependency to have failed if it's cancelled. (To be used with .noFailed.)
    ///
    /// - noCancelled: Verifies that no dependencies are cancelled. If any dependencies are cancelled, the Condition fails with a `ProcedureKitError.ConditionDependenciesCancelled` error.
    ///
    /// - noFailedOrCancelled: [.noFailed, .noCancelled] (Verifies that no dependencies are failed nor cancelled.)
    /// - none: Do not automatically verify any properties of the dependencies once they are finished.
    public struct DependencyRequirements: OptionSet {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }

        public static let noFailed                  = DependencyRequirements(rawValue: 1 << 0)
        public static let ignoreFailedIfCancelled   = DependencyRequirements(rawValue: 1 << 1)
        public static let noCancelled               = DependencyRequirements(rawValue: 1 << 2)

        public static let noFailedOrCancelled: DependencyRequirements = [.noFailed, .noCancelled]
        public static let none: DependencyRequirements = []
    }

    fileprivate let stateLock = PThreadMutex()
    private weak var _procedure: Procedure?
    fileprivate var _name: String? // swiftlint:disable:this variable_name
    private var _dependencyRequirements: DependencyRequirements = .none
    fileprivate var _output: Pending<ConditionResult> = .pending // swiftlint:disable:this variable_name
    private var _producedDependencies = Set<Operation>()
    private var _dependencies = Set<Operation>()
    private var _mutuallyExclusiveCategories = Set<String>()

    fileprivate func synchronise<T>(block: () -> T) -> T {
        return stateLock.withCriticalScope(block: block)
    }

    /// Dependencies to produce and wait on.
    ///
    /// The framework will automatically schedule these dependencies to run
    /// after all dependencies on the attached `Procedure`, and will wait for
    /// these dependencies to finish before the Condition's
    /// `evaluate(procedure:completion:)` function is called.
    ///
    /// - IMPORTANT:
    /// It is programmer error to add an Operation to the `producedDependencies`
    /// that is already scheduled for execution or executing, or that will be
    /// scheduled for execution elsewhere.
    public var producedDependencies: Set<Operation> {
        return synchronise { _producedDependencies }
    }

    /// Dependencies to wait on, added via `add(dependency:)`.
    ///
    /// The framework will wait for these dependencies to finish
    /// before the Condition's `evaluate(procedure:completion:)`
    /// function is called.
    public var dependencies: Set<Operation> {
        return synchronise { _dependencies }
    }

    /// Mutually exclusive categories to apply to the attached Procedure.
    ///
    /// Only one Procedure with a particular mutuallyExclusiveCategory may
    /// execute at a time.
    public var mutuallyExclusiveCategories: Set<String> {
        return synchronise { _mutuallyExclusiveCategories }
    }

    /// A descriptive name for the Condition. (optional)
    public var name: String? {
        get { return synchronise { _name } }
        set { synchronise { _name = newValue } }
    }

    /// Requirements that must be satisfied after all dependencies are finished, before
    /// the Condition is evaluated by the framework.
    ///
    /// If the requirements fail, the Condition will fail. See `DependencyRequirements`.
    ///
    /// The default is ".none", which performs no checks on the dependencies after they
    /// are finished.
    ///
    /// - See: `DependencyRequirements`
    public var dependencyRequirements: DependencyRequirements {
        get { return synchronise { _dependencyRequirements } }
        set {
            synchronise {
                debugAssertConditionNotAttachedToProcedure("Dependency requirement must be modified before the Condition is added to a Procedure.")
                _dependencyRequirements = newValue
            }
        }
    }

    /// The ConditionResult.
    /// Will be Pending.ready(ConditionResult) once the Condition has been evaluated.
    public var output: Pending<ConditionResult> {
        return synchronise { _output }
    }

    public init() { }

    /// Called before a Condition is added to a Procedure.
    ///
    /// - Parameter procedure: the Procedure to which the Condition is being added
    public func willAttach(to procedure: Procedure) {
        synchronise {
            debugAssertConditionNotAttachedToProcedure("Cannot add a single Condition instance to multiple Procedures.")
            _procedure = procedure
        }
    }

    // MARK: Mutual Exclusivity

    /// Adds a mutually exclusive category to be applied to the attached Procedure.
    ///
    /// Only one Procedure with a particular mutuallyExclusiveCategory may execute at a time.
    ///
    /// - Parameter mutuallyExclusiveCategory: a String, which should be unique per category
    final public func addToAttachedProcedure(mutuallyExclusiveCategory: String) {
        synchronise {
            debugAssertConditionNotAttachedToProcedure("Categories must be modified before the Condition is added to a Procedure.")
            _mutuallyExclusiveCategories.insert(mutuallyExclusiveCategory)
        }
    }

    // MARK: Dependencies

    /// Produce a dependency that the `Condition` runs before evaluation.
    ///
    /// Dependencies produced in this way are scheduled after all dependencies on
    /// the attached `Procedure`, but prior to the `evaluate(procedure:completion)`
    /// method being called.
    ///
    /// The Condition "owns" the dependency, and the framework will handle
    /// scheduling and running the dependency at the appropriate time.
    /// - IMPORTANT: Do *not* separately add the dependency to your own queue.
    ///
    /// If you want to add a dependency that has been or will be separately added
    /// to a queue (or otherwise scheduled for execution), use `add(dependency:)` instead.
    ///
    /// - IMPORTANT:
    /// It is a programmer error to produce the same Operation instance on more than
    /// one `Condition` instance.
    ///
    /// - Parameter dependency: an Operation to be produced as a dependency
    final public func produceDependency(_ dependency: Operation) {
        assert(!dependency.isExecuting, "Do not call produce(dependency:) with an Operation that is already executing.")
        assert(!dependency.isFinished, "Do not call produce(dependency:) with an Operation that is already finished.")
        synchronise {
            debugAssertConditionNotAttachedToProcedure("Dependencies must be modified before the Condition is added to a Procedure.")
            _producedDependencies.insert(dependency)
        }
    }

    /// Adds a dependency, just like `Procedure.addDependency(_:)`.
    ///
    /// The framework will wait for the dependency to finish before the Condition's 
    /// `evaluate(procedure:completion:)` function is called.
    ///
    /// - IMPORTANT:
    /// Does not schedule the dependency for execution. You must do this elsewhere by,
    /// for example, adding it to an `OperationQueue` / `ProcedureQueue`.
    ///
    /// - Parameter dependency: an Operation to be added as a dependency
    final public func addDependency(_ dependency: Operation) {
        synchronise {
            debugAssertConditionNotAttachedToProcedure("Dependencies must be modified before the Condition is added to a Procedure.")
            _dependencies.insert(dependency)
        }
    }

    /// Add dependencies, just like `Procedure.addDependencies(_:)`.
    ///
    /// The framework will wait for the dependencies to finish before the Condition's
    /// `evaluate(procedure:completion:)` function is called.
    ///
    /// - IMPORTANT:
    /// Does not schedule the dependencies for execution. You must do this elsewhere by,
    /// for example, adding it to an `OperationQueue` / `ProcedureQueue`.
    ///
    /// - Parameter dependencies: an array of Operations to be added as a dependencies
    final public func addDependencies(_ dependencies: [Operation]) {
        synchronise {
            debugAssertConditionNotAttachedToProcedure("Dependencies must be modified before the Condition is added to a Procedure.")
            _dependencies.formUnion(dependencies)
        }
    }

    final public func addDependencies(_ dependencies: Operation...) {
        addDependencies(dependencies)
    }

    /// Removes a dependency.
    ///
    /// - Parameter dependency: an Operation to be removed from the `producedDependencies` and/or `dependencies`.
    public func removeDependency(_ dependency: Operation) {
        synchronise {
            debugAssertConditionNotAttachedToProcedure("Dependencies must be modified before the Condition is added to a Procedure.")
            _dependencies.remove(dependency)
            _producedDependencies.remove(dependency)
        }
    }

    /// Removes dependencies.
    ///
    /// - Parameter dependencies: an array of Operations to be removed from the `producedDependencies` and/or `dependencies`.
    public func removeDependencies(_ dependencies: [Operation]) {
        synchronise {
            debugAssertConditionNotAttachedToProcedure("Dependencies must be modified before the Condition is added to a Procedure.")
            dependencies.forEach {
                _dependencies.remove($0)
                _producedDependencies.remove($0)
            }
        }
    }

    public func removeDependencies(_ dependencies: Operation...) {
        removeDependencies(dependencies)
    }

    // MARK: Evaluate

    /// Must be overriden in Condition subclasses.
    /// Must always call `completion` with the result.
    open func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        let reason = "Condition must be subclassed, and \(#function) overridden."
        let result: ConditionResult = .failure(ProcedureKitError.programmingError(reason: reason))
        completion(result)
    }

    // MARK: Hashable

    public static func == (lhs: Condition, rhs: Condition) -> Bool {
        return lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }


    // MARK: Internal Implementation

    internal func evaluate(procedure: Procedure, withContext context: ConditionEvaluationContext, completion: @escaping (ConditionResult) -> Void) {
        // Default is to ignore the context, and simply call the overriden open evaluate method
        evaluate(procedure: procedure, completion: completion)
    }
}

extension Condition {

    public var isMutuallyExclusive: Bool {
        return !mutuallyExclusiveCategories.isEmpty
    }
}

internal extension Condition {
    /// Set a descriptive name for the Condition.
    ///
    /// - Parameters:
    ///   - name: the new name (String)
    ///   - ifNotAlreadySet: if `true` (the default), the new name will only be set if the existing name is `nil`
    /// - Returns: the resulting name for the Condition
    func set(name: String, ifNotAlreadySet: Bool = true) -> String {
        return synchronise {
            if ifNotAlreadySet, let existingName = _name {
                return existingName
            }
            _name = name
            return name
        }
    }

    // Set the output (once the Condition has been evaluated).
    func set(output: ConditionResult) {
        synchronise {
            assert(_output.isPending, "Trying to set output of Condition evaluation more than once.")
            _output = .ready(output)
        }
    }
}

// MARK: - Internal Extensions

internal extension Condition {

    func debugAssertConditionNotAttachedToProcedure(_ message: String = "Condition is already attached to a Procedure.") {
        #if DEBUG
        guard _procedure == nil else {
            assertionFailure("Dependencies must be modified before the Condition is added to a Procedure.")
            return
        }
        #endif
    }
}

// MARK: - Deprecations

public extension Condition {

    @available(*, deprecated, renamed: "produceDependency(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func produce(dependency: Operation) {
        produceDependency(dependency)
    }

    @available(*, deprecated, renamed: "addDependency(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add(dependency: Operation) {
        addDependency(dependency)
    }

    @available(*, deprecated, renamed: "addDependencies(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add(dependencies: [Operation]) {
        addDependencies(dependencies)
    }

    @available(*, deprecated, renamed: "addDependencies(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    final func add(dependencies: Operation...) {
        addDependencies(dependencies)
    }

    @available(*, deprecated, renamed: "removeDependency(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func remove(dependency: Operation) {
        removeDependency(dependency)
    }

    @available(*, deprecated, renamed: "removeDependencies(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func remove(dependencies: [Operation]) {
        removeDependencies(dependencies)
    }

    @available(*, deprecated, renamed: "removeDependencies(_:)", message: "This has been renamed to use Swift 3/4 naming conventions")
    func remove(dependencies: Operation...) {
        removeDependencies(dependencies)
    }
}

// MARK: - Condition Subclasses

/**
 A `Condition` subclass that always evaluates successfully.

 - seealso: `FalseCondition`
 */
public class TrueCondition: Condition {

    public init(name: String = "TrueCondition", mutuallyExclusiveCategory: String? = nil) {
        super.init()
        self.name = name
        if let category = mutuallyExclusiveCategory {
            addToAttachedProcedure(mutuallyExclusiveCategory: category)
        }
    }

    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.success(true))
    }
}

/**
 A `Condition` subclass that always fails.

 - seealso: `TrueCondition`
 */
public class FalseCondition: Condition {

    public init(name: String = "FalseCondition", mutuallyExclusiveCategory: String? = nil) {
        super.init()
        self.name = name
        if let category = mutuallyExclusiveCategory {
            addToAttachedProcedure(mutuallyExclusiveCategory: category)
        }
    }

    public override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.failure(ProcedureKitError.FalseCondition()))
    }
}

/**
 A Condition subclass that evaluates a sequence of Conditions according to the desired
 compound predicate. ("&&", "||")

 For example, if you have two Conditions and you'd like the attached Procedure to
 proceed if *either* of them evaluates successfully, you can use the "orPredicate"
 behavior:

 ```swift
 // assuming "condition1" and "condition2" were previously defined
 procedure.add(condition: CompoundCondition(orPredicateWith: [condition1, condition2]))
 ```

 You can also use the `AndCondition` and `OrCondition` subclasses of `CompoundCondition`,
 if you prefer:

 ```swift
 // equivalent to the prior example
 procedure.add(condition: OrCondition(condition1, condition2))
 ```

 - see: `AndCondition`, `OrCondition`
 */
open class CompoundCondition: Condition {

    public let conditions: [Condition]

    private var _currentEvaluationContext: ConditionEvaluationContext?
    private var currentEvaluationContext: ConditionEvaluationContext? {
        get { return stateLock.withCriticalScope { _currentEvaluationContext } }
        set {
            stateLock.withCriticalScope {
                assert(_currentEvaluationContext == nil, "Evaluating the same Condition twice is not supported.")
                _currentEvaluationContext = newValue
            }
        }
    }

    private enum Kind {
        case andPredicate
        case orPredicate

        var resultAggregationBehavior: ConditionResultAggregationBehavior {
            switch self {
            case .andPredicate: return .andPredicate
            case .orPredicate: return .orPredicate
            }
        }

        var description: String {
            switch self {
            case .andPredicate: return "&&"
            case .orPredicate: return "||"
            }
        }
    }
    private let kind: Kind

    // NOTE: A CompoundCondition, unlike a ComposedCondition, does not inherit its 
    //       conditions dependencies / producedDependencies.
    //
    //       Internally, a CompoundCondition uses the Condition Collection extension
    //       `evaluate(procedure:withAggregationBehavior:withQueue:completion)`
    //       method which handles dependencies (while supporting short-cut evaluation).
    //
    //       This is the same method that the Procedure.EvaluateConditions operation uses.

    // However, it's important to inherit mutually-exclusive categories from all the conditions,
    // so they are applied to the Procedure to which this CompoundCondition is attached.
    override public var mutuallyExclusiveCategories: Set<String> {
        return super.mutuallyExclusiveCategories.union(conditions.mutuallyExclusiveCategories)
    }

    /// A descriptive name for the Condition. (optional)
    ///
    /// It may be expensive to generate a name for a CompoundCondition.
    /// This override delays that generation until the name is first requested
    /// (unless something else, like a subclass, explicitly sets a name).
    override public var name: String? {
        get {
            if let name = super.name {
                return name
            }
            else {
                // generate and cache the CompoundCondition name
                // if another name hasn't already been set
                return set(name: computeName(), ifNotAlreadySet: true)
            }
        }
        set {
            super.name = newValue
        }
    }

    override public func willAttach(to procedure: Procedure) {
        conditions.forEach { $0.willAttach(to: procedure) }
        super.willAttach(to: procedure)
    }

    // MARK: Init - AndPredicate

    /// Initialize a CompoundCondition that evaluates to the logical "&&"
    /// of all the supplied conditions.
    ///
    /// i.e. The CompoundCondition will only succeed if all the supplied
    /// conditions succeed.
    ///
    /// - Parameter conditions: a Sequence of Conditions
    public init<S: Sequence>(andPredicateWith conditions: S) where S.Iterator.Element == Condition {
        self.conditions = conditions.filterDuplicates()
        self.kind = .andPredicate
        super.init()
    }

    /// Initialize a CompoundCondition that evaluates to the logical "&&"
    /// of all the supplied conditions.
    ///
    /// i.e. The CompoundCondition will only succeed if all the supplied
    /// conditions succeed.
    ///
    /// - Parameter conditions: a sequence of Conditions
    convenience public init(andPredicateWith conditions: Condition...) {
        self.init(andPredicateWith: conditions)
    }

    // MARK: Init - OrPredicate

    /// Initialize a CompoundCondition that evaluates to the logical "||"
    /// of all the supplied conditions.
    ///
    /// i.e. As soon as one of the supplied conditions evaluates successfully,
    /// the CompoundCondition will return success.
    ///
    /// - Parameter conditions: a Sequence of Conditions
    public init<S: Sequence>(orPredicateWith conditions: S) where S.Iterator.Element == Condition {
        self.conditions = conditions.filterDuplicates()
        self.kind = .orPredicate
        super.init()
    }

    /// Initialize a CompoundCondition that evaluates to the logical "||"
    /// of all the supplied conditions.
    ///
    /// i.e. As soon as one of the supplied conditions evaluates successfully,
    /// the CompoundCondition will return success.
    ///
    /// - Parameter conditions: a sequence of Conditions
    convenience public init(orPredicateWith conditions: Condition...) {
        self.init(orPredicateWith: conditions)
    }

    // MARK: Evaluate Override

    /// Override of public function
    ///
    /// If you subclass `CompoundCondition` and override this method, you must call
    /// `super.evaluate(procedure: completion:)`.
    public final override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        // Create an evaluation sub-context (if a current evaluation context is present)
        let context = currentEvaluationContext?.subContext(withBehavior: kind.resultAggregationBehavior) ?? ConditionEvaluationContext(behavior: kind.resultAggregationBehavior)

        // Utilize the Condition Collection extension `evaluate` method to
        // evaluate the conditions (while handling dependencies and
        // short-cut evaluation).
        conditions.evaluate(procedure: procedure, withContext: context, completion: completion)
    }

    /// Override of internal function
    internal override func evaluate(procedure: Procedure, withContext context: ConditionEvaluationContext, completion: @escaping (ConditionResult) -> Void) {
        currentEvaluationContext = context
        super.evaluate(procedure: procedure, withContext: context, completion: completion)
    }

    // MARK: Private Implementation

    private func computeName() -> String {
        func makeConditionsString(kind: Kind, conditions: [Condition]) {
            var output: String = ""
            for condition in conditions {
                guard !output.isEmpty else {
                    output.append("\(condition)")
                    continue
                }
                output.append("\(kind.description) \(condition)")
            }
        }
        return "CompoundCondition(\(makeConditionsString(kind: kind, conditions: conditions)))"
    }
}

/**
 A Condition subclass that evaluates a sequence of Conditions according to the "&&"
 compound predicate. i.e. All Conditions in the sequence must succeed for the AndCondition
 to succeed.

 A subclass of `CompoundCondition` that provides custom initializers (for convenience)
 for "&&" behavior.

 - see: `CompoundCondition`
 */
open class AndCondition: CompoundCondition {

    /// Initialize an AndCondition that evaluates to the logical "&&"
    /// of all the supplied conditions.
    ///
    /// - Parameter conditions: an array of `Condition`s
    public init(_ conditions: [Condition]) {
        super.init(andPredicateWith: conditions)
    }

    /// Initialize an AndCondition that evaluates to the logical "&&"
    /// of all the supplied conditions.
    ///
    /// - Parameter conditions: an sequence of `Condition`s
    public init<S: Sequence>(_ conditions: S) where S.Iterator.Element == Condition {
        super.init(andPredicateWith: conditions)
    }

    /// Initialize an AndCondition that evaluates to the logical "&&"
    /// of all the supplied conditions.
    ///
    /// - Parameter conditions: a variadic array of `Condition`s
    convenience public init(_ conditions: Condition...) {
        self.init(conditions)
    }
}

/**
 A Condition subclass that evaluates a sequence of Conditions according to the "||"
 compound predicate. i.e. At least one Condition in the sequence must succeed for the
 OrCondition to succeed.

 A subclass of `CompoundCondition` that provides custom initializers (for convenience)
 for "||" behavior.

 - see: `CompoundCondition`
 */
open class OrCondition: CompoundCondition {

    /// Initialize an OrCondition that evaluates to the logical "||"
    /// of all the supplied conditions.
    ///
    /// - Parameter conditions: an array of `Condition`s
    public init(_ conditions: [Condition]) {
        super.init(orPredicateWith: conditions)
    }

    /// Initialize an OrCondition that evaluates to the logical "||"
    /// of all the supplied conditions.
    ///
    /// - Parameter conditions: an sequence of `Condition`s
    public init<S: Sequence>(_ conditions: S) where S.Iterator.Element == Condition {
        super.init(orPredicateWith: conditions)
    }

    /// Initialize an OrCondition that evaluates to the logical "||"
    /// of all the supplied conditions.
    ///
    /// - Parameter conditions: a variadic array of `Condition`s
    convenience public init(_ conditions: Condition...) {
        self.init(conditions)
    }
}

/**
 Class which can be used to compose a Condition, it is designed to be subclassed.

 This can be useful to automatically manage the dependency and automatic
 injection of the composed condition result for evaluation inside your custom subclass.

 - see: `NegatedCondition`
 - see: `SilentCondition`
 */
open class ComposedCondition<C: Condition>: Condition {

    /**
     The composed condition.

     - parameter condition: a the composed `Condition`
     */
    public let condition: C

    private var _currentEvaluationContext: ConditionEvaluationContext?
    private var currentEvaluationContext: ConditionEvaluationContext? {
        get { return stateLock.withCriticalScope { _currentEvaluationContext } }
        set {
            stateLock.withCriticalScope {
                assert(_currentEvaluationContext == nil, "Evaluating the same Condition twice is not supported.")
                _currentEvaluationContext = newValue
            }
        }
    }

    override public var producedDependencies: Set<Operation> {
        return super.producedDependencies.union(condition.producedDependencies)
    }

    override public var dependencies: Set<Operation> {
        return super.dependencies.union(condition.dependencies)
    }

    override public var mutuallyExclusiveCategories: Set<String> {
        return super.mutuallyExclusiveCategories.union(condition.mutuallyExclusiveCategories)
    }

    override public func willAttach(to procedure: Procedure) {
        condition.willAttach(to: procedure)
        super.willAttach(to: procedure)
    }

    /**
     Initializer which receives a condition.

     - parameter [unnamed]: a nested `Condition` type.
     */
    public init(_ condition: C) {
        self.condition = condition
        super.init()
        name = condition.name
    }

    /// Override of public function
    open override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        // pass-through the Evaluation Context provided for the current evaluation (if present)
        let context = currentEvaluationContext ?? ConditionEvaluationContext()

        // evaluate the composed condition
        condition.evaluate(procedure: procedure, withContext: context) { [weak self] result in
            self?.condition.set(output: result)
            // call the completion block with the composed condition's result
            completion(result)
        }
    }

    override public func removeDependency(_ dependency: Operation) {
        condition.removeDependency(dependency)
        super.removeDependency(dependency)
    }

    internal override func evaluate(procedure: Procedure, withContext context: ConditionEvaluationContext, completion: @escaping (ConditionResult) -> Void) {
        currentEvaluationContext = context
        super.evaluate(procedure: procedure, withContext: context, completion: completion)
    }
}

/**
 A condition that treats failures from a composed condition as `.success(false)`.

 Thus, the only two possible ConditionResult outputs from an IgnoredCondition are:
 - `.success(true)`
 - `.success(false)`

 And any failure errors will not be propagated to the attached Procedure.
 */
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

// MARK: - Condition Logical Operator Support

public func && (lhs: Condition, rhs: Condition) -> AndCondition {
    return AndCondition([lhs, rhs])
}

public func || (lhs: Condition, rhs: Condition) -> OrCondition {
    return OrCondition([lhs, rhs])
}

public prefix func !<T> (rhs: T) -> NegatedCondition<T> {
    return NegatedCondition(rhs)
}

// MARK: - Internal Helpers

internal class ConditionEvaluationContext {
    var procedureQueue: ProcedureQueue {
        return stateLock.withCriticalScope { _procedureQueue }
    }
    var isCancelled: Bool {
        return stateLock.withCriticalScope { _isCancelled }
    }
    fileprivate let underlyingQueue: DispatchQueue
    fileprivate let aggregator: ConditionResultAggregator

    init(queue: DispatchQueue = DispatchQueue(label: "run.kit.procedure.ProcedureKit.ConditionEvaluationContext", attributes: [.concurrent]), behavior: ConditionResultAggregationBehavior = .andPredicate) {
        self.underlyingQueue = queue
        self.aggregator = ConditionResultAggregator(behavior: behavior)
    }

    private var stateLock = PThreadMutex()
    private var _isCancelled: Bool = false
    private var _subContexts: [ConditionEvaluationContext] = []
    private var _procedureQueue: ProcedureQueue {
        if __procedureQueue == nil {
            // Lazily create a ProcedureQueue the first time it's needed
            __procedureQueue = ProcedureQueue()
            __procedureQueue!.underlyingQueue = underlyingQueue
        }
        return __procedureQueue!
    }
    private var __procedureQueue: ProcedureQueue? // swiftlint:disable:this variable_name

    func cancel() {
        stateLock.withCriticalScope {
            _isCancelled = true
            if let procedureQueue = __procedureQueue {
                procedureQueue.cancelAllOperations()
            }
            for subContext in _subContexts {
                subContext.cancel()
            }
            aggregator.cancel(withResult: .failure(ProcedureKitError.ConditionEvaluationCancelled()))
        }
    }

    func queueOperation(_ operation: Operation) -> ProcedureFuture {
        return stateLock.withCriticalScope {
            if _isCancelled { operation.cancel() }
            return _procedureQueue.addOperation(operation)
        }
    }

    func queueOperations<S>(_ operations: S) -> ProcedureFuture where S: Sequence, S.Iterator.Element: Operation {
        return stateLock.withCriticalScope {
            if _isCancelled { operations.forEach { $0.cancel() } }
            return _procedureQueue.addOperations(operations)
        }
    }

    func queueOperations<S>(_ operations: S...) where S: Sequence, S.Iterator.Element: Operation {
        stateLock.withCriticalScope {
            for operations in operations {
                if _isCancelled { operations.forEach { $0.cancel() } }
                _procedureQueue.addOperations(operations)
            }
        }
    }

    func subContext(withBehavior behavior: ConditionResultAggregationBehavior = .andPredicate) -> ConditionEvaluationContext {
        return stateLock.withCriticalScope {
            let newContext = ConditionEvaluationContext(queue: underlyingQueue, behavior: behavior)
            if _isCancelled { newContext.cancel() }
            _subContexts.append(newContext)
            return newContext
        }
    }
}

/// The method of handling a new result for a particular ConditionResultAggregationBehavior.
///
/// - aggregate: Instructs the aggregator to aggregate the result.
/// - finishWithResult: Instructs the aggregator to finish immediately with the supplied result.
internal enum ConditionResultAggregationResult {
    case aggregate
    case finishWithResult(ConditionResult)
}

/// ConditionResultAggregationBehavior provides two main behaviors:
///
/// - andPredicate: Aggregates results with logical behavior that matches "&&". Results are aggregated until one fails (i.e. does not return `.success(true)`), at which point the failure is treated as the final result.
/// - orPredicate: Aggregates results with logical behavior that matches "||". Results are aggregated until one succeeds (i.e. returns `.success(true)`), at which point the success is treated as the final result. (If no results are successful, then all the failures are the result.)
internal enum ConditionResultAggregationBehavior {
    case andPredicate
    case orPredicate

    func handle(newResult: ConditionResult) -> ConditionResultAggregationResult {
        switch self {
        case .andPredicate:
            return andProcess(newResult: newResult)
        case .orPredicate:
            return orProcess(newResult: newResult)
        }
    }

    private func andProcess(newResult: ConditionResult) -> ConditionResultAggregationResult {
        switch newResult {
        case .success: return .aggregate
        default: return .finishWithResult(newResult)
        }
    }

    private func orProcess(newResult: ConditionResult) -> ConditionResultAggregationResult {
        switch newResult {
        case .success(true): return .finishWithResult(newResult)
        default: return .aggregate
        }
    }
}

fileprivate class ConditionResultAggregator {
    enum Errors: Error {
        case alreadyFinishedWithResult(ConditionResult)
    }
    private let stateLock = PThreadMutex()
    private var _oustandingExpectations = 0
    private var _aggregatedResults = [ConditionResult]()
    private var _hasFinishedWithResult: ConditionResult?
    private let resultAggregationBehavior: ConditionResultAggregationBehavior
    private let group = DispatchGroup()

    var aggregatedResults: [ConditionResult] {
        return stateLock.withCriticalScope { _aggregatedResults }
    }

    var result: ConditionResult {
        return stateLock.withCriticalScope {
            guard let result = _hasFinishedWithResult else {
                // no explicit result was set, so get the
                // _aggregatedResults array and compute its result
                return _aggregatedResults.conditionResult
            }
            return result
        }
    }

    /// Initialize a ConditionResultAggregator with a ConditionResultAggregationBehavior.
    ///
    /// - Parameter behavior: A `ConditionResultAggregationBehavior`.
    init(behavior: ConditionResultAggregationBehavior) {
        resultAggregationBehavior = behavior
    }

    /// Call once before every expected call to `fulfill(result:)`.
    ///
    /// NOTE: If the `ConditionResultAggregationBehavior` specifies that the
    /// aggregator should `.finishWithResult(ConditionResult)`, it is acceptable
    /// to short-cut any remaining calls to `fulfill(result:)`.
    ///
    /// i.e. If a call to `expectResult()` throws `Errors.alreadyFinishedWithResult`
    /// you are permitted to handle that result immediately, and do not have to make
    /// any other remaining `fulfill(result:)` calls (to balance out earlier
    /// `expectResult()` calls).
    ///
    /// - Throws: throws Errors.alreadyFinishedWithResult
    func expectResult() throws {
        let error: Error? = stateLock.withCriticalScope {
            if let result = _hasFinishedWithResult {
                // has already finished with result
                // throw an error so the caller can handle this case
                return Errors.alreadyFinishedWithResult(result)
            }
            if _oustandingExpectations == 0 {
                group.enter()
            }
            _oustandingExpectations += 1
            return nil
        }
        if let error = error {
            throw error
        }
    }

    /// For every call to `fulfill(result:)`, you must first call `expectResult()`.
    ///
    /// However, a `ConditionResultAggregator` may finish with a result before
    /// all paired `fulfill(result:)` calls are made (depending on its
    /// `ConditionResultAggregationBehavior`), in which case you are not required
    /// to make further (remaining) `fulfill(result:)` calls.
    ///
    /// - Parameter result: A ConditionResult that is aggregated, based on the
    ///                     aggregator's `ConditionResultAggregationBehavior`.
    func fulfill(result: ConditionResult) {
        stateLock.withCriticalScope {
            guard _oustandingExpectations > 0 else {
                fatalError("Mis-matched expectResult() / fulfill(result:) calls.")
            }
            _oustandingExpectations -= 1
            guard _hasFinishedWithResult == nil else { return }
            switch resultAggregationBehavior.handle(newResult: result) {
            case .aggregate:
                _aggregatedResults.append(result)
                guard _oustandingExpectations > 0 else {
                    // no more outstanding expectations, decrease the group to 0
                    group.leave()
                    return
                }
            case .finishWithResult(let result):
                // stop aggregating, and immediately trigger the completion with this result
                _hasFinishedWithResult = result
                group.leave()
                return
            }
        }
    }

    func cancel(withResult result: ConditionResult) {
        stateLock.withCriticalScope {
            guard _hasFinishedWithResult == nil else { return }
            // stop aggregating, and immediately trigger the completion with this result
            _hasFinishedWithResult = result
            guard _oustandingExpectations > 0 else { return }
            group.leave()
        }
    }

    func notify(queue: DispatchQueue, execute: @escaping (ConditionResult) -> Void) {
        group.notify(queue: queue) {
            execute(self.result)
        }
    }
}

internal extension Condition {

    enum DependencyVerificationResult {
        case success
        case dependencyFailed
        case dependencyCancelled
    }

    // swiftlint:disable cyclomatic_complexity
    func verifyDependencyRequirements() -> DependencyVerificationResult {
        let dependencyRequirements = self.dependencyRequirements
        guard !dependencyRequirements.isEmpty else { return .success }

        let dependencies = self.dependencies.union(self.producedDependencies)

        if dependencyRequirements.contains(.noFailed) {
            // Verify that there are no failed dependencies
            if dependencyRequirements.contains(.ignoreFailedIfCancelled) {
                // Ignore failed dependencies that are cancelled
                for dependency in dependencies {
                    guard let procedure = dependency as? Procedure else { continue }
                    guard !procedure.failed || procedure.isCancelled else { return .dependencyFailed }
                }
            }
            else {
                for dependency in dependencies {
                    guard let procedure = dependency as? Procedure else { continue }
                    guard !procedure.failed else { return .dependencyFailed }
                }
            }
        }

        if dependencyRequirements.contains(.noCancelled) {
            // Verify that there are no cancelled dependencies
            for dependency in dependencies {
                guard !dependency.isCancelled else { return .dependencyCancelled }
            }
        }

        return .success
    }
    // swiftlint:enable cyclomatic_complexity
}

// A Dummy Operation that only finishes once: 
// - something external calls `finishOnceStarted()` *and* it has been started by the queue
fileprivate class DummyDependency: Operation {
    private var stateLock = PThreadMutex()
    private var _started: Bool = false
    private var _shouldFinish: Bool = false
    private var _isFinished: Bool = false
    private var _isExecuting: Bool = false

    override func start() {
        isExecuting = true
        main()
    }
    override func main() {
        let canFinish: Bool = stateLock.withCriticalScope {
            _started = true
            return _shouldFinish
        }
        guard canFinish else { return }
        finish()
    }
    func finishOnceStarted() {
        let canFinish: Bool = stateLock.withCriticalScope {
            _shouldFinish = true
            return _started
        }
        guard canFinish else { return }
        finish()
    }
    private func finish() {
        isExecuting = false
        isFinished = true
    }
    override var isFinished: Bool {
        get { return stateLock.withCriticalScope { return _isFinished } }
        set {
            willChangeValue(forKey: .finished)
            stateLock.withCriticalScope { _isFinished = newValue }
            didChangeValue(forKey: .finished)
        }
    }
    override var isExecuting: Bool {
        get { return stateLock.withCriticalScope { return _isExecuting } }
        set {
            willChangeValue(forKey: .executing)
            stateLock.withCriticalScope { _isExecuting = newValue }
            didChangeValue(forKey: .executing)
        }
    }
}

internal extension Collection where Iterator.Element == Condition {

    var producedDependencies: Set<Operation> {
        var result = Set<Operation>()
        for condition in self {
            result.formUnion(condition.producedDependencies)
        }
        return result
    }

    var dependencies: Set<Operation> {
        var result = Set<Operation>()
        for condition in self {
            result.formUnion(condition.dependencies)
        }
        return result
    }

    var mutuallyExclusiveCategories: Set<String> {
        var result = Set<String>()
        for condition in self {
            result.formUnion(condition.mutuallyExclusiveCategories)
        }
        return result
    }

    /// Evaluate a collection of Conditions on a Procedure, utilizing a context
    /// containing a defined aggregation behavior to return an aggregated
    /// ConditionResult as soon as it is known.
    ///
    /// For example, utilizing `.andPredicate` behavior ensures that the
    /// ConditionResult aggregates successes, while returning immediately
    /// for the first failure.
    ///
    /// The `ConditionResult` passed-in to the `completion` block is either
    /// the final result determined by the aggregation behavior, or
    /// (if the aggregation behavior does not instruct a final result)
    /// the aggregate `ConditionResult` computed from the collection of
    /// all results (once they are available).
    ///
    /// - Parameters:
    ///   - procedure: a Procedure that is passed-in to every Condition's evaluate method
    ///   - context: a ConditionEvaluationContext, containing parameters like the aggregation behavior
    ///   - completion: the completion block that is called with a result as soon as it is known

    func evaluate(procedure: Procedure, withContext context: ConditionEvaluationContext, completion: @escaping (ConditionResult) -> Void) {

        let aggregator = context.aggregator
        for condition in self {
            do {
                try aggregator.expectResult()
            }
            catch ConditionResultAggregator.Errors.alreadyFinishedWithResult(let result) {
                // A result has been obtained (before all Conditions have been evaluated)

                // Cancel the current evaluation context (since we have a result)
                // (This cancels outstanding produced dependencies and dependent condition operations)
                context.cancel()

                // Immediately complete with the result
                completion(result)

                // Stop processing further conditions - return immediately
                return
            }
            catch {
                fatalError("Unexpected error: \(error)")
            }

            // Get any dependencies for this condition
            let directDependencies = condition.dependencies
            let producedDependencies = condition.producedDependencies
            guard producedDependencies.isEmpty && directDependencies.isEmpty else {
                // Must wait for dependencies to complete before evaluating the condition

                // Create a new BlockOperation that wraps the call to `condition.evaluate`
                let conditionEvaluateOperation = BlockOperation { [weak procedure, weak condition] in

                    // Do not bother evaluating the Condition if the Procedure no longer exists
                    guard let procedure = procedure else { return }
                    guard let condition = condition else { return }

                    // Check Dependencies (if required)
                    switch condition.verifyDependencyRequirements() {
                    case .success: break
                    case .dependencyFailed:
                        // one or more dependencies failed verification because they finished with errors
                        // immediately fail this Condition
                        aggregator.fulfill(result: .failure(ProcedureKitError.ConditionDependenciesFailed(condition: condition)))
                        return
                    case .dependencyCancelled:
                        // one or more dependencies failed verification because they were cancelled
                        // immediatelly fail this Condition
                        aggregator.fulfill(result: .failure(ProcedureKitError.ConditionDependenciesCancelled(condition: condition)))
                        return
                    }

                    // Evaluate the Condition
                    condition.evaluate(procedure: procedure, withContext: context) { result in
                        condition.set(output: result)
                        aggregator.fulfill(result: result)
                    }
                }

                // Set the conditionEvaluateOperation to be dependent on all the Condition dependencies
                conditionEvaluateOperation.addDependencies(directDependencies.union(producedDependencies))

                // Sanity-Check the producedDependencies
                //
                // An Operation instance must be produced by a single Condition instance.
                // (i.e. Should only be added to a single Condition instance via a single
                // `produce(dependency:)` call, and must not be scheduled for execution via
                // any other means.)
                assert(producedDependencies.filter { $0.isExecuting || $0.isFinished }.isEmpty, "One or more produced dependencies are already executing or finished. Condition-produced dependencies must be produced by a single Condition instance, and not manually added to a queue, or executed, or produced by any other Condition instances. Problem Operations: \(producedDependencies.filter { $0.isExecuting || $0.isFinished })")

                // Add the producedDependencies and the conditionEvaluateOperation to the procedureQueue
                //
                // IMPORTANT: To work around a rare race condition in NSOperation / NSOperationQueue,
                //            the conditionEvaluateOperation must not have its isReady state transition to
                //            `true` while it is being added to the queue.
                //
                //            Therefore: 
                //              1.) Add the `conditionEvaluateOperation` to the queue *before* its 
                //                  producedDependencies.
                //              2.) If only directDependencies exist, create a "dummy" producedDependency,
                //                  which is explicitly finished only after the queue add completes.
                //
                //            (Otherwise, it is possible for a conditionEvaluateOperation to get
                //            "stuck" as ready but never executing if the dependencies all finish
                //            while the conditionEvaluateOperation is being added to the underlying
                //            NSOperationQueue.)
                //
                if !producedDependencies.isEmpty {
                    // 1.) Add the `conditionEvaluateOperation` to the queue *before* its
                    //     producedDependencies.
                    context.queueOperations([conditionEvaluateOperation], producedDependencies)
                }
                else {
                    // 2.) No produced dependencies (only direct dependencies)
                    //     Create a "dummy" workaround produced dependency which is explicitly finished
                    //     only after the queue add completes. 
                    //     (This ensures that the conditionEvaluateOperation will not become ready while
                    //     being added to the queue.)
                    let workaroundProducedDependency = DummyDependency()
                    conditionEvaluateOperation.addDependency(workaroundProducedDependency)
                    context.queueOperations([conditionEvaluateOperation, workaroundProducedDependency]).then(on: context.underlyingQueue) {
                        workaroundProducedDependency.finishOnceStarted()
                    }
                }

                // Skip to the next condition
                continue
            }

            // Since this Condition has no dependencies, call the `evaluate` function directly
            condition.evaluate(procedure: procedure, withContext: context) { result in
                condition.set(output: result)
                aggregator.fulfill(result: result)
            }
        }

        aggregator.notify(queue: context.underlyingQueue) { result in
            // Cancel the current evaluation context (since we have a result)
            // (This cancels outstanding produced dependencies and dependent condition operations)
            context.cancel()

            // Call the completion block
            completion(result)
        }
    }
}

internal extension Collection where Iterator.Element == ConditionResult {

    // Get a single conditionResult for a collection of results
    var conditionResult: ConditionResult {
        return self.reduce(.success(false)) { lhs, result in
            // Unwrap the condition's output
            let rhs = result

            switch (lhs, rhs) {
            // both results are failures
            case let (.failure(error), .failure(anotherError)):
                if let error = error as? ProcedureKitError.FailedConditions {
                    return .failure(error.append(error: anotherError))
                }
                else if let anotherError = anotherError as? ProcedureKitError.FailedConditions {
                    return .failure(anotherError.append(error: error))
                }
                else {
                    return .failure(ProcedureKitError.FailedConditions(errors: [error, anotherError]))
                }
            // new condition failed - so return it
            case (_, .failure):
                return rhs
            // first condition is ignored - so return the new one
            case (.success(false), _):
                return rhs
            default:
                return lhs
            }
        }
    }

    // Determine if any result in a collection of results is `.success(true)`
    var hasSuccessfulConditionResult: Bool {
        for result in self {
            switch result {
            case .success(true): return true
            default: continue
            }
        }
        return false
    }
}

internal extension Sequence where Iterator.Element: Hashable {

    // - returns: an Array<Iterator.Element> that preserves the original sequence order, but in which only the first instance of a unique Element is preserved
    func filterDuplicates() -> [Iterator.Element] {
        var result: [Iterator.Element] = []
        var added = Set<Iterator.Element>()
        for element in self {
            guard !added.contains(element) else { continue }
            result.append(element)
            added.insert(element)
        }
        return result
    }
}

// MARK: - Unavailable

public extension Condition {

    @available(*, unavailable, renamed: "addToAttachedProcedure(mutuallyExclusiveCategory:)")
    var mutuallyExclusiveCategory: String? {
        get { fatalError("Unavailable. Use `mutuallyExclusiveCategories` instead to query.") }
        set { fatalError("Unavailable. Use `addToAttachedProcedure(mutuallyExclusiveCategory:)` instead to set.") }
    }
}

// swiftlint:enable file_length
