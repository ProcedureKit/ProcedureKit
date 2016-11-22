//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//


public enum Pending<T> {

    case pending
    case ready(T)

    public var isPending: Bool {
        guard case .pending = self else { return false }
        return true
    }

    public var value: T? {
        guard case let .ready(value) = self else { return nil }
        return value
    }
}

public enum Result<T> {

    case success(T)
    case failure(Error)

    public var value: T? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    public var error: Error? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}

public protocol InputProcedure: ProcedureProtocol {

    associatedtype Input

    var input: Pending<Input> { get set }
}

public protocol OutputProcedure: ProcedureProtocol {

    associatedtype Output

    var output: Pending<Result<Output>> { get }
}


// MARK: - Extensions

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

public extension InputProcedure {

    @discardableResult func injectResult<Dependency: OutputProcedure>(from dependency: Dependency, via block: @escaping (Dependency.Output) throws -> Input) -> Self {
        return inject(dependency: dependency) { procedure, dependency, errors in
            // Check if there are any errors first
            guard errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            // Check that we have a result ready
            guard let result = dependency.output.value else {
                procedure.cancel(withError: ProcedureKitError.requirementNotSatisfied()); return
            }
            // Check that the result was successful
            guard let output = result.value else {
                // If not, check for an error
                if let error = result.error {
                    procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: [error]))
                }
                else {
                    procedure.cancel(withError: ProcedureKitError.requirementNotSatisfied())
                }
                return
            }

            // Given successfull output
            do {
                procedure.input = .ready(try block(output))
            }
            catch {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: [error]))
            }
        }
    }

    @discardableResult func injectResult<Dependency: OutputProcedure>(from dependency: Dependency) -> Self where Dependency.Output == Input {
        return injectResult(from: dependency, via: { $0 })
    }

    @discardableResult func injectResult<Dependency: OutputProcedure>(from dependency: Dependency) -> Self where Dependency.Output == Optional<Input> {
        return injectResult(from: dependency) { output in
            guard let output = output else {
                throw ProcedureKitError.requirementNotSatisfied()
            }
            return output
        }
    }
}
