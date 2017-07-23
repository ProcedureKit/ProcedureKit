# Understanding Cancellation

_When and how do we respond to cancellation_

---

In _ProcedureKit_, `Procedure` follows the policy of cancellation that Apple use in Foundation for `Operation`. There is a `cancel()` method which sets `isCancelled` to be true. That is all.

Before we get into the details of cancellation, it is helpful to clarify some assumptions about usage.

## Who calls `cancel()`?

In general, `Procedure` instances should not call `cancel()` on themselves. Instead, other code will cancel a procedure. Lets think of some examples:

1. The user taps "Cancel" on a button.
    In this scenario, a controller will likely respond or react to that button press, and invoke `cancel()` on the procedure doing any work, such as a network request or data processing.
    
2. An iOS application is sent to the background.
    Potentially here, the app delegate may signal to any running procedures to `cancel()`.
    
3. A `Procedure`'s dependency finishes with errors.
    In this scenario, a procedure is waiting for the results of another procedure. However, if the dependency finishes unsuccessfully, the waiting procedure aught to be cancelled. This is likely done from within a *DidCancelObserver* which will call `cancel(withError:)` on the waiting procedure. The framework does this automatically with the `inject(result:)` APIs.
    
In all of these example, `cancel()` is invoked on the procedure from outside. In all situations, the `Procedure` needs to ensure that it _handles_ cancellation correctly.

## Handling Cancellation

Once a procedure is cancelled, it must move to the finished state. *It is the responsibility of the `Procedure` subclass to cancel its work and move to the finished state as soon as is practical once cancelled.*

We call handling cancellation and moving to the finished state quickly once cancelled being *responsive to cancellation*.

Built-in `Procedure` subclasses in the framework are already responsive. For example:

1. `GroupProcedure` will cancel its children. It finishes after all of its children have finished. It also prevents new children from being added after cancelled.
2. `DelayProcedure` immediately finishes when cancelled.

If you want your custom `Procedure` subclass to response to cancellation (i.e. finish early when it is cancelled) you *must* do some additional work.

### When _ProcedureKit_ handles cancellation for you

- When using built-in procedures, such as `GroupProcedure`.
- By default, when a custom `Procedure` subclass is cancelled _before it has begun executing_ (i.e. before your `execute()` method is called).

### When you need to handle Cancellation

- When you need to take any additional steps to properly cancel the underlying work of your procedure. For example, if wrapping another asynchronous task in a `Procedure`.
- Inside your `execute()` method. Periodically, if possible, check to see if the procedure has been cancelled. How?

    ```swift  
    override func execute() {

		// Just an example
        doStepOne()

		// You probably wouldn't ever do this really
        doStepTwo()
        
        finish()
    }
    
    private func doStepOne() {
        guard !isCancelled else { return }    
        
        // etc
    }
    
    private func doStepTwo() {
        guard !isCancelled else { return }    
        
        // etc
    }
    
    ````

## Sequence of events during Cancellation

When a `Procedure` is cancelled, the following order of events happen:

1. *`isCancelled`* is set to *`true`*

2. *`procedureDidCancel(withErrors:)`* is called (can be overridden)

3. *`DidCancelObserver`* instances are called.

## You can handle cancellation by any combination of:

1. Checking `isCancelled` as in the example above.

2. Override `procedureDidCancel(withErrors:)`.
    While the `Procedure` implementation of this method is empty, it is best practice to call `super.procedureDidCancel(withErrors:)` at the beginning of your override.
    
3. Attach `DidCancelObserver` instances. This is the only mechanism to observe cancellation from outside the instance. For example:
    ```swift
    let procedure = MyProcedure() // etc
    
    procedure.addDidCancelBlockObserver { (procedure, errors) in
        // inspect the errors possibly.
    }
    ````
    
Generally, the method you choose will depend on the type of `Procedure`, and what is required if a procedure is cancelled.

## Next steps

- [Synchronous Procedures](cancelling-in-synchronous-procedures.html)
- [Asynchronous Procedures](cancelling-in-asynchronous-procedures.html)
