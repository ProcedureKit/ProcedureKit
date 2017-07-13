# Creating MyFirstProcedure

`Procedure` is a `Foundation.Operation` subclass. It is also an abstract class which *must* be subclassed.

Here is a simple example. 

```swift
import ProcedureKit

class MyFirstProcedure: Procedure {
    override func execute() {
        print("Hello World")
        finish()
    }
}
```

## Executing

To use the procedure, we need to add it to a `ProcedureQueue`.

```swift
let queue = ProcedureQueue()
let myProcedure = MyFirstProcedure()
queue.add(procedure: myProcedure)
```

This is a contrived example, but the important points are:

1. Subclass `Procedure`
2. Override `execute()`, but *do not* call `super.execute()`.
3. Always call `finish()` when the work is complete. This could be done asynchronously.
4. Add operations to instances of `ProcedureQueue`.

If the queue is not suspended, procedures will be executed as soon as they become ready and the queue has capacity.

### Finishing

If the procedure does not call `finish()` or `finishWithError()` it will never complete. This might block a queue from executing subsequent operations. Any operations which are waiting on the stuck operation will not start.

## Best Practices

`Procedure` is a class, so object orientated programming best practices apply. For example pass known dependencies into the initialiser:

```swift
class Greeter: Procedure {

    let personName: String
    
    init(name: String) {
        self.personName = name
        super.init()
        name = "Greeter Operation"
    }
    
    override func execute() {
        print("Hello \(personName)")
        finish()
    }
}
```

### Set the name

`Foundation.Operation` has a `name` property. It can be handy to set this for debugging purposes.

### Cancelling

`Procedure` will check that it has not been cancelled before it invokes `execute`. However, depending on the *work* being done, the subclass should periodically check if it has been cancelled, and then finish accordingly. See the [Cancallation] for more guidance on how to handle cancellation.

