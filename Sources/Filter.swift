//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public class FilterProcedure<Element>: Procedure, ResultInjectionProtocol {

    public var requirement: AnySequence<Element>
    public var result: Array<Element> = []
    public let isIncluded: (Element) throws -> Bool

    public init<S: Sequence>(source: S, isIncluded block: @escaping (Element) throws -> Bool) where S.Iterator.Element == Element, S.SubSequence: Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence {
        requirement = AnySequence(source)
        isIncluded = block
        super.init()
    }

    public convenience init(isIncluded block: @escaping (Element) throws -> Bool) {
        self.init(source: [], isIncluded: block)
    }

    public override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            result = try requirement.filter(isIncluded)
        }
        catch { finishingError = error }
    }
}

public extension ProcedureProtocol where Self: ResultInjectionProtocol, Self.Result: Sequence {

    func filter(includeElement: @escaping (Result.Iterator.Element) throws -> Bool) -> FilterProcedure<Result.Iterator.Element> {
        let filter = FilterProcedure(isIncluded: includeElement)
        filter.inject(dependency: self) { filter, dependency, errors in
            guard errors.isEmpty else {
                filter.cancel(withError: ProcedureKitError.dependency(finishedWithErrors: errors)); return
            }
            filter.requirement = AnySequence(Array(dependency.result))
        }
        return filter
    }
}
