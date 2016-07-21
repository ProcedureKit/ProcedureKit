//
//  FunctionalOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 21/12/2015.
//
//

import Foundation

/**
 # Result Procedure

 Abstract but a concrete class for a ResultOperationType.
*/
public class ResultOperation<Result>: Procedure, ResultOperationType {

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
 # Map Procedure

 An `Procedure` subclass which accepts a map transform closure. Because it
 conforms to both `ResultOperationType` and `AutomaticInjectionOperationType`
 it can be used to create an array of operations which transform state.

 - discussion: Note that the closure is invoked as the operation's *work* on
 an operation queue. So it should perform synchronous computation, although
 it will be executed asynshronously.

*/
public class MapOperation<T, U>: ResultOperation<U>, AutomaticInjectionOperationType {

    /// - returns: the requirement an optional type T
    public var requirement: T! = nil

    let transform: (T) -> U

    /**
     Initializes an instance with an optional starting requirement, and an
     transform block.

     - parameter x: the value to the transformed. Note this is optional, as it
     can be injected after initialization, but before execution.
     - parameter transform: a closure which maps a non-optional T to U!. Note
     that this closure will only be run if the requirement is non-nil.
    */
    public init(input: T! = .none, transform: (T) -> U) {
        self.requirement = input
        self.transform = transform
        super.init(result: nil)
        name = "Map"
    }

    public override func execute() {
        guard let requirement = requirement else {
            finish(AutomaticInjectionError.requirementNotSatisfied)
            return
        }
        result = transform(requirement)
        finish()
    }
}

extension ResultOperationType where Self: Procedure {

    /**
     Map the result of an `Procedure` which conforms to `ResultOperationType`.

     ```swift
     let getLocation = UserLocationOperation()
     let toString = getLocation.mapResult { $0.map { "\($0)" } ?? "No location received" }
     queue.addOperations(getLocation, toString)
     ```

    */
    public func mapOperation<U>(_ transform: (Result) -> U) -> MapOperation<Result, U> {
        let map: MapOperation<Result, U> = MapOperation(transform: transform)
        map.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = dependency.result
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.dependencyFinishedWithErrors(errors))
            }
        }
        return map
    }
}

/**
 # Filter Procedure

 An `Procedure` subclass which accepts an include element closure. Because it
 conforms to both `ResultOperationType` and `AutomaticInjectionOperationType`
 it can be used to create an array of operations which transform state.

 - discussion: Note that the closure is invoked as the operation's *work* on
 an operation queue. So it should perform synchronous computation, although
 it will be executed asynshronously.

*/
public class FilterOperation<Element>: ResultOperation<Array<Element>>, AutomaticInjectionOperationType {

    /// - returns: the requirement an optional type T
    public var requirement: Array<Element> = []

    let filter: (Element) -> Bool

    public init(source: Array<Element> = [], includeElement: (Element) -> Bool) {
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

extension ResultOperationType where Self: Procedure, Result: Sequence {

    /**
     Filter the result of the receiver `Procedure` which conforms to `ResultOperationType` where
     the Result is a SequenceType.

     ```swift
     let getLocation = UserLocationOperation()
     let toString = getLocation.mapResult { $0.map { "\($0)" } ?? "No location received" }
     queue.addOperations(getLocation, toString)
     ```
    */
    public func filterOperation(_ includeElement: (Result.Iterator.Element) -> Bool) -> FilterOperation<Result.Iterator.Element> {
        let filter: FilterOperation<Result.Iterator.Element> = FilterOperation(includeElement: includeElement)
        filter.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = Array(dependency.result)
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.dependencyFinishedWithErrors(errors))
            }
        }
        return filter
    }
}

/**
 # Reduce Procedure

 An `Procedure` subclass which accepts an initial value, and a combine closure. Because it
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

extension ResultOperationType where Self: Procedure, Result: Sequence {

    /**
     Reduce the result of the receiver `Procedure` which conforms to `ResultOperationType` where
     the Result is a SequenceType.

     ```swift
     let getStrings = GetStringsOperation()
     let createParagraph = getStrings.reduceOperation("") { (accumulator: String, str: String) in
        return "\(accumulator) \(str)"
     }
     queue.addOperations(getStrings, createParagraph)
     ```

    */
    public func reduceOperation<U>(_ initial: U, combine: (U, Result.Iterator.Element) -> U) -> ReduceOperation<Result.Iterator.Element, U> {
        let reduce: ReduceOperation<Result.Iterator.Element, U> = ReduceOperation(initial: initial, combine: combine)
        reduce.injectResultFromDependency(self) { operation, dependency, errors in
            if errors.isEmpty {
                operation.requirement = Array(dependency.result)
            }
            else {
                operation.cancelWithError(AutomaticInjectionError.dependencyFinishedWithErrors(errors))
            }
        }
        return reduce
    }
}
