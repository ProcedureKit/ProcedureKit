//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

open class ResultProcedure<Output>: Procedure, OutputProcedure {

    public typealias ThrowingOutputBlock = () throws -> Output

    public var output: Pending<ProcedureResult<Output>> = .pending

    public let block: ThrowingOutputBlock

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

open class AsyncResultProcedure<Output>: Procedure, OutputProcedure {

    public typealias FinishingBlock = (ProcedureResult<Output>) -> Void
    public typealias Block = (@escaping FinishingBlock) -> Void

    public let block: Block

    public var output: Pending<ProcedureResult<Output>> = .pending

    public init(block: @escaping Block) {
        self.block = block
        super.init()
    }

    open override func execute() {
        block { [weak self] in self?.finish(withResult: $0) }
    }
}

open class AsyncBlockProcedure: AsyncResultProcedure<Void> { }

open class CancellableResultProcedure<Output>: Procedure, OutputProcedure {

    /// A block that receives a closure (that returns the current value of `isCancelled`
    /// for the CancellableResultProcedure), and returns a value (which is set as the
    /// CancellableResultProcedure's `output`).
    public typealias ThrowingCancellableOutputBlock = (() -> Bool) throws -> Output

    public var output: Pending<ProcedureResult<Output>> = .pending

    public let block: ThrowingCancellableOutputBlock

    public init(cancellableBlock: @escaping ThrowingCancellableOutputBlock) {
        self.block = cancellableBlock
        super.init()
    }

    open override func execute() {
        defer { finish(withError: output.error) }
        do { output = .ready(.success(try block({[unowned self] in return self.isCancelled }))) }
        catch { output = .ready(.failure(error)) }
    }
}

open class CancellableBlockProcedure: CancellableResultProcedure<Void> { }

/*
 A block based procedure which execute the provided block on the UI/main thread.
 */
open class UIBlockProcedure: AsyncBlockProcedure {

    open override func execute() {
        let substitute = AsyncBlockProcedure(block: block)
        substitute.addDidFinishBlockObserver { (_, errors) in
            self.finish(withErrors: errors)
        }
        substitute.addDidCancelBlockObserver { (_, errors) in
            self.cancel(withErrors: errors)
        }
        ProcedureQueue.main.add(operation: substitute)
    }
}
