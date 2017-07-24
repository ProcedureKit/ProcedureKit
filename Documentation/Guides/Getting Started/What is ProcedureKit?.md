# What is ProcedureKit?

*ProcedureKit* is a framework which provides advanced features to [`Foundation.Operation`](https://developer.apple.com/reference/foundation/operation) and [`Foundation.OperationQueue`](https://developer.apple.com/reference/foundation/operationqueue). 

[`Procedure`](Classes/Procedure.html) is a subclass of `Foundation.Operation` and is used to perform *work* on an instance of `ProcedureQueue` which is a subclass of `Foundation.OperationQueue`. `Procedure` itself however is an abstract class and should always be subclassed to specialize the *work*.

What do we mean by *work*? This is anything (programmatic), for example number crunching, data processing, parsing or retrieval, view controller presentation, seriously - anything.

## What does the ProcedureKit framework provide?

The framework provides the core elements of `Procedure` and `ProcedureQueue` types. It also has abstract types for core functionality like the `Condition` class and `Observer` protocol.  

Additionally, there are helper types, which are "building blocks" which when used together with `Procedure ` subclasses allow for advanced usage. On top of this there are a number of feature procedures. These are `Procedure ` subclasses which can be used directly to perform common yet specialist functionality, like `UserLocationProcedure`.