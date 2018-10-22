//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
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

extension Pending: Equatable where T: Equatable {

    public static func == (lhs: Pending<T>, rhs: Pending<T>) -> Bool {
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

extension Pending: ProcedureResultProtocol where T: ProcedureResultProtocol {

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

extension ProcedureResult: Equatable where T: Equatable {

    public static func == (lhs: ProcedureResult<T>, rhs: ProcedureResult<T>) -> Bool {
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
        finish(with: output.error)
    }
}

private enum InjectionResult<Dependency: OutputProcedure> {
    case success(Dependency.Output)
    case cancel(Error)
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
    @discardableResult func inject<Dependency: ProcedureProtocol>(dependency: Dependency, block: @escaping (Self, Dependency, Error?) -> Void) -> Self {
        precondition(dependency !== self, "Cannot inject result of self into self.")

        dependency.addWillFinishBlockObserver(synchronizedWith: (self as? QueueProvider)) { [weak self] dependency, error, _ in
            guard let this = self else { return }
            block(this, dependency, error)
        }

        dependency.addDidCancelBlockObserver { [weak self] _, error in
            guard let this = self else { return }
            if let dependencyError = error {
                this.cancel(with: ProcedureKitError.dependency(cancelledWithError: dependencyError))
            }
            else {
                this.cancel(with: ProcedureKitError.dependenciesCancelled())
            }
        }

        add(dependency: dependency)

        return self
    }

    @discardableResult func injectResult<Dependency: OutputProcedure>(from dependency: Dependency, block: @escaping (Self, Dependency.Output) -> Void) -> Self {

        func injectionResultGiven(_ pendingResult: Pending<ProcedureResult<Dependency.Output>>, and error: Error?) -> InjectionResult<Dependency> {

            if let error = error {
                return .cancel(ProcedureKitError.dependency(finishedWithError: error))
            }

            switch pendingResult {

            case .pending:
                return .cancel(ProcedureKitError.requirementNotSatisfied())

            case let .ready(.failure(error)):
                return .cancel(ProcedureKitError.dependency(finishedWithError: error))

            case let .ready(.success(output)):
                return .success(output)
            }
        }

        return inject(dependency: dependency) { procedure, dependency, error in

            switch injectionResultGiven(dependency.output, and: error) {
            case let .cancel(e):
                procedure.cancel(with: e)
            case let .success(output):
                block(procedure, output)
            }
        }
    }
}

public extension InputProcedure {

    /// Notifies observers that the input was set .ready
    func didSetInputReady() {
        guard !input.isPending, let procedure = self as? Procedure else { return }
        procedure.eventQueue.dispatch {
            procedure.dispatchObservers(pendingEvent: PendingEvent.execute) { (observer, event) in
                observer.didSetInputReady(on: procedure)
            }
        }
    }

    @discardableResult func injectResult<Dependency: OutputProcedure>(from dependency: Dependency, via block: @escaping (Dependency.Output) throws -> Input) -> Self {

        return injectResult(from: dependency) { (procedure, output) in
            do {
                procedure.input = .ready(try block(output))

                procedure.didSetInputReady()
            }
            catch {
                procedure.cancel(with: error)
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

// MARK: - Bindings

public extension InputProcedure {

    func bind<T: InputProcedure>(to target: T) where T.Input == Self.Input {
        addDidSetInputReadyBlockObserver { (procedure) in
            target.input = procedure.input
        }
    }
}

public extension OutputProcedure {

    func bind<T: OutputProcedure>(from source: T) where T.Output == Self.Output {
        source.addWillFinishBlockObserver { [weak self] (source, _, _) in
            guard let strongSelf = self else { return }
            strongSelf.output = source.output
        }
    }
}



