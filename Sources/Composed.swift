//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

open class ComposedProcedure<T: Operation>: GroupProcedure {

    public private(set) var operation: T

    public convenience init(_ composed: T) {
        self.init(operation: composed)
    }

    public init(dispatchQueue: DispatchQueue? = nil, operation: T) {
        self.operation = operation
        super.init(dispatchQueue: dispatchQueue, operations: [operation])
    }
}

open class GatedProcedure<T: Operation>: ComposedProcedure<T> {

    public convenience init(_ composed: T, gate: @escaping ThrowingBoolBlock) {
        self.init(operation: composed, gate: gate)
    }

    public init(dispatchQueue: DispatchQueue? = nil, operation: T, gate: @escaping ThrowingBoolBlock) {
        super.init(dispatchQueue: dispatchQueue, operation: operation)
        add(condition: IgnoredCondition(BlockCondition(block: gate)))
    }
}
