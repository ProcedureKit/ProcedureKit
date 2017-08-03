//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

import Foundation
import Dispatch

/**
 A `Procedure` which can be used to compose an Operation.
 It is designed to be subclassed or used directly.

 This can be useful for wrapping an (unmodifiable / system framework) Operation subclass inside
 a `Procedure`, gaining the advantages of a `Procedure` (such as Observers).

 - note: If you can modify the Operation subclass yourself, you may be better off migrating it
 to a `Procedure` subclass. In cases where you cannot modify the Operation subclass, such as when
 it's part of another framework for which you do not have the source code, ComposedProcedure can
 be used.

 - note: CloudKitProcedure internally uses a ComposedProcedure subclass (`CKProcedure`) to wrap
 CKOperation subclasses.
 */
open class ComposedProcedure<T: Operation>: GroupProcedure {

    /// The composed operation (T)
    public private(set) var operation: T

    /// Initialize a ComposedProcedure to wrap a specified T (Operation subclass)
    ///
    /// - Parameter composed: the composed operation (T)
    public convenience init(_ composed: T) {
        self.init(operation: composed)
    }

    /// Initialize a ComposedProcedure to wrap a specified T (Operation subclass),
    /// optionally specifying an underlying DispatchQueue.
    ///
    /// - Parameters:
    ///   - dispatchQueue: the underlying DispatchQueue for the internal ProcedureQueue onto which the composed operation is submitted
    ///   - operation: the composed operation (T)
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
