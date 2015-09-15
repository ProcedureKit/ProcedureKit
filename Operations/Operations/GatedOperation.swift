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

    public let operation: O
    let gate: GateBlockType

    /**
    Return true from the block to have the composed operation
    be executed, return false and the operation will not
    be executed.
    
    :param: operation, any subclass of `NSOperation`.
    :param: gate, a block which returns a Bool.
    */
    public init(operation: O, gate: GateBlockType) {
        self.operation = operation
        self.gate = gate
        super.init(operations: [])
    }

    public override func execute() {
        if gate() {
            addOperation(operation)
        }
        super.execute()
    }
}

