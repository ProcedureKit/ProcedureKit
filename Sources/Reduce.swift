//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public class ReduceProcedure<Element, U>: Procedure, ResultInjectionProtocol {

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

    public override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            result = try requirement.reduce(initial, nextPartialResult)
        }
        catch { finishingError = error }
    }
}

public extension ProcedureProtocol where Self: ResultInjectionProtocol, Self.Result: Sequence {

    func reduce<ReducedResult>(_ initial: ReducedResult, nextPartialResult: @escaping (ReducedResult, Result.Iterator.Element) throws -> ReducedResult) -> ReduceProcedure<Result.Iterator.Element, ReducedResult> {

        let reduce = ReduceProcedure(initial: initial, nextPartialResult: nextPartialResult)
        reduce.inject(dependency: self) { reduce, dependency, errors in
            guard errors.isEmpty else {
                reduce.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            reduce.requirement = AnySequence(Array(dependency.result))
        }
        return reduce
    }
}
