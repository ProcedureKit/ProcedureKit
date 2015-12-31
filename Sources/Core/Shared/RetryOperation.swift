//
//  RetryOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

public class RetryOperation<T: Operation>: RepeatedOperation<T> {

    public init(strategy: WaitStrategy = .Fixed(0.1), maxCount max: Int? = .None, _ body: () -> T?) {
        super.init(strategy: strategy, maxCount: max, anyGenerator {
            guard let op = body() else { return nil }
            op.addCondition(NoFailedDependenciesCondition())
            return op
        })
        name = "Retry Operation"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if !errors.isEmpty, let _ = operation as? T  {
            addNextOperation()
        }
    }
}

