//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

public protocol ResultInjectionProtocol: class {

    associatedtype Requirement
    associatedtype Result

    var requirement: Requirement { get set }
    var result: Result { get }
}

public extension ProcedureProtocol {

    /**
     Access the completed dependency operation before `self` is
     started. This can be useful for transfering results/data between
     operations.

     - parameters dep: any `Operation` subclass.
     - parameters block: a closure which receives `self`, the dependent
     operation, and an array of `ErrorType`, and returns Void.
     - returns: `self` - so that injections can be chained together.
     */
    @discardableResult func inject<Dependency: ProcedureProtocol>(dependency: Dependency, block: @escaping (Self, Dependency, [Error]) -> Void) -> Self {

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

public extension ProcedureProtocol where Self: ResultInjectionProtocol {

    @discardableResult public func injectResult<Dependency: ProcedureProtocol>(from dependency: Dependency, via block: @escaping (Dependency.Result) throws -> Requirement) -> Self where Dependency: ResultInjectionProtocol {

        return inject(dependency: dependency) { procedure, dependency, errors in
            guard errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            do {
                procedure.requirement = try block(dependency.result)
            }
            catch {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
        }
    }

    @discardableResult func injectResult<Dependency: ProcedureProtocol>(from dependency: Dependency) -> Self where Dependency: ResultInjectionProtocol, Dependency.Result == Requirement {
        return injectResult(from: dependency, via: { $0 })
    }

    @discardableResult func requireResult<Dependency: ProcedureProtocol>(from dependency: Dependency) -> Self where Dependency: ResultInjectionProtocol, Dependency.Result == Optional<Requirement> {
        return injectResult(from: dependency) { result in
            guard let requirement = result else { throw ProcedureKitError.requirementNotSatisfied() }
            return requirement
        }
    }
}
