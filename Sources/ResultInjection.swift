//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

public enum PendingValue<T> {
    case void
    case pending
    case ready(T)

    public var value: T? {
        guard case let .ready(value) = self else { return nil }
        return value
    }

    var isPending: Bool {
        if case .pending = self {
            return true
        }
        return false
    }
}

extension PendingValue where T: Equatable {

    static func==(lhs: PendingValue<T>, rhs: PendingValue<T>) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending), (.void, .void):
            return true
        case let (.ready(lhsValue), .ready(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

public protocol ResultInjection: class {

    associatedtype Requirement
    associatedtype Result

    var requirement: PendingValue<Requirement> { get set }
    var result: PendingValue<Result> { get }
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

public extension ProcedureProtocol where Self: ResultInjection {

    @discardableResult func injectResult<Dependency: ProcedureProtocol>(from dependency: Dependency, via block: @escaping (Dependency.Result) throws -> Requirement) -> Self where Dependency: ResultInjection {

        return inject(dependency: dependency) { procedure, dependency, errors in
            guard errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            guard let result = dependency.result.value else {
                procedure.cancel(withError: ProcedureKitError.requirementNotSatisfied()); return
            }
            do {
                procedure.requirement = .ready(try block(result))
            }
            catch {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
        }
    }

    @discardableResult func injectResult<Dependency: ProcedureProtocol>(from dependency: Dependency) -> Self where Dependency: ResultInjection, Dependency.Result == Requirement {
        return injectResult(from: dependency, via: { $0 })
    }

    @discardableResult func injectResult<Dependency: ProcedureProtocol>(from dependency: Dependency) -> Self where Dependency: ResultInjection, Dependency.Result == Optional<Requirement> {
        return injectResult(from: dependency) { result in
            guard let value = result else {
                throw ProcedureKitError.requirementNotSatisfied()
            }
            return value
        }
    }
}
