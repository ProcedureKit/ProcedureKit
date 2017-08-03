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

    public init(_ value: T?) {
        self = value.pending
    }
}

extension Pending where T: Equatable {

    static func == (lhs: Pending<T>, rhs: Pending<T>) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending):
            return true
        case let (.ready(lhsValue), .ready(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

public extension Optional {

    var pending: Pending<Wrapped> {
        switch self {
        case .none:
            return .pending
        case let .some(value):
            return .ready(value)
        }
    }
}

public protocol ProcedureResultProtocol {
    associatedtype Value

    var value: Value? { get }

    var error: Error? { get }
}

extension Pending where T: ProcedureResultProtocol {

    public var success: T.Value? {
        return value?.value
    }

    public var error: Error? {
        return value?.error
    }
}

public enum ProcedureResult<T>: ProcedureResultProtocol {

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

extension ProcedureResult where T: Equatable {

    static func == (lhs: ProcedureResult<T>, rhs: ProcedureResult<T>) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsValue), .success(rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

public protocol InputProcedure: ProcedureProtocol {

    associatedtype Input

    var input: Pending<Input> { get set }
}

public protocol OutputProcedure: ProcedureProtocol {

    associatedtype Output

    var output: Pending<ProcedureResult<Output>> { get set }
}

public let pendingVoid: Pending<Void> = .ready(())
public let success: ProcedureResult<Void> = .success(())
public let pendingVoidResult: Pending<ProcedureResult<Void>> = .ready(success)

// MARK: - Extensions

public extension OutputProcedure {

    func finish(withResult result: ProcedureResult<Output>) {
        output = .ready(result)
        finish(withError: output.error)
    }
}

public extension ProcedureProtocol {

    /**
     Access the completed dependency Procedure before `self` is
     started. This can be useful for transfering results/data between
     Procedures.

     - parameter dependency: any `Procedure` subclass.
     - parameter block: a closure which receives `self`, the dependent
     operation, and an array of `ErrorType`, and returns Void.
     (The closure is automatically dispatched on the EventQueue
     of the receiver, if the receiver is a Procedure or supports the
     QueueProvider protocol).
     - returns: `self` - so that injections can be chained together.
     */
    @discardableResult func inject<Dependency: ProcedureProtocol>(dependency: Dependency, block: @escaping (Self, Dependency, [Error]) -> Void) -> Self {
        precondition(dependency !== self, "Cannot inject result of self into self.")

        dependency.addWillFinishBlockObserver(synchronizedWith: (self as? QueueProvider)) { [weak self] dependency, errors, _ in
            if let strongSelf = self {
                block(strongSelf, dependency, errors)
            }
        }

        dependency.addDidCancelBlockObserver { [weak self] _, errors in
            if let strongSelf = self {
                strongSelf.cancel(withError: ProcedureKitError.dependency(cancelledWithErrors: errors))
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
