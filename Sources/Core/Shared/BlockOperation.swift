//
//  OldBlockOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
An `OldOperation` subclass to compose a block. The block type receives
a "continuation block" as its only argument. The block provided must
call this block to correctly finish the operation. It can be called
with a nil error argument to finish with no errors. Or an `ErrorType`
argument to finish with the supplied error.
*/
public class OldBlockOperation: OldOperation {

    public typealias ContinuationBlockType = (error: ErrorProtocol?) -> Void
    public typealias BlockType = (continueWithError: ContinuationBlockType) -> Void

    private let block: BlockType

    /**
    Designated initializer.

    - parameter block: The closure to run when the operation executes.
    If this block is nil, the operation will immediately finish.
    */
    public init(block: BlockType = { continuation in continuation(error: nil) }) {
        self.block = block
        super.init()
        name = "OldBlockOperation"
    }

    /**
    Convenience initializer.

    - parameter block: a dispatch block which is run on the main thread.
    */
    public convenience init(mainQueueBlock: ()->()) {
        self.init(block: { continuation in
            Queue.main.queue.async {
                mainQueueBlock()
                continuation(error: nil)
            }
        })
    }

    /**
    Executes the block. The block is passed another block which receives an optional
    error which is passed to finish.

    In other words, the operation is initialized with a block which receives a
    "continuation" block. The consumer must call this continuation block to finish
    the operation. Errors can be propagated from the block to the operation by passing
    them to this continuation block.
    */
    public override func execute() {
        if !isCancelled {
            block { error in self.finish(error) }
        }
    }
}
