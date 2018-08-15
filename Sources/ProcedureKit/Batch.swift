//
//  ProcedureKit
//
//  Copyright © 2018 ProcedureKit. All rights reserved.
//

import Foundation

open class BatchProcedure<Transform: Procedure>: GroupProcedure, InputProcedure, OutputProcedure where Transform: InputProcedure, Transform: OutputProcedure {

    public typealias Generator = () -> Transform

    /// - returns: The pending input property
    public var input: Pending<[Transform.Input]> = .pending

    /// - returns: The pending output result property
    public var output: Pending<ProcedureResult<[Transform.Output]>> = .pending

    public let generator: Generator

    public init(dispatchQueue: DispatchQueue? = nil, via generator: @escaping Generator) {
        self.generator = generator
        super.init(dispatchQueue: dispatchQueue, operations: [])
        name = "Batch<\(Transform.self)>"
    }

    open override func execute() {

        defer { super.execute() }

        guard let input = input.value else {
            cancel(with: ProcedureKitError.requirementNotSatisfied())
            return
        }

        let batch = input.map { i -> Transform in
            let transform = generator()
            transform.input = .ready(i)
            transform.didSetInputReady()
            return transform
        }

        let gathered = batch.gathered()
        bind(from: gathered)

        addChildren(batch)
        addChild(gathered)
    }
}
