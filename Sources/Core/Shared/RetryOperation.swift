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

internal class RetryGenerator<T: NSOperation>: GeneratorType {

    var info: RetryFailureInfo<T>? = .None

    let shouldRetry: RetryFailureInfo<T> -> Bool
    private var generator: AnyGenerator<T>

    init(generator: AnyGenerator<T>, shouldRetry: RetryFailureInfo<T> -> Bool) {
        self.generator = generator
        self.shouldRetry = shouldRetry
    }

    func next() -> T? {
        guard let info = info else {
            return generator.next()
        }
        guard shouldRetry(info) else {
            return nil
        }

        return generator.next()
    }
}

public class RetryOperation<T: NSOperation>: RepeatedOperation<T> {
    public typealias FailureInfo = RetryFailureInfo<T>

    let retry: RetryGenerator<T>

    public init<D, G where D: GeneratorType, D.Element == NSTimeInterval, G: GeneratorType, G.Element == T>(delay: D, maxCount max: Int?, shouldRetry: RetryFailureInfo<T> -> Bool, generator: G) {
        retry = RetryGenerator(generator: anyGenerator(generator), shouldRetry: shouldRetry)
        super.init(delay: delay, maxCount: max, generator: retry)
        name = "Retry Operation <\(operation.dynamicType)>"
    }

    public convenience init<G where G: GeneratorType, G.Element == NSTimeInterval>(delay: G, maxCount max: Int?, shouldRetry: RetryFailureInfo<T> -> Bool, _ body: () -> T?) {
        self.init(delay: delay, maxCount: max, shouldRetry: shouldRetry, generator: anyGenerator {
            guard let op = body() else { return nil }
            if let op = op as? Operation {
                op.addCondition(NoFailedDependenciesCondition())
            }
            return op
        })
    }

    public convenience init(strategy: WaitStrategy = .Fixed(0.1), maxCount max: Int? = 5, shouldRetry: RetryFailureInfo<T> -> Bool = { _ in true }, _ body: () -> T) {
        self.init(delay: strategy.generate(), maxCount: max, shouldRetry: shouldRetry, body)
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

