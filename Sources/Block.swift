//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class ResultProcedure<Output>: Procedure, OutputProcedure {

    public private(set) var output: Pending<Result<Output>> = .pending

    public typealias ThrowingOutputBlock = () throws -> Output

    private let block: ThrowingOutputBlock

    public init(block: @escaping ThrowingOutputBlock) {
        self.block = block
        super.init()
    }

    open override func execute() {
        var finishingError: Error? = nil
        defer { finish(withError: finishingError) }
        do { output = .ready(.success(try block())) }
        catch {
            output = .ready(.failure(error))
            finishingError = error
        }
    }
}

open class BlockProcedure: ResultProcedure<Void> { }
