//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class ResultProcedure<Result>: Procedure, ResultInjection {
    public var requirement: PendingValue<Void> = .void
    public private(set) var result: PendingValue<Result> = .pending

    public typealias ThrowingResultBlock = () throws -> Result

    private let block: ThrowingResultBlock

    public init(block: @escaping ThrowingResultBlock) {
        self.block = block
        super.init()
    }

    open override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do { result = .ready(try block()) }
        catch { finishingError = error }
    }
}

open class BlockProcedure: ResultProcedure<Void> { }
