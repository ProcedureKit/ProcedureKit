# Conditions

- Remark: Conditions (can) prevent procedures from starting


Conditions are types which can be attached to a [Procedure](Classes\/Procedure.html), and multiple conditions can be attached to the same Procedure. Before the Procedure executes, it asynchronously _evaluates_ all of its conditions. If any condition fails, the procedure is canceled with an error instead of executing.

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

_ProcedureKit_ has several built-in Conditions, like `BlockCondition` and [`MutuallyExclusive<T>`](Classes\/MutuallyExclusive.html). It is also easy to implement your own.

## Implementing a custom Condition

First, subclass [`Condition`](Classes\/Condition.html). Then, override `evaluate(procedure:completion:)`. Here is a simple example of [`FalseCondition`](Classes\/FalseCondition.html) which is part of the framework:

```swift
class FalseCondition: Condition {
     override func evaluate(procedure: Procedure, completion: @escaping (ConditionResult) -> Void) {
        completion(.failure(ProcedureKitError.FalseCondition()))
     }
}
```

This method receives the procedure instance which the condition has been attached to, and should called the (escaping) completion handler with the result. This means that it is possible to evaluate the condition asynchronously. The result of the evaluation is a [`ConditionResult`](Other%20Typealiases.html#\/s:12ProcedureKit15ConditionResult), which is a typealias for `ProcedureResult<Bool>`.

### Calling the completion block

- Important:
Your `evaluate(procedure:completion:)` override **must** eventually call the completion block with a [`ConditionResult`](Other%20Typealiases.html#\/s:12ProcedureKit15ConditionResult). (Although it may, of course, be called asynchronously.)

[`ConditionResult`](Other%20Typealiases.html#\/s:12ProcedureKit15ConditionResult) encompasses 3 states:
1. `.success(true)`, the "successful" result
2. `.failure(let error: Error)`, the "failure" result
3. `.success(false)`, an "ignored" result


Generally:
 - If a Condition *succeeds*, return `.success(true)`.
 - If a Condition *fails*, return `.failure(error)` with a unique error defined for your Condition.

 In some situations, it can be beneficial for a Procedure to not collect an
 error if an attached condition fails. You can use [`IgnoredCondition`](Classes\/IgnoredCondition.html) to
 suppress the error associated with any Condition. This is generally
 preferred (greater utility, flexibility) to returning `.success(false)` directly.

## Indirect Dependencies

[`Condition`](Classes\/Condition.html), while not an `Operation` or `Procedure` subclass, supports the concept of producing dependencies using the API: `produce(dependency:)`. This should be called during the initializer of the condition. These dependencies can be `Operation` instances. They allow conditions to create an operation which runs _after_ the procedure's direct dependencies, but before the conditions are evaluated. We'll cover this topic more in [Advanced Conditions](Advanced-Conditions.html) and [Capabilities](Capabilities.html).
