//
//  SlientCondition.swift
//  Operations
//
//  Created by Daniel Thorpe on 19/07/2015.
//  Copyright © 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

/**
A simple condition which suppresses its contained condition to not
enqueue any dependencies. This is useful for verifying access to
a resource without prompting for permission, for example
*/
public final class SilentCondition<C: Condition>: ComposedCondition<C> {

    /// Public override of initializer.
    public override init(_ condition: C) {
        condition.removeDependencies()
        super.init(condition)
        name = condition.name.map { "Silent<\($0)>" }
    }
}
