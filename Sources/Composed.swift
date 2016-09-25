//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation

public class ComposedProcedure<T: Operation>: GroupProcedure {

    public private(set) var operation: T

    public convenience init(_ composed: T) {
        self.init(operation: composed)
    }

    public init(operation: T) {
        self.operation = operation
        super.init(operations: [operation])
    }
}

public class GatedProcedure<T: Operation>: ComposedProcedure<T> {

    public convenience init(_ composed: T, gate: @escaping ThrowingBoolBlock) {
        self.init(operation: composed, gate: gate)
    }

    public init(operation: T, gate: @escaping ThrowingBoolBlock) {
        super.init(operation: operation)
        attach(condition: IgnoredCondition(BlockCondition(block: gate)))
    }
}
