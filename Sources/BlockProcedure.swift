//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

/**
 A `Procedure` which composes a block.
 */
public class BlockProcedure<Requirement, Result>: Procedure, ResultInjectionProtocol {

    public typealias Block = (Requirement!) throws -> Result

    private let block: Block


    public var requirement: Requirement! = nil
    public var result: Result! = nil

    public init(block: Block) {
        self.block = block
        super.init()
    }

    public override func execute() {
        guard !isCancelled else { return }
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do {
            result = try block(requirement)
        }
        catch {
            finishingError = error
        }
    }
}

public typealias VoidBlockProcedure = BlockProcedure<Void, Void>
