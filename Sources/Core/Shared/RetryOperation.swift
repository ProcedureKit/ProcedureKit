//
//  RetryOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

public class RetryOperation<T: Operation>: RepeatedOperation<T> {

    public typealias ShouldRetryBlock = (T, errors: [ErrorType], aggreateErrors: [ErrorType], count: Int) -> Bool

    let shouldRetryOperation: ShouldRetryBlock

    public init<G where G: GeneratorType, G.Element == NSTimeInterval>(delay: G, maxCount max: Int?, shouldRetry: ShouldRetryBlock, _ body: () -> T) {
        self.shouldRetryOperation = shouldRetry
        super.init(delay: delay, maxCount: max, anyGenerator {
            let op = body()
            op.addCondition(NoFailedDependenciesCondition())
            return op
        })
        name = "Retry Operation"
    }

    public convenience init(strategy: WaitStrategy = .Fixed(0.1), maxCount max: Int? = 5, shouldRetry: ShouldRetryBlock = {_, _, _, _ in true }, _ body: () -> T) {
        self.init(delay: strategy.generate(), maxCount: max, shouldRetry: shouldRetry, body)
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if !errors.isEmpty, let op = operation as? T {
            addNextOperation(shouldRetryOperation(op, errors: errors, aggreateErrors: aggregateErrors, count: count))
        }
    }
}

