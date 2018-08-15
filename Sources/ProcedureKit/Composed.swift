//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
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

/// Conformance for ComposedProcedure where T implements InputProcedure
extension ComposedProcedure: InputProcedure where T: InputProcedure {

    public typealias Input = T.Input

    public var input: Pending<T.Input> {
        get { return operation.input }
        set { operation.input = newValue }
    }
}

/// Conformance for ComposedProcedure where T implements OutputProcedure
extension ComposedProcedure: OutputProcedure where T: OutputProcedure {

    public typealias Output = T.Output

    public var output: Pending<ProcedureResult<T.Output>> {
        get { return operation.output }
        set { operation.output = newValue }
    }
}

/**
 A `Procedure` which composes an Operation, with a block.
 The block returns a boolean, and can be used for simple control flow.
 */
open class GatedProcedure<T: Operation>: ComposedProcedure<T> {

    /// Initialize a GatedProcedure to wrap a specified Operation subclass T
    ///
    /// - Parameters:
    ///   - composed: the composed Operation subclass T
    ///   - gate: an escaping ThrowingBoolBlock
    public convenience init(_ composed: T, gate: @escaping ThrowingBoolBlock) {
        self.init(operation: composed, gate: gate)
    }

    /// Initialize a GatedProcedure to wrap a specified Operation subclass T
    ///
    /// - Parameters:
    ///   - dispatchQueue: the underlying DispatchQueue for the internal ProcedureQueue onto which the composed operation is submitted
    ///   - composed: the composed Operation subclass T
    ///   - gate: an escaping ThrowingBoolBlock
    public init(dispatchQueue: DispatchQueue? = nil, operation: T, gate: @escaping ThrowingBoolBlock) {
        super.init(dispatchQueue: dispatchQueue, operation: operation)
        addCondition(IgnoredCondition(BlockCondition(block: gate)))
    }
}
