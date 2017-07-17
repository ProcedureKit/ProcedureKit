# Conditions

_Conditions (can) prevent procedures from starting_.

--

Conditions are types which can be attached to a procedure, and multiple conditions can be attached to the same procedure. Before the procedure executes, it asynchronously _evaluates_ all of its conditions. If any condition fails, the procedure is canceled with an error instead of executing.

This is very useful as it allows us to abstract the control logic of whether a procedure should be executed or not into a decoupled unit. This is a key idea behind _ProcedureKit_: that procedures are units of work, and conditions are the business logic which executes them or not.

Adding a condition is easy:

```swift
procedure.add(condition: BlockCondition {
    // procedure will cancel instead of executing if this is false
    return trueOrFalse
})
```

## Scheduling

Conditions are evaluated after all of the procedure's direct dependencies have finished. What does this mean? Consider the following code:

```swift
// Create some simple procedures
let global = BlockProcedure { print(" World") }
let local = BlockProcedure { print(" Dan") }

// Add a dependency
let greeting = BlockProcedure { print("Hello") }

// Add a dependency directly to the procedure
global.add(dependency: greeting)
local.add(dependency: greeting)

// Add some conditions
global.add(condition: BlockCondition { showGlobalGreeting }) // assume we have a Bool
local.add(condition: BlockCondition { !showGlobalGreeting })

queue.add(operations: global, local, greeting)
```

If we forgive the contrived nature of the example, if the variable `showGlobalGreeting` is true, we'll have this output:

> Hello World

and for a false value:

> Hello Dan

The key point is that the greeting procedure, which is added a dependency executes first, and then the condition (and all other conditions) is evaluated.

## Creating a custom Condition

While there are many built in conditions available in the framework, and `BlockCondition` offer excellent utility, creating a custom condition is pretty straightforward too.

1. Subclass `Condition`
2. Override `evaluate(procedure:completion:)`

This method receives the procedure instance which the condition has been attached to, and should called the (escaping) completion handler with the result. This means that it is possible to evaluate the condition asynchronously. The result of the evaluation is a `ConditionResult`, which is a typealias for `ProcedureResult<Bool>`.

## Indirect Dependencies

`Condition`, while not an `Operation` subclass supports the concept of producing dependencies using the API: `produce(dependency:)`. This should be called during the initializer of the condition. These dependencies can be `Operation` instances. They allow conditions to create an operation which runs _after_ the procedure's direct dependencies, but before the conditions are evaluated. We'll cover this topic more in [Advanced Conditions](Advanced-Conditions.html) and [Capabilities](Capabilities.html).
