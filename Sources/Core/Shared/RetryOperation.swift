//
//  RetryOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

public class RetryOperation<T: NSOperation>: RepeatedOperation<T> {

    public init(strategy: WaitStrategy, maxNumberOfAttempts attempts: Int? = .None, _ op: T) {
        if let op = op as? Operation {
            op.addCondition(NoFailedDependenciesCondition())
        }
        super.init(strategy: strategy, maxNumberOfAttempts: attempts, anyGenerator { return op })
        name = "Retry Operation"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if !errors.isEmpty, let _ = operation as? T  {
            addNextOperation()
        }
    }
}

