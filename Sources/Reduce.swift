//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

open class ReduceProcedure<Element, U>: Procedure, ResultInjectionProtocol {

    public var requirement: AnySequence<Element>
    public var result: U
    public let initial: U
    public let nextPartialResult: (U, Element) throws -> U

    public init<S: Sequence>(source: S, initial: U, nextPartialResult block: @escaping (U, Element) throws -> U) where S.Iterator.Element == Element, S.SubSequence: Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence {
        self.requirement = AnySequence(source)
        self.initial = initial
        self.result = initial
        self.nextPartialResult = block
        super.init()
    }

    public convenience init(initial: U, nextPartialResult block: @escaping (U, Element) throws -> U) {
        self.init(source: [], initial: initial, nextPartialResult: block)
    }

    open override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            result = try requirement.reduce(initial, nextPartialResult)
        }
        catch { finishingError = error }
    }
}

internal extension ProcedureProtocol where Self: ResultInjectionProtocol, Self.Result: Sequence {

    func injectRequirement<P: ProcedureProtocol>(_ procedure: P) -> P where P: ResultInjectionProtocol, P.Requirement == AnySequence<Self.Result.Iterator.Element> {
        procedure.inject(dependency: self) { procedure, dependency, errors in
            guard errors.isEmpty else {
                procedure.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            procedure.requirement = AnySequence(Array(dependency.result))
        }
        return procedure
    }
}

public extension ProcedureProtocol where Self: ResultInjectionProtocol, Self.Result: Sequence {

    func reduce<U>(_ initial: U, nextPartialResult: @escaping (U, Result.Iterator.Element) throws -> U) -> ReduceProcedure<Result.Iterator.Element, U> {
        return injectRequirement(ReduceProcedure(initial: initial, nextPartialResult: nextPartialResult))
    }
}
