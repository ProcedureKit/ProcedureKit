//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

open class ResultProcedure<Output>: BlockProcedure, OutputProcedure {

    public typealias ThrowingOutputBlock = (ResultProcedure<Output>) throws -> Output

    public var output: Pending<ProcedureResult<Output>> = .pending

    public override init(block: @escaping SelfBlock) {
        super.init(block: block)
    }

    public init(block: @escaping ThrowingOutputBlock) {
        super.init { (procedure) in
            var outputProcedure = procedure as! ResultProcedure<Output>
            defer {
                if false == outputProcedure.isFinished {
                    outputProcedure.finish(with: outputProcedure.output.error)
                }
            }
            do {
                outputProcedure.output = .ready(.success(try block(outputProcedure)))
            }
            catch {
                outputProcedure.output = .ready(.failure(error))
            }
        }
    }

    public init(block: @escaping () throws -> Output) {
        super.init { (procedure) in
            var outputProcedure = procedure as! ResultProcedure<Output>
            defer { outputProcedure.finish(with: outputProcedure.output.error) }
            do { outputProcedure.output = .ready(.success(try block())) }
            catch { outputProcedure.output = .ready(.failure(error)) }
        }
    }
}

open class AsyncResultProcedure<Output>: ResultProcedure<Output> {

    public typealias FinishingBlock = (ProcedureResult<Output>) -> Void
    public typealias Block = (@escaping FinishingBlock) -> Void

    public init(block: @escaping Block) {
        super.init { (procedure) in
            block { result in
                let outputProcedure = procedure as! ResultProcedure<Output>
                outputProcedure.finish(withResult: result)
            }
        }
    }
}

@available(*, deprecated: 5.0, message: "Use ResultProcedure directly and query the procedure argument inside your block.")
open class CancellableResultProcedure<Output>: ResultProcedure<Output> {

    /// A block that receives a closure (that returns the current value of `isCancelled`
    /// for the CancellableResultProcedure), and returns a value (which is set as the
    /// CancellableResultProcedure's `output`).
    public typealias ThrowingCancellableOutputBlock = (() -> Bool) throws -> Output

    public init(cancellableBlock: @escaping ThrowingCancellableOutputBlock) {
        super.init { (resultProcedure) -> Output in
            return try cancellableBlock { resultProcedure.isCancelled }
        }
    }
}
