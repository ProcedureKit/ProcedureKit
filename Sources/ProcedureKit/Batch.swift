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
            let error = ProcedureKitError.requirementNotSatisfied()
            output = .ready(.failure(error))
            cancel(withError: error)
            return
        }

        let batch = input.map { i -> Transform in
            let transform = generator()
            transform.input = .ready(i)
            return transform
        }

        let gathered = batch.gathered()
        bind(from: gathered)

        add(children: batch)
        add(child: gathered)
    }
}
