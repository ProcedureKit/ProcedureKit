# Result Injection

- Remark: Transforming state through procedures

Up until now procedures have been discussed as isolated units of work, albeit with scheduling thanks to dependencies. In practice, this is rather limiting. If a procedure has a dependency, then it's likely the result of the dependency is needed for the waiting procedure.

In software engineering this is known as [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection), but we wish to avoid this term to avoid confusion the operational dependencies.

## Synchronous & literal requirements

If the requirement for a procedure is available synchronously, or perhaps as a literal value, then it can be inject into the procedure's initialiser. This is following best practices for object orientated programming.

## Asynchronous input

When the requirements needed for a procedure are not available when the instance is created, it must be injected sometime later - but _before the procedure executes_.

Consider a `DataProcessing` procedure class. Its job is to process `Data`, which we refer to as its _input_. However, lets assume that the data in question must be retrieved from storage, or the network. For this, there is a `DataFetch` procedure. In this context, the `Data` is its _output_.

Lets look at some code:

```swift
class DataFetch: Procedure, OutputProcedure {

    private(set) var output: Pending<ProcedureResult<Data>> = .pending
    
    override func execute() {
        fetchDataAsynchronouslyFromTheNetwork { data in 
            output = .ready(.success(data))
            finish()
        }
    }
}
```

Above is a `DataFetch` example. It conforms to the `OutputProcedure` protocol, which requires the `output` property. This is a generic property with no contraint on `Output`, its associatedtype. 

## Asynchronous output

For a data processing class example:

```swift
class DataProcessing: Procedure, InputProcedure, OutputProcedure {

    var input: Pending<Data> = .pending
    var ouptut: Pending<ProcedureResult<Data>> = .pending
    
    override func execute() {
        guard let data = input.value else { return }
        process(data: data) { processed in 
            output = .ready(.success(processed))
            finish()
        }
    }
}
```

The above shows a `DataProcessing` class. Here it conforms to `InputProcedure` which defines its `input` property, which is also a generic property with no constraints. In this case, it also conforms to `OutputProcedure`.

## Transforming state through procedures

Putting these ideas together allows us to chain procedures together, essentially mutating state through the procedures. Something like this:

```swift
let fetch = DataFetch()
let processing = DataProcessing()
processing.injectResult(from: fetch)
``` 

Firstly, the `injectResult(from:)` API is defined in a public extension on `InputProcedure`. But, what does it do?

1. The data fetch procedure is automatically added as a dependency of the processing procedure.
2. A _will finish_ block observer is added to the dependency to take its output, and set it as the processing procedure's input. This happens before the data fetch procedure finishes, and therefore before the processing procedure becomes ready.

- Note:
There is a constraint on `injectResult(from:)` where the dependency, which conforms to `OutputProcedure`, has an `Output` type which is equal to the `InputProcedure`'s `Input` type. Essentially, input has to equal output.

## What about errors?

If the dependency (the `DataFetch` procedure in this example) is cancelled with an error, the _dependent_ procedure (`DataProcessing` in this example) is automatically cancelled with a `ProcedureKitError`.

If the dependency finishes with errors, likewise, the dependent is cancelled with an appropriate error.

If the dependency finishes without a `.ready` output value, the dependent is cancelled with an appropriate error.

if the dependency finishes with an error, the dependency is cancelled with an appropriate error.

