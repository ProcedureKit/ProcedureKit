//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

open class MapProcedure<Element, U>: ReduceProcedure<Element, Array<U>> {

    public init<S: Sequence>(source: S, transform: @escaping (Element) throws -> U) where S.Iterator.Element == Element {
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

public extension OutputProcedure where Self.Output: Sequence {

    func map<U>(transform: @escaping (Output.Iterator.Element) throws -> U) -> MapProcedure<Output.Iterator.Element, U> {
        return MapProcedure(transform: transform).injectResult(from: self) { AnySequence(Array($0)) }
    }
}

open class FlatMapProcedure<Element, U>: ReduceProcedure<Element, Array<U>> {

    public init<S: Sequence>(source: S, transform: @escaping (Element) throws -> U?) where S.Iterator.Element == Element {
        super.init(source: source, initial: Array<U>()) { acc, element in
            guard let u = try transform(element) else { return acc }
            return acc + [u]
        }
    }

    public convenience init(transform: @escaping (Element) throws -> U?) {
        self.init(source: [], transform: transform)
    }
}

public extension OutputProcedure where Self.Output: Sequence {

    func flatMap<U>(transform: @escaping (Output.Iterator.Element) throws -> U?) -> FlatMapProcedure<Output.Iterator.Element, U> {
        return FlatMapProcedure(transform: transform).injectResult(from: self) { AnySequence(Array($0)) }
    }
}
