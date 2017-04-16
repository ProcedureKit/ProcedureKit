//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public extension Procedure {

    public struct Chain<Output> {
        public let procedures: [Procedure]
        public let tail: AnyOutputProcedure<Output>

        internal func add<NewOutput>(newTail: AnyOutputProcedure<NewOutput>) -> Chain<NewOutput> {
            var newProcedures = procedures
            newProcedures.append(newTail)
            return Procedure.Chain<NewOutput>(procedures: newProcedures, tail: newTail)
        }

        public func transform<TransformedOutput>(block: @escaping (Output) throws -> TransformedOutput) -> Procedure.Chain<TransformedOutput> {
            let transform = TransformProcedure(transform: block)
            transform.injectResult(from: tail)
            return add(newTail: AnyOutputProcedure(transform))
        }

        public func transform<TransformedOutput>(block: @escaping (Output, (ProcedureResult<TransformedOutput>) -> Void) -> Void) -> Procedure.Chain<TransformedOutput> {
            let transform = AsyncTransformProcedure(transform: block)
            transform.injectResult(from: tail)
            return add(newTail: AnyOutputProcedure(transform))
        }
    }
}

public extension Procedure.Chain where Output: Sequence {

    func filter(includeElement: @escaping (Output.Iterator.Element) throws -> Bool) -> Procedure.Chain<Array<Output.Iterator.Element>> {
        return add(newTail: AnyOutputProcedure(tail.filter(includeElement: includeElement)))
    }

    func map<U>(transform: @escaping (Output.Iterator.Element) throws -> U) -> Procedure.Chain<[U]> {
        return add(newTail: AnyOutputProcedure(tail.map(transform: transform)))
    }

    func flatMap<U>(transform: @escaping (Output.Iterator.Element) throws -> U?) -> Procedure.Chain<[U]> {
        return add(newTail: AnyOutputProcedure(tail.flatMap(transform: transform)))
    }

    func reduce<U>(_ initial: U, nextPartialResult: @escaping (U, Output.Iterator.Element) throws -> U) -> Procedure.Chain<U> {
        return add(newTail: AnyOutputProcedure(tail.reduce(initial, nextPartialResult: nextPartialResult)))
    }
}

public extension OutputProcedure where Self: Procedure {

    var chain: Procedure.Chain<Output> {
        get {
            let tail = AnyOutputProcedure(self)
            return Procedure.Chain(procedures: [tail], tail: tail)
        }
    }

    func transform<TransformedOutput>(block: @escaping (Output) throws -> TransformedOutput) -> Procedure.Chain<TransformedOutput> {
        let tail = AnyOutputProcedure(self)
        return Procedure.Chain(procedures: [tail], tail: tail).transform(block: block)
    }

    public func transform<TransformedOutput>(block: @escaping (Output, (ProcedureResult<TransformedOutput>) -> Void) -> Void) -> Procedure.Chain<TransformedOutput> {
        let tail = AnyOutputProcedure(self)
        return Procedure.Chain(procedures: [tail], tail: tail).transform(block: block)
    }
}

public extension ProcedureQueue {

    func add<Output>(chain: Procedure.Chain<Output>) {
        add(operations: chain.procedures)
    }
}
