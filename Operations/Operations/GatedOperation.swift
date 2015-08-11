//
//  GatedOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 24/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

public class GatedOperation<O: NSOperation>: GroupOperation {

    public typealias GateBlockType = () -> Bool

    public let operation: O
    let gate: GateBlockType

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

