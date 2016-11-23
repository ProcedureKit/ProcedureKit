//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

open class TransformProcedure<Input, Output>: Procedure, InputProcedure, OutputProcedure {

    public typealias Transform = (Input) throws -> Output

    private let transform: Transform

    public var input: Pending<Input> = .pending
    public var output: Pending<Result<Output>> = .pending

    public init(transform: @escaping Transform) {
        self.transform = transform
        super.init()
    }

    open override func execute() {
        defer { finish(withError: output.error) }
        do {
            guard let inputValue = input.value else { throw ProcedureKitError.requirementNotSatisfied() }
            output = .ready(.success(try transform(inputValue)))
        }
        catch { output = .ready(.failure(error)) }
    }
}
