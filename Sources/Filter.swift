//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class FilterProcedure<Element>: ReduceProcedure<Element, Array<Element>> {

    public init<S: Sequence>(source: S, isIncluded: @escaping (Element) throws -> Bool) where S.Iterator.Element == Element, S.SubSequence: Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence {
        super.init(source: source, initial: []) { acc, element in
            guard try isIncluded(element) else { return acc }
            return acc + [element]
        }
    }

    public convenience init(isIncluded block: @escaping (Element) throws -> Bool) {
        self.init(source: [], isIncluded: block)
    }
}

public extension ProcedureProtocol where Self: ResultInjection, Self.Result: Sequence {

    func filter(includeElement: @escaping (Result.Iterator.Element) throws -> Bool) -> FilterProcedure<Result.Iterator.Element> {
        return injectRequirement(FilterProcedure(isIncluded: includeElement))
    }
}
