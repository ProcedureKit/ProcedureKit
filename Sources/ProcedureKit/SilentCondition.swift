//
//  ProcedureKit
//
//  Copyright © 2015-2018 ProcedureKit. All rights reserved.
//

/**
 A simple condition which suppresses its contained condition to not
 enqueue any dependencies. This is useful for verifying access to
 a resource without prompting for permission, for example.
 */
public final class SilentCondition<C: Condition>: ComposedCondition<C> {

    /// Public override of initializer.
    public override init(_ condition: C) {
        condition.producedDependencies.forEach(condition.removeDependency)
        super.init(condition)
        name = condition.name.map { "Silent<\($0)>" }
    }
}
