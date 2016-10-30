//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class ReduceProcedure<Element, U>: Procedure, ResultInjection {

    public let initial: U
    public let nextPartialResult: (U, Element) throws -> U
    public var requirement: PendingValue<AnySequence<Element>> = .pending
    public var result: PendingValue<U> = .pending

    public init<S: Sequence>(source: S, initial: U, nextPartialResult block: @escaping (U, Element) throws -> U) where S.Iterator.Element == Element, S.SubSequence: Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence {
        self.initial = initial
        self.nextPartialResult = block
        self.requirement = .ready(AnySequence(source))
        self.result = .ready(initial)
        super.init()
    }

    public convenience init(initial: U, nextPartialResult block: @escaping (U, Element) throws -> U) {
        self.init(source: [], initial: initial, nextPartialResult: block)
    }

    open override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            if let requirementValue = requirement.value {
                result = .ready(try requirementValue.reduce(initial, nextPartialResult))
            }
        }
        catch { finishingError = error }
    }
}

internal extension ProcedureProtocol where Self: ResultInjection, Self.Result: Sequence {

    func injectRequirement<P: ProcedureProtocol>(_ procedure: P) -> P where P: ResultInjection, P.Requirement == AnySequence<Self.Result.Iterator.Element> {
        procedure.inject(dependency: self) { procedure, dependency, errors in
            guard errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            guard let result = dependency.result.value else {
                procedure.cancel(withError: ProcedureKitError.requirementNotSatisfied()); return
            }
            procedure.requirement = .ready(AnySequence(Array(result)))
        }
        return procedure
    }
}

public extension ProcedureProtocol where Self: ResultInjection, Self.Result: Sequence {

    func reduce<U>(_ initial: U, nextPartialResult: @escaping (U, Result.Iterator.Element) throws -> U) -> ReduceProcedure<Result.Iterator.Element, U> {
        return injectRequirement(ReduceProcedure(initial: initial, nextPartialResult: nextPartialResult))
    }
}
