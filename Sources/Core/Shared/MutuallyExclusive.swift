//
//  MutuallyExclusive.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A generic condition for describing operations that
cannot be allowed to execute concurrently.
*/
public final class MutuallyExclusive<T>: Condition {

    /// Public constructor
    public override init() {
        super.init()
        name = "MutuallyExclusive<\(T.self)>"
        mutuallyExclusive = true
    }

    /// Required public override, but there is no evaluation, so it just completes with `.Satisfied`.
    public override func evaluate(operation: Operation, completion: CompletionBlockType) {
        completion(.Satisfied)
    }
}
