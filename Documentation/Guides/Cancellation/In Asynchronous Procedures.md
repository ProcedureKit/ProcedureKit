# Handling Cancellation in Asynchronous Procedures


An *Asynchronous* [`Procedure`](Classes/Procedure.html) may return from its `execute()` method without _finishing_, and then call `finish()` some time later. Typically this happens in a completion block of another asynchronous API.

For example, consider this simplified version of [`DelayProcedure`](Classes/DelayProcedure.html) from the framework:

```swift
// NOTE: Do not use this code. It is not responsive to cancellation. It is
// intended as an example of what not-to-do. Use DelayProcedure if you need
// a delay.

class BadOneMinuteDelay: Procedure {

    var timer: DispatchSourceTimer? = nil
    
    over func execute() {
        timer = DispatchSource.makeTimerSource(flags: [], queue: .default)
        timer?.setEventHandler { [weak self] in 
            guard let strongSelf = self else { return }
            strongSelf.finish()
        }
        timer?.scheduleOneshot(deadline: now() + .seconds(60))
        timer?.resume()
    }
}
```

A `BadOneMinuteDelay` instance will wait for 60 seconds and then finishes, by calling `finish()` from inside the event handler block of a dispatch source timer.

- Note:
The event handle code above shows the best-practice of capturing self as a `weak` reference. It is not necessarily guaranteed that the `Procedure` will not have been deallocated when the closure is invoked, so it is recommended to use `weak` instead of `unowned` in this situation.

The `BadOneMinuteDelay` can be cancelled, but it does not *_respond_* to cancellation. If it is cancelled after it has begun executing, it will only finish when the timer fires.

To respond to cancellation, we need to do two things:

1. Intercept the *DidCancel* event.
2. Cancel the timer and finish the procedure.

To intercept the *DidCancel* event in an asynchronous procedure we can either override the  *`procedureDidCancel(withErrors:)`* method, or add an observer which is shown below.

```swift
// NOTE: This is a limited example of handling cancellation.
// Use `DelayProcedure` if you need a delay.
class BetterOneMinuteDelay: Procedure {

    var timer: DispatchSourceTimer? = nil
    
    override init() {
        super.init()
        addDidCancelBlockObserver { procedure, _ in
            procedure.timer?.cancel()
            // since cancelling the timer prevents it from calling its event handler
            // this will prevent the Procedure from finishing
            // thus, we must call finish() after we've cancelled the timer
            // to ensure that the Procedure always finishes
            procedure.finish()
        }
    }

    over func execute() {
        timer = DispatchSource.makeTimerSource(flags: [], queue: .default)
        timer?.setEventHandler { [weak self] in 
            guard let strongSelf = self else { return }
            strongSelf.finish()
        }
        timer?.scheduleOneshot(deadline: now() + .seconds(60))
        timer?.resume()
    }
}
```

The `BetterOneMinuteDelay` class adds a block based observer for *DidCancel* event to be invoked when it is cancelled. In the block, it:

1. Cancels the procedure's own timer.
2. Explicitly calls `finish()` (since we've cancelled the timer)

Note also that the observer block is provided with an instance of the procedure - we don't need to capture `self` here.

### Add an observer vs override `procedureDidCancel(withErrors:)`?

The main differences between these two options are..

1. A `Procedure` can have multiple did cancel observers.
2. Observers are added to specific instances (vs behaviour for an entire class)
3. A slight difference in the order they are called. The `procedureDidCancel(withErrors:)` method is always invoked before all of the observers.
4. Observers cannot be removed / overridden / usurped by a subclass.

It is that last point, which is primarily why observers are used throughout this framework, and for open classes, we recommend choosing to use an observer. However, for final classes, it is more efficient to implement an override of `procedureDidCancel(withErrors:)`.
