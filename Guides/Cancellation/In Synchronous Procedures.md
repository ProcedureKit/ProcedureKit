# Handling Cancellation in Synchronous Procedures

---

A _synchronous_ `Procedure` performs all its work as part of its `execute()` method, and calls `finish()` before returning.

> 💡 Synchronous procedures are great candidates for the use of occasional `!isCancelled` checks.

For example, consider the following example `BadFibonacci`, which shows an *anti-pattern* which generates a sequence and feeds them to a block:

```swift
// NOTE: Do not use this code. It is not responsive to cancellation.

class BadFibonacci: Procedure {

    let count: Int
    let block: (Int) -> Void
    
    init(count: Int = 10, block: @escaping (Int) -> Void) {
        self.count = count
        self.block = block
        super.init()
        name = "Bad Fibonacci"
    }
    
    override func execute() {
        guard count > 0 else { finish(); return }
        block(0)
        var result = 0
        var prevResult = 1
        for _ in 1..<count {
            let nextResult = prevResult + result
            prevResult = result
            result = nextResult
            block(nextResult)
        }
        finish()
    }
}
``` 

An instance of `BadFibonacci` can be cancelled, but it does not *_respond_* to cancellation. It will have no impact if cancelled while running. To make it respond, we need to modify the loop to periodically check `isCancelled`.

```swift
class BetterFibonacci: Procedure {

    let count: Int
    let block: (Int) -> Void
    
    init(count: Int = 10, block: @escaping (Int) -> Void) {
        self.count = count
        self.block = block
        super.init()
        name = "Bad Fibonacci"
    }

    override func execute() {
        guard count > 0 else { finish(); return }
        block(0)
        var result = 0
        var prevResult = 1
        for i in 1..<count {
            if i % 2 == 0 { // no need to check `isCancelled` every time in this loop
                guard !isCancelled else {
                    // handle cancellation by finishing and returning immediately
                    finish()
                    return
                }
            }
            let nextResult = prevResult + result
            prevResult = result
            result = nextResult
            block(nextResult)
        }
        finish()
    }
}
```

The `BetterFibonacci` class checks whether it has been cancelled every 2 values in the sequence. If it has, then it finishes and returns immediately.

> 💡 Note:
> You may want to consider how frequently `isCancelled` is checked, and potentially use a throttle as shown above. Consider that each check to `isCancelled` requires a lock which can impact performance.
> For tight loops, say 1000 iterations in 50ms, do not check `isCancelled` more frequently than every 1000 or even 10,000 iterations. Try to determine how quickly you want the procedure to respond to cancellation, to calibrate how frequently you check for cancellation.

