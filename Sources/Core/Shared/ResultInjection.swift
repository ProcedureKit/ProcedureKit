//
//  ResultInjection.swift
//  Operations
//
//  Created by Daniel Thorpe on 15/12/2015.
//
//

import Foundation

/**
 # Result Injection
 
 These protocols and extensions allow the injection of result(s) from
 one operation into another. 
 
 Consider a data processing task, before it can execute, it must have 
 the data to process. Consider this data to be a *requirement*. Unless
 this data is literal (i.e. known at compile time) a good practice is
 to "inject" the data into the data-processing task. This is called 
 dependency injection, and in a text book, it would be best to inject
 the dependency (i.e. data) into the task's constructor.
 
 However, with Operations, we cannot exactly do this, hence (and to 
 avoid the overloaded term "dependency") we are going to refer to this
 data as a requirement.
 
 In almost all cases the requirement can be the *result* of another
 operation. Even reading data from the disk should be framed in the
 context of an asychonous task suitable for Operation. Therefore in 
 general we wish to take the result from one operation and set it as
 the requirement on another. This implies an operation dependency. The
 data-processing operation depends upon the completion of the data-
 retrieval operation.

 In the most general case, we can achieve this by making the
 data-processing operation conform to `InjectionOperationType`.
 
 ```swift
 class DataProcessing: Operation, InjectionOperationType {
    // etc
 }
 ```
 
 With the above definition, it is now possible to setup the injection:
 
 ```swift
 let fetch = DataRetrieval()
 let processing = DataProcessing()
 processing.injectResultFromDependency(fetch) { op, dep, errors in
   if errors.isEmpty {
     op.data = dep.data
   }
   else {
     // Still thinking about this, how should errors be handled?
     op.cancel()
   }
 }
 queue.addOperations(fetch, processing)
 ```

 Note here, that the closure's arguments are generic types, so
 `op` is actually the `processing` operation, and `dep` is the 
 `fetch` operation. They are properly typed, and we are assuming that
 there `data` property is set up accordingly.
 
 The usage of this closure is why we refer to this as manual injection.
*/
public protocol InjectionOperationType: class { }

extension InjectionOperationType where Self: Operation {

    /**
     Access the completed dependency operation before `self` is
     started. This can be useful for transfering results/data between
     operations.
     
     - parameters dep: any `Operation` subclass.
     - parameters block: a closure which receives `self`, the dependent
     operation, and an array of `ErrorType`, and returns Void.
     - returns: `self` - so that injections can be chained together.
    */
    public func injectResultFromDependency<T where T: Operation>(dep: T, block: (operation: Self, dependency: T, errors: [ErrorType]) -> Void) -> Self {
        dep.addObserver(BlockObserver(finishHandler: { (op, errors) -> Void in
            if let dep = op as? T {
                block(operation: self, dependency: dep, errors: errors)
            }
        }))
        (self as Operation).addDependency(dep)
        return self
    }
}

/**
 A protocol which operations must conform to, for their
 "result" to be automatically injected as "requirement" into
 an operation conforming to `AutomaticInjectionOperationType`.
*/
public protocol ResultOperationType: class {
    typealias Result

    /// - returns: the `Result`, note that this can be an `Thing?` if needed.
    var result: Result { get }
}

/**
 A protocol which operations must conform to, for "requirement"
 to be injected automatically from the "result" of an operation 
 conforming to `ResultOperationType`.
 */
public protocol AutomaticInjectionOperationType: InjectionOperationType {
    typealias Requirement

    /// - returns: the `Requirement`, note must be mutable, and 
    /// can be `Thing?` if needed.
    var requirement: Requirement { get set }
}

extension AutomaticInjectionOperationType where Self: Operation {

    /**
     Inject the result from one operation as the requirement of 
     another operation. For example consider data retrieval and
     data processing operation classes:
     
     ```swift
     class DataRetrieval: Operation, ResultOperationType {
        var result: NSData? = .None
     
        // etc etc
     }
     
     class DataProcessing: Operation, AutomaticInjectionOperationType {
        var requirement: NSData? = .None

        // etc etc
     }
     ```
     
     then you can do the following:
     
     ```swift
     let fetch = DataRetrieval()
     let processing = DataProcessing()
     processing.injectResultFromDependency(fetch)
     queue.addOperations(fetch, processing)
     ```

    */
    public func injectResultFromDependency<T where T: Operation, T: ResultOperationType, T.Result == Requirement>(dep: T) {
        dep.addObserver(BlockObserver(finishHandler: { (op, errors) -> Void in
            if errors.isEmpty, let dep = op as? T {
                self.requirement = dep.result
            }
            // TODO: How to handle errors here - can't actually throw from this of course as it's async....
            // might add a `cancelWithErrors(errors: [ErrorType])` method.
        }))
        (self as Operation).addDependency(dep)
    }
}


