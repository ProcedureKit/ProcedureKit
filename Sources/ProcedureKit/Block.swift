//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

import Foundation

open class BlockProcedure: Procedure {

    public typealias SelfBlock = (BlockProcedure) -> Void
    public typealias ThrowingVoidBlock = () throws -> Void

    enum BlockStorage {
        case asSelf(SelfBlock)
        case asVoid(ThrowingVoidBlock)
    }

    public static var defaultTimeoutInterval: TimeInterval = 3.0

    let storage: BlockStorage

    public init(block: @escaping SelfBlock) {
        self.storage = .asSelf(block)
        super.init()
        addObserver(TimeoutObserver(by: BlockProcedure.defaultTimeoutInterval))
    }

    public init(block: @escaping ThrowingVoidBlock) {
        self.storage = .asVoid(block)
        super.init()
    }

    open override func execute() {
        switch storage {
        case let .asSelf(block):
            block(self)
        case let .asVoid(block):
            do {
                try block()
                finish()
            }
            catch { finish(with: error) }
        }
    }

    open override func procedureDidCancel(with error: Error?) {
        if let procedureKitError = error as? ProcedureKitError {
            if case .timedOut(.by(BlockProcedure.defaultTimeoutInterval)) = procedureKitError.context {
                log.warning.message("Block not finished after \(BlockProcedure.defaultTimeoutInterval) seconds. This is likely a mistake, check that this block calls .finish() on all code paths.")
            }
        }
    }
}

/*
 A block based procedure which execute the provided block on the UI/main thread.
 */
open class UIBlockProcedure: BlockProcedure {

    public override init(block: @escaping ThrowingVoidBlock) {
        super.init { (procedure) in

            guard DispatchQueue.isMainDispatchQueue == false else {
                do {
                    try block()
                    procedure.finish()
                }
                catch { procedure.finish(with: error) }
                return
            }

            let sub = BlockProcedure(block: block)
            sub.log.enabled = false

            sub.addDidFinishBlockObserver { (_, error) in
                if let error = error {
                    procedure.finish(with: ProcedureKitError.dependency(finishedWithError: error))
                } else {
                    procedure.finish()
                }
            }

            ProcedureQueue.main.addOperation(sub)
        }
    }
}


@available(*, deprecated, message: "Use BlockProcedure directly and call .finish() on the block argument instead.")
open class AsyncBlockProcedure: BlockProcedure {

    public typealias Output = Void
    public typealias FinishingBlock = (ProcedureResult<Output>) -> Void
    public typealias Block = (@escaping FinishingBlock) -> Void

    public init(block: @escaping Block) {
        super.init { (procedure) in
            block { result in
                procedure.finish(with: result.error)
            }
        }
    }
}

@available(*, deprecated, message: "Use BlockProcedure directly and query the procedure argument inside your block.")
open class CancellableBlockProcedure: BlockProcedure {

    /// A block that receives a closure (that returns the current value of `isCancelled`
    /// for the CancellableResultProcedure), and returns a value (which is set as the
    /// CancellableResultProcedure's `output`).
    public typealias ThrowingCancellableBlock = (() -> Bool) throws -> Void

    public init(cancellableBlock: @escaping ThrowingCancellableBlock) {
        super.init { (procedure) in
            do {
                try cancellableBlock { procedure.isCancelled }
                procedure.finish()
            }
            catch { procedure.finish(with: error) }
        }
    }
}

