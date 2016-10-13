//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class BlockProcedure: Procedure {

    public typealias ThrowingVoidBlock = () throws -> Void

    private let block: ThrowingVoidBlock

    public init(block: @escaping ThrowingVoidBlock) {
        self.block = block
        super.init()
    }

    open override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do { try block() }
        catch { finishingError = error }
    }
}
