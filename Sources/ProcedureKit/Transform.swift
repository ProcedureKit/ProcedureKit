//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
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
        defer { finish(withError: output.error) }
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

public extension Procedure {

    public struct Chain<Output> {
        public let procedures: [Procedure]
        public let tail: AnyOutputProcedure<Output>

        internal func add<NewOutput>(newTail: AnyOutputProcedure<NewOutput>) -> Chain<NewOutput> {
            var newProcedures = procedures
            newProcedures.append(newTail)
            return Procedure.Chain<NewOutput>(procedures: newProcedures, tail: newTail)
        }
    }
}

public extension Procedure.Chain {

    func transform<TransformedOutput>(block: @escaping (Output) throws -> TransformedOutput) -> Procedure.Chain<TransformedOutput> {
        let transform = TransformProcedure(transform: block)
        transform.injectResult(from: tail)
        return add(newTail: AnyOutputProcedure(transform))
    }
}

public extension Procedure.Chain where Output: Sequence {

    func reduce<U>(_ initial: U, nextPartialResult: @escaping (U, Output.Iterator.Element) throws -> U) -> Procedure.Chain<U> {
        return add(newTail: AnyOutputProcedure(tail.reduce(initial, nextPartialResult: nextPartialResult)))
    }

    func map<U>(transform: @escaping (Output.Iterator.Element) throws -> U) -> Procedure.Chain<[U]> {
        return add(newTail: AnyOutputProcedure(tail.map(transform: transform)))
    }

}

public extension ProcedureQueue {

    func add<Output>(chain: Procedure.Chain<Output>) {
        add(operations: chain.procedures)
    }
}

public extension OutputProcedure where Self: Procedure {

    func transform<TransformedOutput>(block: @escaping (Output) throws -> TransformedOutput) -> Procedure.Chain<TransformedOutput> {
        let tail = AnyOutputProcedure(self)
        return Procedure.Chain(procedures: [tail], tail: tail).transform(block: block)
    }
}
