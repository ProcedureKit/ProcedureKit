//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public protocol ProcedureProcotol: class {

    var procedureName: String { get }

    var isExecuting: Bool { get }

    var isFinished: Bool { get }

    var isCancelled: Bool { get }

    var errors: [Error] { get }

    // Execution

    func willEnqueue()

    func execute()

    func produce(operation: Operation)

    // Cancelling

    func cancel(withErrors: [Error])

    func procedureWillCancel(withErrors: [Error])

    func procedureDidCancel(withErrors: [Error])

    // Finishing

    func finish(withErrors: [Error])

    func procedureWillFinish(withErrors: [Error])

    func procedureDidFinish(withErrors: [Error])

    // Observers

    func add<Observer: ProcedureObserver>(observer: Observer) where Observer.Procedure == Self

    // Dependencies

    func add<Dependency: ProcedureProcotol>(dependency: Dependency)
}

public extension ProcedureProcotol {

    var failed: Bool {
        return errors.count > 0
    }

    func cancel(withError error: Error?) {
        cancel(withErrors: error.map { [$0] } ?? [])
    }

    func procedureWillCancel(withErrors: [Error]) { }

    func procedureDidCancel(withErrors: [Error]) { }

    func finish(withError error: Error? = nil) {
        finish(withErrors: error.map { [$0] } ?? [])
    }

    func procedureWillFinish(withErrors: [Error]) { }

    func procedureDidFinish(withErrors: [Error]) { }


    /**
     Access the completed dependency operation before `self` is
     started. This can be useful for transfering results/data between
     operations.

     - parameters dep: any `Operation` subclass.
     - parameters block: a closure which receives `self`, the dependent
     operation, and an array of `ErrorType`, and returns Void.
     - returns: `self` - so that injections can be chained together.
     */
    func inject<Dependency: ProcedureProcotol>(dependency: Dependency, block: @escaping (Self, Dependency, [Error]) -> Void) -> Self {

        dependency.addWillFinishBlockObserver { [weak self] dependency, errors in
            if let strongSelf = self {
                block(strongSelf, dependency, errors)
            }
        }

        dependency.addDidCancelBlockObserver { [weak self] dependency, errors in
            if let strongSelf = self {
                strongSelf.cancel(withErrors: errors)
            }
        }

        add(dependency: dependency)

        return self
    }
}


// MARK: - Result Injection

public protocol ResultInjectionProtocol {

    associatedtype Requirement
    associatedtype Result

    var requirement: Requirement { get set }
    var result: Result { get }
}

public extension ResultInjectionProtocol {

    public var requirement: Void {
        get { return Void() }
        set { }
    }
    public var result: Void { return Void() }
}

public extension ResultInjectionProtocol where Self: ProcedureProcotol {

    func injectResultFrom<Dependency>(dependency: Dependency) -> Self where Dependency: ProcedureProcotol, Dependency: ResultInjectionProtocol, Dependency.Result == Requirement {
        return inject(dependency: dependency) { procedure, dependency, errors in
            guard errors.isEmpty else {
                procedure.cancel(withErrors: errors); return
            }
            var mutuableProcedure = procedure
            mutuableProcedure.requirement = dependency.result
        }
    }

    func requireResultFrom<Dependency>(dependency: Dependency) -> Self where Dependency: ProcedureProcotol, Dependency: ResultInjectionProtocol, Dependency.Result == Optional<Requirement> {
        return inject(dependency: dependency) { procedure, dependency, errors in
            guard errors.isEmpty else {
                procedure.cancel(withErrors: errors); return
            }
            guard let requirement = dependency.result else {
                procedure.cancel(withError: Errors.ProgrammingError(reason: "TODO")); return
            }
            var mutuableProcedure = procedure
            mutuableProcedure.requirement = requirement
        }
    }
}
