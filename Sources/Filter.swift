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

    public init<S: Sequence>(source: S, isIncluded block: @escaping (Element) throws -> Bool) where S.Iterator.Element == Element, S.SubSequence : Sequence, S.SubSequence.Iterator.Element == Element, S.SubSequence.SubSequence == S.SubSequence {
        requirement = AnySequence(source)
        isIncluded = block
        super.init()
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
