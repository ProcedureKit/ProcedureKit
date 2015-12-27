//
//  FunctionalOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 21/12/2015.
//
//

import Foundation

/**
 # Result Operation
 
 Abstract but a concrete class for a ResultOperationType.
*/
public class ResultOperation<Result>: Operation, ResultOperationType {

    /// - returns: the Result
    public var result: Result! = nil

    public init(result: Result! = nil) {
        self.result = result
        super.init()
        name = "Result"
    }

    public override func execute() {
        // no-op
        finish()
    }
}


/**
 # Map Operation
 
 An `Operation` subclass which accepts a map transform closure. Because it
 conforms to both `ResultOperationType` and `AutomaticInjectionOperationType`
 it can be used to create an array of operations which transform state.
 
 - discussion: Note that the closure is invoked as the operation's *work* on
 an operation queue. So it should perform synchronous computation, although
 it will be executed asynshronously.

*/
public class MapOperation<T, U>: ResultOperation<U>, AutomaticInjectionOperationType {

    /// - returns: the requirement an optional type T
    public var requirement: T! = nil

    let transform: T -> U

    /**
     Initializes an instance with an optional starting requirement, and an
     transform block.
     
     - parameter x: the value to the transformed. Note this is optional, as it
     can be injected after initialization, but before execution.
     - parameter transform: a closure which maps a non-optional T to U!. Note
     that this closure will only be run if the requirement is non-nil.
    */
    public init(x: T! = .None, transform: T -> U) {
        self.requirement = x
        self.transform = transform
        super.init(result: nil)
        name = "Map"
    }

    public override func execute() {
        guard let requirement = requirement else {
            finish(AutomaticInjectionError.RequirementNotSatisfied)
            return
        }
        result = transform(requirement)
        finish()
    }
}

extension ResultOperationType where Self: Operation {

    /**
     Map the result of an `Operation` which conforms to `ResultOperationType`.
     
     ```swift
     let getLocation = UserLocationOperation()
     let toString = getLocation.mapResult { $0.map { "\($0)" } ?? "No location received" }
     queue.addOperations(getLocation, toString)
     ```

    */
    public func mapOperation<U>(transform: Result -> U) -> MapOperation<Result, U> {
        let map: MapOperation<Result, U> = MapOperation(transform: transform)
        map.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = dependency.result
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        return map
    }
}

/**
 # Filter Operation

 An `Operation` subclass which accepts an include element closure. Because it
 conforms to both `ResultOperationType` and `AutomaticInjectionOperationType`
 it can be used to create an array of operations which transform state.
 
 - discussion: Note that the closure is invoked as the operation's *work* on
 an operation queue. So it should perform synchronous computation, although
 it will be executed asynshronously.

*/
public class FilterOperation<Element>: ResultOperation<Array<Element>>, AutomaticInjectionOperationType {

    /// - returns: the requirement an optional type T
    public var requirement: Array<Element> = []

    let filter: Element -> Bool

    public init(source: Array<Element> = [], includeElement: Element -> Bool) {
        self.requirement = source
        self.filter = includeElement
        super.init(result: [])
        name = "Filter"
    }

    public final override func execute() {
        result = requirement.filter(filter)
        finish()
    }
}

extension ResultOperationType where Self: Operation, Result: SequenceType {

    /**
     Filter the result of the receiver `Operation` which conforms to `ResultOperationType` where
     the Result is a SequenceType.
     
     ```swift
     let getLocation = UserLocationOperation()
     let toString = getLocation.mapResult { $0.map { "\($0)" } ?? "No location received" }
     queue.addOperations(getLocation, toString)
     ```
    */
    public func filterOperation(includeElement: Result.Generator.Element -> Bool) -> FilterOperation<Result.Generator.Element> {
        let filter: FilterOperation<Result.Generator.Element> = FilterOperation(includeElement: includeElement)
        filter.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = Array(dependency.result)
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        return filter
    }
}

/**
 # Reduce Operation
 
 An `Operation` subclass which accepts an initial value, and a combine closure. Because it
 conforms to both `ResultOperationType` and `AutomaticInjectionOperationType`
 it can be used to create an array of operations which transform state.
 
 - discussion: Note that the closure is invoked as the operation's *work* on
 an operation queue. So it should perform synchronous computation, although
 it will be executed asynshronously.

*/
public class ReduceOperation<Element, U>: ResultOperation<U>, AutomaticInjectionOperationType {

    /// - returns: the requirement an optional type T
    public var requirement: Array<Element> = []

    let initial: U
    let combine: (U, Element) -> U

    public init(source: Array<Element> = [], initial: U, combine: (U, Element) -> U) {
        self.requirement = source
        self.initial = initial
        self.combine = combine
        super.init()
        name = "Reduce"
    }

    public final override func execute() {
        result = requirement.reduce(initial, combine: combine)
        finish()
    }
}

extension ResultOperationType where Self: Operation, Result: SequenceType {

    /**
     Reduce the result of the receiver `Operation` which conforms to `ResultOperationType` where
     the Result is a SequenceType.
     
     ```swift
     let getStrings = GetStringsOperation()
     let createParagraph = getStrings.reduceOperation("") { (accumulator: String, str: String) in
        return "\(accumulator) \(str)"
     }
     queue.addOperations(getStrings, createParagraph)
     ```

    */
    public func reduceOperation<U>(initial: U, combine: (U, Result.Generator.Element) -> U) -> ReduceOperation<Result.Generator.Element, U> {
        let reduce: ReduceOperation<Result.Generator.Element, U> = ReduceOperation(initial: initial, combine: combine)
        reduce.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = Array(dependency.result)
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        return reduce
    }
}



/**
 # Operation Flow
 
 OperationFlow is a class which allows for chaining of functional
 actions (map, filter, reduce) as Operation instances.
 
 This operation collects the intermediate Operation instances in
 a an array
*/
public class OperationFlow<T where T: Operation, T: ResultOperationType>: ResultOperation<T.Result>, InjectionOperationType {

    public let operations: [NSOperation]

    internal let lastOperation: T!

    internal init(last: T! = nil, operations: [NSOperation] = []) {
        self.lastOperation = last
        self.operations = operations
        super.init(result: nil)
        name = "Flow"
    }

    public func map<U>(transform: T.Result -> U) -> OperationFlow<ResultOperation<U>> {
        guard let last = lastOperation else {
            fatalError("The last operaton was not set.")
        }
        var ops = operations
        let map = MapOperation(transform: transform)
        map.injectResultFromDependency(last) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = dependency.result
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        ops.append(map)
        return OperationFlow<ResultOperation<U>>(last: map, operations: ops)
    }
}

extension OperationFlow where T.Result: SequenceType {

    public func filter(includeElement: T.Result.Generator.Element -> Bool) -> OperationFlow<ResultOperation<Array<T.Result.Generator.Element>>> {
        guard let last = lastOperation else {
            fatalError("The last operaton was not set.")
        }
        var ops = operations
        let filter = FilterOperation(includeElement: includeElement)
        filter.injectResultFromDependency(last) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = Array(dependency.result)
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        ops.append(filter)
        return OperationFlow<ResultOperation<Array<T.Result.Generator.Element>>>(last: filter, operations: ops)
    }

    public func reduce<U>(initial: U, combine: (U, T.Result.Generator.Element) -> U) -> OperationFlow<ResultOperation<U>> {
        guard let last = lastOperation else {
            fatalError("The last operaton was not set.")
        }
        var ops = operations
        let reduce = ReduceOperation(initial: initial, combine: combine)
        reduce.injectResultFromDependency(last) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = Array(dependency.result)
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        ops.append(reduce)
        return OperationFlow<ResultOperation<U>>(last: reduce, operations: ops)
    }
}


extension ResultOperationType where Self: Operation {

    public func collect() -> OperationFlow<ResultOperation<Result>> {

        let seq: OperationFlow<ResultOperation<Result>> = OperationFlow()
        seq.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.result = dependency.result
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.DependencyFinishedWithErrors(errors))
            }
        }
        return seq
    }
}



