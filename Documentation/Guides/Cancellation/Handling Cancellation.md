# Understanding Cancellation

- Remark: When and how do we respond to cancellation


In _ProcedureKit_, [`Procedure`](Classes/Procedure.html) follows the policy of cancellation that Apple use in Foundation for [`Operation`](https://developer.apple.com/documentation/foundation/operation). There is a [`cancel()`](Classes/Procedure.html#/s:FC12ProcedureKit9Procedure6cancelFT_T_) method which sets [`isCancelled`](Classes/Procedure.html#/s:vC12ProcedureKit9Procedure11isCancelledSb) to be `true`. That is all.

Before we get into the details of cancellation, it is helpful to clarify some assumptions about usage.

## Who calls `cancel()`?

In general, [`Procedure`](Classes/Procedure.html) instances should not call [`cancel()`](Classes/Procedure.html#/s:FC12ProcedureKit9Procedure6cancelFT_T_) on themselves. Instead, other code will cancel a procedure. Lets think of some examples:

1. The user taps "Cancel" on a button.
    In this scenario, a controller will likely respond or react to that button press, and invoke `cancel()` on the procedure doing any work, such as a network request or data processing.
    
2. An iOS application is sent to the background.
    Potentially here, the app delegate may signal to any running procedures to `cancel()`.
    
3. A [`Procedure`](Classes/Procedure.html)'s dependency finishes with errors.
    In this scenario, a procedure is waiting for the results of another procedure. However, if the dependency finishes unsuccessfully, the waiting procedure aught to be cancelled. This is likely done from within a *DidCancelObserver* which will call [`cancel(withError:)`](Classes/Procedure.html#/s:FC12ProcedureKit9Procedure6cancelFT10withErrorsGSaPs5Error___T_) on the waiting procedure. The framework does this automatically with the [`injectResult(from:)`](Protocols/InputProcedure.html) APIs.
    
In all of these example, `cancel()` is invoked on the procedure from outside. In all situations, the [`Procedure`](Classes/Procedure.html) needs to ensure that it _handles_ cancellation correctly.

## Handling Cancellation

Once a procedure is cancelled, it must move to the finished state. 

- Important:
It is the responsibility of the [`Procedure`](Classes/Procedure.html) subclass to cancel its work and move to the finished state as soon as is practical once cancelled.

We call handling cancellation and moving to the finished state quickly once cancelled being *responsive to cancellation*.

Built-in [`Procedure`](Classes/Procedure.html) subclasses in the framework are already responsive. For example:

1. [`GroupProcedure`](Classes/GroupProcedure.html) will cancel its children. It finishes after all of its children have finished. It also prevents new children from being added after cancelled.
2. [`DelayProcedure`](Classes/DelayProcedure.html) immediately finishes when cancelled.

If you want your custom [`Procedure`](Classes/Procedure.html) subclass to response to cancellation (i.e. finish early when it is cancelled) you *must* do some additional work.

### When _ProcedureKit_ handles cancellation for you

- When using built-in procedures, such as [`GroupProcedure`](Classes/GroupProcedure.html).
- By default, when a custom [`Procedure`](Classes/Procedure.html) subclass is cancelled _before it has begun executing_ (i.e. before your `execute()` method is called).

### When you need to handle Cancellation

- When you need to take any additional steps to properly cancel the underlying work of your procedure. For example, if wrapping another asynchronous task in a [`Procedure`](Classes/Procedure.html).
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

When a [`Procedure`](Classes/Procedure.html) is cancelled, the following order of events happen:

1. *[`isCancelled`](Classes/Procedure.html#/s:vC12ProcedureKit9Procedure11isCancelledSb)* is set to *`true`*

2. *[`procedureDidCancel(withErrors:)`](Classes/Procedure.html#/s:FC12ProcedureKit9Procedure18procedureDidCancelFT10withErrorsGSaPs5Error___T_)* is called (can be overridden)

3. *[`DidCancelObserver`](Structs/DidCancelObserver.html)* instances are called.

## You can handle cancellation by any combination of:

1. Checking [`isCancelled`](Classes/Procedure.html#/s:vC12ProcedureKit9Procedure11isCancelledSb) as in the example above.

2. Override [`procedureDidCancel(withErrors:)`](Classes/Procedure.html#/s:FC12ProcedureKit9Procedure18procedureDidCancelFT10withErrorsGSaPs5Error___T_).
    While the [`Procedure`](Classes/Procedure.html) implementation of this method is empty, it is best practice to call `super.procedureDidCancel(withErrors:)` at the beginning of your override.
    
3. Attach [`DidCancelObserver`](Structs/DidCancelObserver.html) instances. This is the only mechanism to observe cancellation from outside the instance. For example:
    ```swift
    let procedure = MyProcedure() // etc
    
    procedure.addDidCancelBlockObserver { (procedure, errors) in
        // inspect the errors possibly.
    }
    ````
    
Generally, the method you choose will depend on the type of [`Procedure`](Classes/Procedure.html), and what is required if a procedure is cancelled.

## Next steps

- [Synchronous Procedures](cancelling-in-synchronous-procedures.html)
- [Asynchronous Procedures](cancelling-in-asynchronous-procedures.html)
