# Dependencies

`Foundation.Operation` supports the concept of operations which depend on other operations finishing first. Additionally, an operation can have multiple dependencies across different queues.

```swift
let greet = Greeter(name: "Daniel")
let welcome = ShowWelcome()
greet.addDependency(welcome)
queue.add(operations: greet, welcome)
```

### Set dependencies before adding operations to queues

A great aspect of this features is that the dependency can be setup between operations in different queues. However, we recommend that if possible all operations involved in a dependency graph are added to the same queue at the same time, and that dependencies are set before operations are added to any queues.

## Handling Failure

`Procedure` has the concept of finishing (or cancelling) with errors, whereas `Foundation.Operation` does not, they just complete. If a procedure finishes with an error, and it is the dependency of another operation, *that operation will still execute despite this failure*. This is pretty subtle behavior, and it may change in future versions. However, there are helper methods to catch cancellations, errors and ensure dependencies succeeded which we'll get into later. But consider that before your `Procedure` subclass executes its work it is a best practice to validate assumptions using `assert` or `precondition`.