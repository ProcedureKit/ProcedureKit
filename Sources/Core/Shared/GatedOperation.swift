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

 Use this class to execute another operation depending on other
 logic. Unlike a `BlockCondition` this will not fail the operation.
*/
public class GatedOperation<T: NSOperation>: ComposedOperation<T> {

    public typealias GateBlockType = () -> Bool

    let gate: GateBlockType

    /**
     Return true from the block to have the composed operation
     be executed, return false and the operation will not
     be executed.

     - parameter operation: any subclass of `NSOperation`.
     - parameter gate: a block which returns a Bool.
    */
    public init(_ operation: T, gate: GateBlockType) {
        self.gate = gate
        super.init(operation: operation)
    }

    /**
     Executes the block. If the result of executing the gate is
     true, the composed operation will start. If the gate is
     false, this operation will finish. Note that if the gate is
     closed, the operation does not "fail" i.e. finish with errors.
    */
    public override func execute() {
        if gate() {
            super.execute()
        }
        else {
            finish()
        }
    }
}
