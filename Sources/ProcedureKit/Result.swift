//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

/// A BlockProcedure subclass which returns an output value from a block
///
///  ResultProcedure is useful to return a value as
///     an `OutputProcedure`. This allow injection of a result into
///     Procedure subclasses which conform to InputProcedure.
///
///  The result can be returned synchonously, for example using
///     a literal:
///
///     let result = ResultProceure { return "Hello World" }
///
///  Or, if there is an error, it can be thrown.
///
///     let resultError = ResultProcedure<String> { throw MyError() }
/// 
open class ResultProcedure<Output>: BlockProcedure, OutputProcedure {

    public typealias ThrowingOutputBlock = (ResultProcedure<Output>) throws -> Output

    public var output: Pending<ProcedureResult<Output>> = .pending

    public override init(block: @escaping (ResultProcedure<Output>) -> Void) {
        super.init { block($0 as! ResultProcedure<Output>) }
    }

    /// Create a ResultProcedure using a throwing block
    ///
    /// - Parameter block: the block receives an instance of self,
    ///    and should return the `Output` value, or throw an error.
    ///    use the procedure argument to cancel use the logger etc.
    public init(block: @escaping ThrowingOutputBlock) {
        super.init { (procedure) -> Void in
            let resultProcedure = procedure as! ResultProcedure<Output>
            defer {
                if false == resultProcedure.isFinished {
                    resultProcedure.finish(with: resultProcedure.output.error)
                }
            }
            do {
                resultProcedure.output = .ready(.success(try block(resultProcedure)))
            }
            catch {
                resultProcedure.output = .ready(.failure(error))
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
                defer {
                    if false == procedure.isFinished {
                        procedure.finish(with: procedure.output.error)
                    }
                }
                procedure.finish(withResult: result)
            }
        }
    }
}

@available(*, deprecated, message: "Use ResultProcedure directly and query the procedure argument inside your block.")
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
