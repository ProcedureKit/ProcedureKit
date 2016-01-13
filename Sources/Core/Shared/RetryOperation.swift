//
//  RetryOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

public struct RetryFailureInfo<T: NSOperation> {
    public let operation: T
    public let errors: [ErrorType]
    public let aggregateErrors: [ErrorType]
    public let count: Int
    public let addOperations: (NSOperation...) -> Void
}

public class RetryGenerator<T: NSOperation>: GeneratorType {
    public typealias Retry = (RetryFailureInfo<T>, Delay?, T) -> (Delay?, T)?

    internal let shouldRetry: Retry
    internal var info: RetryFailureInfo<T>? = .None
    private var generator: AnyGenerator<(Delay?, T)>

    init(generator: AnyGenerator<(Delay?, T)>, shouldRetry: Retry) {
        self.generator = generator
        self.shouldRetry = shouldRetry
    }

    public func next() -> (Delay?, T)? {
        guard let (delay, next) = generator.next() else { return nil }
        guard let info = info else { return (delay, next) }
        return shouldRetry(info, delay, next)
    }
}

public class RetryOperation<T: NSOperation>: RepeatedOperation<T> {
    public typealias FailureInfo = RetryFailureInfo<T>
    public typealias Handler = RetryGenerator<T>.Retry

    let retry: RetryGenerator<T>

    public init(maxCount max: Int?, retry block: Handler, generator: AnyGenerator<(Delay?, T)>) {
        retry = RetryGenerator(generator: generator, shouldRetry: block)
        super.init(maxCount: max, generator: anyGenerator(retry))
        name = "Retry Operation"
    }

    public convenience init<D, G where D: GeneratorType, D.Element == Delay, G: GeneratorType, G.Element == T>(maxCount max: Int?, delay: D, retry: Handler, generator: G) {
        let tuple = TupleGenerator(primary: generator, secondary: delay)
        self.init(maxCount: max, retry: retry, generator: anyGenerator(tuple))
    }

    public convenience init<G where G: GeneratorType, G.Element == T>(maxCount max: Int?, strategy: WaitStrategy, retry: Handler, generator: G) {
        self.init(maxCount: max, delay: GeneratorMap(strategy.generator()) { Delay.By($0) }, retry: retry, generator: generator)
    }

    public convenience init(maxCount max: Int? = 5, strategy: WaitStrategy = .Fixed(0.1), retry: Handler = { (_, delay: Delay?, op: T) in (delay, op) }, _ body: () -> T?) {
        self.init(maxCount: max, strategy: strategy, retry: retry, generator: anyGenerator { body() })
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if !errors.isEmpty, let op = operation as? T {
            retry.info = createFailureInfo(op, errors: errors)
            addNextOperation()
        }
    }

    internal func createFailureInfo(operation: T, errors: [ErrorType]) -> RetryFailureInfo<T> {
        return RetryFailureInfo(
            operation: operation,
            errors: errors,
            aggregateErrors: aggregateErrors,
            count: count,
            addOperations: addOperations
        )
    }
}

