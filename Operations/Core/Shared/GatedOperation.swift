//
//  GatedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
Allows a `NSOperation` to be composed inside an `Operation`, 
with a block to act as a gate.
*/
public class GatedOperation<O: NSOperation>: GroupOperation {

    public typealias GateBlockType = () -> Bool

    /// The composed generic operation
    public let operation: O
    let gate: GateBlockType

    /**
    Return true from the block to have the composed operation
    be executed, return false and the operation will not
    be executed.
    
    - parameter operation: any subclass of `NSOperation`.
    - parameter gate: a block which returns a Bool.
    */
    public init(operation: O, gate: GateBlockType) {
        self.operation = operation
        self.gate = gate
        super.init(operations: [])
    }

    /**
    Executes the block. If the result of executing the gate is
    true, the operation is added. Then we call super.execute()
    which will start the group's queue, meaning that the composed
    operation will start.
    */
    public override func execute() {
        if gate() {
            addOperation(operation)
        }
        super.execute()
    }
}

