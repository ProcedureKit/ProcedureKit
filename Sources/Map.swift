//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class MapProcedure<Element, U>: ReduceProcedure<Element, Array<U>> {

    public init<S: Sequence>(source: S, transform: @escaping (Element) throws -> U) where S.Iterator.Element == Element, S.SubSequence: Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence {
        super.init(source: source, initial: Array<U>()) { acc, element in
            var accumulator = acc
            try accumulator.append(transform(element))
            return accumulator
        }
    }

    public convenience init(transform: @escaping (Element) throws -> U) {
        self.init(source: [], transform: transform)
    }
}

public extension ProcedureProtocol where Self: ResultInjection, Self.Result: Sequence {

    func map<U>(transform: @escaping (Result.Iterator.Element) throws -> U) -> MapProcedure<Result.Iterator.Element, U> {
        return injectRequirement(MapProcedure(transform: transform))
    }
}

open class FlatMapProcedure<Element, U>: ReduceProcedure<Element, Array<U>> {

    public init<S: Sequence>(source: S, transform: @escaping (Element) throws -> U?) where S.Iterator.Element == Element, S.SubSequence: Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence {
        super.init(source: source, initial: Array<U>()) { acc, element in
            guard let u = try transform(element) else { return acc }
            return acc + [u]
        }
    }

    public convenience init(transform: @escaping (Element) throws -> U?) {
        self.init(source: [], transform: transform)
    }
}

public extension ProcedureProtocol where Self: ResultInjection, Self.Result: Sequence {

    func flatMap<U>(transform: @escaping (Result.Iterator.Element) throws -> U?) -> FlatMapProcedure<Result.Iterator.Element, U> {
        return injectRequirement(FlatMapProcedure(transform: transform))
    }
}
