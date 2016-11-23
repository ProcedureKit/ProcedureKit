//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class ResultProcedure<Output>: Procedure, OutputProcedure {

    public typealias ThrowingOutputBlock = () throws -> Output

    public private(set) var output: Pending<Result<Output>> = .pending

    private let block: ThrowingOutputBlock

    public init(block: @escaping ThrowingOutputBlock) {
        self.block = block
        super.init()
    }

    open override func execute() {
        defer { finish(withError: output.error) }
        do { output = .ready(.success(try block())) }
        catch { output = .ready(.failure(error)) }
    }
}

open class BlockProcedure: ResultProcedure<Void> { }
