//
//  BlockOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class BlockOperation: Operation {

    public typealias ContinuationBlockType = (error: ErrorType?) -> Void
    public typealias BlockType = (continueWithError: ContinuationBlockType) -> Void

    private let block: BlockType

    /**
    Designated initializer.
    
    - parameter block: The closure to run when the operation executes.
    If this block is nil, the operation will immediately finish.
    */
    public init(block: BlockType = { (continueWithError) in continueWithError(error: nil) }) {
        self.block = block
        super.init()
    }

    /**
    Convenience initializer.
    
    - paramter block: a dispatch block which is run on the main thread.
    */
    public convenience init(mainQueueBlock: dispatch_block_t) {
        self.init(block: { continuation in
            dispatch_async(Queue.Main.queue) {
                mainQueueBlock()
                continuation(error: nil)
            }
        })
    }

    public override func execute() {
        block { error in self.finish(error) }
    }
}




