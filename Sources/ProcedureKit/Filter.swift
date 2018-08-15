//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

open class FilterProcedure<Element>: ReduceProcedure<Element, Array<Element>> {

    public init<S: Sequence>(source: S, isIncluded: @escaping (Element) throws -> Bool) where S.Iterator.Element == Element {
        super.init(source: source, initial: []) { acc, element in
            guard try isIncluded(element) else { return acc }
            return acc + [element]
        }
    }

    public convenience init(isIncluded block: @escaping (Element) throws -> Bool) {
        self.init(source: [], isIncluded: block)
    }
}

public extension OutputProcedure where Self.Output: Sequence {

    func filter(includeElement: @escaping (Output.Iterator.Element) throws -> Bool) -> FilterProcedure<Output.Iterator.Element> {
        return FilterProcedure(isIncluded: includeElement).injectResult(from: self) { AnySequence(Array($0)) }
    }
}
