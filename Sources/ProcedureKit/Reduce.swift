//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

open class ReduceProcedure<Element, U>: TransformProcedure<AnySequence<Element>, U> {

    public init<S: Sequence>(source: S, initial: U, nextPartialResult block: @escaping (U, Element) throws -> U) where S.Iterator.Element == Element {
        super.init { try $0.reduce(initial, block) }
        self.input = .ready(AnySequence(source))
        self.output = .ready(.success(initial))
    }

    public convenience init(initial: U, nextPartialResult block: @escaping (U, Element) throws -> U) {
        self.init(source: [], initial: initial, nextPartialResult: block)
    }
}

public extension OutputProcedure where Self.Output: Sequence {

    func reduce<U>(_ initial: U, nextPartialResult: @escaping (U, Output.Iterator.Element) throws -> U) -> ReduceProcedure<Output.Iterator.Element, U> {
        return ReduceProcedure(initial: initial, nextPartialResult: nextPartialResult).injectResult(from: self) { AnySequence(Array($0)) }
    }
}
