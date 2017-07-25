# Creating MyFirstProcedure

[`Procedure`](Classes/Procedure.html) is a [`Foundation.Operation`](https://developer.apple.com/documentation/foundation/operation) subclass. It is also an abstract class which *must* be subclassed.

Here is a simple example:

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

To use the procedure, we need to add it to a [`ProcedureQueue`](Classes/ProcedureQueue.html).

```swift
let queue = ProcedureQueue()
let myProcedure = MyFirstProcedure()
queue.add(procedure: myProcedure)
```

This is a contrived example, but the important points are:

1. Subclass [`Procedure`](Classes/Procedure.html)
2. Override `execute()`, but **do not** call `super.execute()`.
3. Always call [`finish()`](Classes\/Procedure.html#\/s:FC12ProcedureKit9Procedure6finishFT10withErrorsGSaPs5Error___T_) when the work is complete. This could be done asynchronously.
4. Add operations to instances of [`ProcedureQueue`](Classes/ProcedureQueue.html).

If the queue is not suspended, procedures will be executed as soon as they become ready and the queue has capacity.

### Finishing

- Important: Every Procedure **must** eventually call [`finish`](Classes\/Procedure.html#\/s:FC12ProcedureKit9Procedure6finishFT10withErrorsGSaPs5Error___T_).

If the procedure does not call [`finish()`](Classes\/Procedure.html#\/s:FC12ProcedureKit9Procedure6finishFT10withErrorsGSaPs5Error___T_) or [`finish(withErrors:)`](Classes\/Procedure.html#\/s:FC12ProcedureKit9Procedure6finishFT10withErrorsGSaPs5Error___T_) it will never complete. This might block a queue from executing subsequent operations. Any operations which are waiting on the stuck operation will not start.

## Best Practices

[`Procedure`](Classes/Procedure.html) is a class, so object orientated programming best practices apply. For example pass known dependencies into the initialiser:

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

[`Foundation.Operation`](https://developer.apple.com/documentation/foundation/operation) has a [`name`](https://developer.apple.com/documentation/foundation/operation/1416089-name) property. It can be handy to set this for debugging purposes.

### Cancelling

[`Procedure`](Classes/Procedure.html) will check that it has not been cancelled before it invokes `execute()`. However, depending on the *work* being done, the subclass should periodically check if it has been cancelled, and then finish accordingly. See the [Cancellation] for more guidance on how to handle cancellation.

