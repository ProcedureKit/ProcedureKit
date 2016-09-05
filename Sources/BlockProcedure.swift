//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/**
 A `Procedure` which performs a transform mapping
 */
public class MapProcedure<Requirement, Result>: Procedure, ResultInjectionProtocol {

    public typealias Transform = (Requirement!) throws -> Result

    private let transform: Transform

    public var requirement: Requirement! = nil
    public var result: Result! = nil

    public init(transform: Transform) {
        self.transform = transform
        super.init()
    }

    public override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            result = try transform(requirement)
        }
        catch {
            finishingError = error
        }
    }
}

public class BlockProcedure: MapProcedure<Void, Void> {

    public init(block: @escaping () throws -> Void) {
        super.init { _ in try block() }
    }
}
