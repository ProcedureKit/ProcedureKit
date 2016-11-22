//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class ReduceProcedure<Element, U>: Procedure, InputProcedure, OutputProcedure {

    public let initial: U
    public let nextPartialResult: (U, Element) throws -> U
    public var input: Pending<AnySequence<Element>> = .pending
    public var output: Pending<Result<U>> = .pending

    public init<S: Sequence>(source: S, initial: U, nextPartialResult block: @escaping (U, Element) throws -> U) where S.Iterator.Element == Element, S.SubSequence: Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence {
        self.initial = initial
        self.nextPartialResult = block
        self.input = .ready(AnySequence(source))
        self.output = .ready(.success(initial))
        super.init()
    }

    public convenience init(initial: U, nextPartialResult block: @escaping (U, Element) throws -> U) {
        self.init(source: [], initial: initial, nextPartialResult: block)
    }

    open override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            guard let inputValue = input.value else { throw ProcedureKitError.requirementNotSatisfied() }
            output = .ready(.success(try inputValue.reduce(initial, nextPartialResult)))
        }
        catch {
            output = .ready(.failure(error))
            finishingError = error
        }
    }
}

public extension OutputProcedure where Self.Output: Sequence {

    func reduce<U>(_ initial: U, nextPartialResult: @escaping (U, Output.Iterator.Element) throws -> U) -> ReduceProcedure<Output.Iterator.Element, U> {
        return ReduceProcedure(initial: initial, nextPartialResult: nextPartialResult).injectResult(from: self) { AnySequence(Array($0)) }
    }
}
