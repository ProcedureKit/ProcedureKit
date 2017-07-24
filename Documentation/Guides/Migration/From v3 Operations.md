# Migrating from Operations, a.k.a. ProcedureKit v3

![ProcedureKit 4.0+](https://img.shields.io/badge/ProcedureKit-4.0⁺-blue.svg)

> ## 🚧 Work-In-Progress 🚧
> This document is incomplete.

The journey from _Operations v3_ to _ProcedureKit v4_ included some ground-breaking re-thinks of how things work internally.

Migrating your code from _Operations v3_ to _ProcedureKit v4_ will net you:
- Numerous bug fixes, thread-safety improvements, and fixes for rare bugs, edge cases, and race conditions.
- A rock-solid, asynchronous core, with a massively expanded library of tests to back it up.
- New methods to minimise the code you have to write.
- New asserts and logging to help catch programmer error and debug issues with your code.
- Swift 3 support and naming.

However, because of some of these improvements, and the concurrent transition to Swift 3, some class and method names have changed.

(With Swift 3.x, Foundation's "NSOperation" became "Operation", so renaming this framework's "Operation" class - and the framework itself - became a part of the major new release.)

## Comparisons

A cheat-sheet for the `ProcedureKit` replacements for `Operations 3.x` classes:

| Operations 3.x | ProcedureKit 4.x  |             |
|----------------|----------------|:--------------------------:|
| Operation      | Procedure      | [Compare](#-operation--procedure)  |
| OperationQueue | ProcedureQueue | [Compare](#-operationqueue--procedurequeue) |
| BlockOperation | BlockProcedure | [Compare](#-blockoperation--blockprocedure) |
| GroupOperation | GroupProcedure | [Compare](#-groupoperation--groupprocedure) |
| DelayOperation | DelayProcedure | [Compare](#-delayoperation--delayprocedure) |
| URLSessionTaskOperation | NetworkDataProcedure / NetworkDownloadProcedure / NetworkUploadProcedure | [Compare](#-urlsessiontaskoperation--networkprocedures) |
| MutuallyExclusive | MutuallyExclusive | [Compare](#-mutuallyexclusive--mutuallyexclusive-condition) |
| RepeatOperation | RepeatProcedure |
| RetryOperation | RetryProcedure |
| CloudKitOperation | CloudKitProcedure |


### Operation → [Procedure](Classes\Procedure.html)

#### Usage Differences:
- A `Procedure` must be added to a `ProcedureQueue`.
- A `Procedure` cannot override `cancel()` or several other `Foundation.Operation` methods - safer alternatives (like Observers) are provided.
- `Procedure.cancel()` does not automatically call `finish()` once the `Procedure` has been started. See our guide on [[how to handle cancellation in your Procedure subclasses|Handling-Cancellation]].

#### Improvements:
- `Procedure` provides enhanced thread-safety and fixes for race conditions.
- `Procedure` executes user code and events on a serial [EventQueue](Classes\EventQueue.html), helping avoid common classes of concurrency issues with subclass overrides, Observers, and more.
- `Procedure`'s internals (and methods) are asynchronous, preventing several classes of deadlock issues.
- `Procedure` does not use recursive locks.
- `Procedure` incorporates numerous performance-improvements, such as short-circuit evaluation of Conditions and minimizing lock contention and use.
- `Procedure` provides numerous helpers for adopting proper asynchronous patterns and scheduling blocks / Observers on specific queues, or before / after certain `Procedure` lifecycle events.
- Additional internal checks and asserts help you catch logical mistakes in your code.
- Additional verbose, [[customizable|Custom-Logging]] logging that makes it easier to debug complex graphs of `Procedures`.

### OperationQueue → [ProcedureQueue](Classes\ProcedureQueue.html)

A `ProcedureQueue` can be a nearly drop-in replacement for an Operations' `OperationQueue`, and supports the same API and functionality as `OperationQueue`.

#### Key Exception:
- `ProcedureQueue` supports `ProcedureQueueDelegate` which has naming changes and additional functionality over `OperationQueueDelegate`. If you are using a delegate, review `ProcedureQueueDelegate` for the new interface.

### BlockOperation → [BlockProcedure](Classes\BlockProcedure.html)

Operations 3.x had `BlockOperation`.

ProcedureKit 4.x has `BlockProcedure` and `AsyncBlockProcedure`, and the interface is slightly different.

#### Operations 3.x - Example 1

If you previously initialized a `BlockOperation` with a block that takes a continuation as input, like this:
```swift
// NOTE: The following does not do any asynchronous calls within the block.
let operation = BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
    doSomeWork()
    continuation(error: nil)
}
```

#### ProcedureKit 4.x - Example 1

You can replace your use of `BlockOperation` with **`BlockProcedure`** as follows:
```swift
let procedure = BlockProcedure {
    doSomeWork()
    // optionally throw the error, if one occurs
}
```

#### Operations 3.x - Example 2

However, if you had an asynchronous call and require the completion handler, like so:
```swift
let operation = BlockOperation { (continuation: BlockOperation.ContinuationBlockType) in
    dispatch_async(Queue.Default.queue) {
        doSomeWork()
        continuation(error: nil)
    }
}
```

#### ProcedureKit 4.x - Example 2

Replace your use of `BlockOperation` with **`AsyncBlockProcedure`**:
```swift
let procedure = AsyncBlockProcedure { finishWithResult in
    DispatchQueue.global().async {
        doSomeWork()
        // if an error occurs, call `finishWithResult(.failure(error))`
        // else, call `finishWithResult(success)`
        finishWithResult(success)
    }
}
```

### GroupOperation → [GroupProcedure](Classes\GroupProcedure.html)

In essentially all cases, `GroupProcedure` can be a drop-in replacement for `GroupOperation`.

### DelayOperation → [DelayProcedure](Classes\DelayProcedure.html)

In essentially all cases, `DelayProcedure` can be a drop-in replacement for `DelayOperation`.

### URLSessionTaskOperation → Network*Procedures

_ProcedureKitNetwork_ provides three classes that split up the duties of `URLSessionTaskOperation`:

1. `NetworkDataProcedure` is a simple procedure which will perform a data task using URLSession based APIs.
2. `NetworkDownloadProcedure` is a simple procedure which will perform a download task using URLSession based APIs.
3. `NetworkUploadProcedure` is a simple procedure which will perform an upload task using URLSession based APIs.

#### Core Differences:

- 3 classes versus 1
- `Network*Procedure` only supports the completion block style URLSession API, therefore do not use these procedures if you wish to use delegate based APIs on URLSession.
- `Network*Procedure` is now initialized with the session, completion handler, and (optionally) the request (and data, in the case of upload) - *not* the URLSessionTask. The `Network*Procedure` is responsible for internally creating the URLSessionTask based on the input parameters.

#### Advantages:

- `Network*Procedures` can utilize dependency injection to have their "input" (the request, etc) provided post-initialization.
- `Network*Procedures` do not utilize KVO on `URLSessionTask`, which [can cause crashes](https://github.com/ProcedureKit/ProcedureKit/issues/320).

### MutuallyExclusive → [MutuallyExclusive (Condition)](Classes\MutuallyExclusive.html)

In essentially all cases, `MutuallyExclusive` can be a drop-in replacement for Operations' `MutuallyExclusive`.

#### Additional Advantages:

- Mutual Exclusivity is now evaluated post-dependencies and condition evaluation (i.e. immediately before execute).
    - This resolves **several deadlock and unexpected dependency scenarios**, while still ensuring that only one `Procedure` with each mutual exclusivity category is running simultaneously.
    - It also **improves performance** by only acquiring locks in a single request, and only when the `Procedure` is otherwise ready to execute.
