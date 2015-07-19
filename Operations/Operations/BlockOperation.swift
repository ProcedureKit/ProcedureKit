//
//  BlockOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 18/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class BlockOperation: Operation {

    public typealias ContinuationBlockType = Void -> Void
    public typealias BlockType = (ContinuationBlockType) -> Void

    private let block: BlockType?

    /**
    Designated initializer.
    
    - parameter block: The closure to run when the operation executes.
    If this block is nil, the operation will immediately finish.
    */
    public init(block: BlockType? = .None) {
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
                continuation()
            }
        })
    }

    public override func execute() {
        guard let block = block else {
            finish()
            return
        }

        block { self.finish() }
    }
}




