//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public protocol ResultInjectionProtocol: class {

    associatedtype Requirement
    associatedtype Result

    var requirement: Requirement { get set }
    var result: Result { get }
}

public extension ProcedureProcotol {

    /**
     Access the completed dependency operation before `self` is
     started. This can be useful for transfering results/data between
     operations.

     - parameters dep: any `Operation` subclass.
     - parameters block: a closure which receives `self`, the dependent
     operation, and an array of `ErrorType`, and returns Void.
     - returns: `self` - so that injections can be chained together.
     */
    @discardableResult func inject<Dependency: ProcedureProcotol>(dependency: Dependency, block: @escaping (Self, Dependency, [Error]) -> Void) -> Self {

        dependency.addWillFinishBlockObserver { [weak self] dependency, errors in
            if let strongSelf = self {
                block(strongSelf, dependency, errors)
            }
        }

        dependency.addDidCancelBlockObserver { [weak self] dependency, errors in
            if let strongSelf = self {
                strongSelf.cancel(withError: ProcedureKitError.parent(cancelledWithErrors: errors))
            }
        }

        add(dependency: dependency)

        return self
    }
}


public extension ResultInjectionProtocol where Self: ProcedureProcotol {

    @discardableResult func injectResultFrom<Dependency>(dependency: Dependency) -> Self where Dependency: ProcedureProcotol, Dependency: ResultInjectionProtocol, Dependency.Result == Requirement {

        return inject(dependency: dependency) { procedure, dependency, errors in
            guard errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            procedure.log.verbose(message: "injecting \(dependency.result) from \(dependency)")
            procedure.requirement = dependency.result
        }
    }

    @discardableResult func requireResultFrom<Dependency>(dependency: Dependency) -> Self where Dependency: ProcedureProcotol, Dependency: ResultInjectionProtocol, Dependency.Result == Optional<Requirement> {

        return inject(dependency: dependency) { procedure, dependency, errors in
            guard errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            guard let requirement = dependency.result else {
                procedure.cancel(withError: ProcedureKitError.requirementNotSatisfied()); return
            }
            procedure.log.verbose(message: "injecting \(dependency.result) from \(dependency)")
            procedure.requirement = requirement
        }
    }
}
