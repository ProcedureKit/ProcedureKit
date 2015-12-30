//
//  RetryOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 29/12/2015.
//
//

import Foundation

public class RetryOperation<O: NSOperation>: RepeatedOperation<AnyGenerator<O>> {

    public init(min: NSTimeInterval = 1, max: MaximumTimeInterval = .Backoff, limit: Int? = .None, operation op: O) {
        if let op = op as? Operation {
            op.addCondition(NoFailedDependenciesCondition())
        }
        super.init(min: min, max: max, limit: limit, generator: anyGenerator { return op })
        name = "Retry Operation"
    }
}

