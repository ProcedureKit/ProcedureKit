//
//  RetryOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

public class RetryOperation<T: Operation>: RepeatedOperation<T> {

    public init<G where G: GeneratorType, G.Element == NSTimeInterval>(delay: G, maxCount max: Int? = .None, _ body: () -> T?) {
        super.init(delay: delay, maxCount: max, anyGenerator {
            guard let op = body() else { return nil }
            op.addCondition(NoFailedDependenciesCondition())
            return op
        })
        name = "Retry Operation"
    }

    public convenience init(strategy: WaitStrategy = .Fixed(0.1), maxCount max: Int? = .None, _ body: () -> T?) {
        self.init(delay: strategy.generate(), maxCount: max, body)
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if !errors.isEmpty, let _ = operation as? T  {
            addNextOperation()
        }
    }
}

