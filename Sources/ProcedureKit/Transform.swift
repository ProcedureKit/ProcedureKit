//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

open class TransformProcedure<Input, Output>: Procedure, InputProcedure, OutputProcedure {

    public typealias Transform = (Input) throws -> Output

    private let transform: Transform

    public var input: Pending<Input> = .pending
    public var output: Pending<ProcedureResult<Output>> = .pending

    public init(transform: @escaping Transform) {
        self.transform = transform
        super.init()
    }

    open override func execute() {
        defer { finish(with: output.error) }
        do {
            guard let inputValue = input.value else { throw ProcedureKitError.requirementNotSatisfied() }
            output = .ready(.success(try transform(inputValue)))
        }
        catch { output = .ready(.failure(error)) }
    }
}

open class AsyncTransformProcedure<Input, Output>: Procedure, InputProcedure, OutputProcedure {

    public typealias FinishingBlock = (ProcedureResult<Output>) -> Void
    public typealias Transform = (Input, @escaping FinishingBlock) -> Void

    private let transform: Transform

    public var input: Pending<Input> = .pending
    public var output: Pending<ProcedureResult<Output>> = .pending

    public init(transform: @escaping Transform) {
        self.transform = transform
        super.init()
    }

    open override func execute() {
        guard let inputValue = input.value else {
            finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
            return
        }
        transform(inputValue) { self.finish(withResult: $0) }
    }
}
