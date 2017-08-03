# Migrating from _PSOperations_

![ProcedureKit 4.0+](https://img.shields.io/badge/ProcedureKit-4.0⁺-blue.svg)

Concepts from _PSOperations_ map closely to (differently-named) _ProcedureKit_ classes.

## Comparisons

A cheat-sheet for the _ProcedureKit_ replacements for _PSOperations_ classes:

| PSOperations   | ProcedureKit   |             |
|----------------|----------------|:--------------------------:|
| Operation      | Procedure      | [Compare](#-psoperationsoperation--procedure)  |
| OperationQueue | ProcedureQueue | [Compare](#-psoperationsoperationqueue--procedurequeue) |
| BlockOperation | BlockProcedure | [Compare](#-psoperationsblockoperation--blockprocedure) |
| GroupOperation | GroupProcedure | [Compare](#-psoperationsgroupoperation--groupprocedure) |
| DelayOperation | DelayProcedure | [Compare](#-psoperationsdelayoperation--delayprocedure) |
| URLSessionTaskOperation | NetworkDataProcedure / NetworkDownloadProcedure / NetworkUploadProcedure | [Compare](#-psoperationsurlsessiontaskoperation--networkprocedures) |
| MutuallyExclusive | MutuallyExclusive | [Compare](#-psoperationsmutuallyexclusive--mutuallyexclusive-condition) |


## PSOperations.Operation → [Procedure](Classes\Procedure.html)

### Usage Differences:
- A `Procedure` must be added to a `ProcedureQueue`.
- A `Procedure` cannot override `cancel()` or several other `Foundation.Operation` methods - safer alternatives (like Observers) are provided.
- `Procedure.cancel()` does not automatically call `finish()` once the `Procedure` has been started. See our guide on [[how to handle cancellation in your Procedure subclasses|Handling-Cancellation]].

#### Advantages:
- `Procedure` provides enhanced thread-safety and fixes for race conditions.
- `Procedure` fixes a bug where [Operations occasionally get stuck ready, but never execute or properly finish](https://github.com/ProcedureKit/ProcedureKit/issues/175#issuecomment-208004960) (due to overriding `isReady`).
- `Procedure` executes user code and events on a serial [[EventQueue]], helping avoid common classes of concurrency issues with subclass overrides, Observers, and more.
- `Procedure`'s internals (and methods) are asynchronous, preventing several classes of deadlock issues.
- `Procedure` does not use recursive locks.
- `Procedure` is aggressively stress-tested with [a massive Stress-Testing suite](https://github.com/ProcedureKit/ProcedureKit/tree/development/Tests/ProcedureKitStressTests).
- `Procedure` incorporates numerous performance-improvements, such as short-circuit evaluation of Conditions and minimizing lock contention and use.
- `Procedure` provides numerous helpers for adopting proper asynchronous patterns and scheduling blocks / Observers on specific queues, or before / after certain `Procedure` lifecycle events.
- `Procedure` internal checks and asserts help you catch logical mistakes in your code.
- `Procedure` provides verbose, [[customizable|Custom-Logging]] logging that makes it easier to debug complex graphs of `Procedures`.

## PSOperations.OperationQueue → [ProcedureQueue](Classes\ProcedureQueue.html)

A `ProcedureQueue` can be a nearly drop-in replacement for a `PSOperations.OperationQueue`, and supports the same API and functionality as `OperationQueue`.

### Key Exception:
- `ProcedureQueue` supports `ProcedureQueueDelegate` which has naming changes and additional functionality over `PSOperations.OperationQueueDelegate`.

## PSOperations.BlockOperation → [BlockProcedure](Classes\BlockProcedure.html)

In essentially all cases, `BlockProcedure` can be a drop-in replacement for `PSOperations.BlockOperation`, but provides all the additional functionality and advantages of a `Procedure` ([see above](#-psoperationsoperation--procedure)).

## PSOperations.GroupOperation → [GroupProcedure](Classes\GroupProcedure.html)

In essentially all cases, `GroupProcedure` can be a drop-in replacement for `PSOperations.GroupOperation`, but provides all the additional functionality and advantages of a `Procedure` ([see above](#-psoperationsoperation--procedure)).

### Additional Advantages:

- `GroupProcedure` provides enhanced thread-safety and fixes for race conditions, including:
    - `GroupOperation` has race conditions and other issues impacting cancellation, which can result in a cancelled `GroupOperation` finishing without the cancelled flag ever being set.
    - `GroupOperation` has race conditions impacting error aggregation from children, which can result in crashes or other unexpected behavior.
- `GroupProcedure` supports customization of the `underlyingQueue` used for its children, the `qualityOfService`, etc.
- `GroupProcedure` supports suspend / resume.
- `GroupProcedure` provides overrides to support customizing error handling behavior and customizing added `Operations`.
- `GroupProcedure` provides numerous helpers for adopting proper asynchronous patterns and scheduling blocks / Observers on specific queues, or before / after certain `Procedure` lifecycle events.
- `GroupProcedure` internal checks and asserts help you catch logical mistakes in your code.

## PSOperations.DelayOperation → [DelayProcedure](Classes\DelayProcedure.html)

In essentially all cases, `DelayProcedure` can be a drop-in replacement for `PSOperations.DelayOperation`, but provides all the additional functionality and advantages of a `Procedure` ([see above](#-psoperationsoperation--procedure)).

## PSOperations.URLSessionTaskOperation → Network*Procedures

_ProcedureKitNetwork_ provides three classes that split up the duties of `PSOperation`'s `URLSessionTaskOperation`:

1. `NetworkDataProcedure` is a simple procedure which will perform a data task using URLSession based APIs.
2. `NetworkDownloadProcedure` is a simple procedure which will perform a download task using URLSession based APIs.
3. `NetworkUploadProcedure` is a simple procedure which will perform an upload task using URLSession based APIs.

#### Core Differences:

- 3 classes versus 1
- `Network*Procedure` only supports the completion block style URLSession API, therefore do not use these procedures if you wish to use delegate based APIs on URLSession.

#### Advantages:

- `Network*Procedures` can utilize dependency injection to have their "input" (the request, etc) provided post-initialization.
- `Network*Procedures` do not utilize KVO on `URLSessionTask`, which [can cause crashes](https://github.com/ProcedureKit/ProcedureKit/issues/320).

## · PSOperations.MutuallyExclusive → [[MutuallyExclusive (Condition)]]

In essentially all cases, `MutuallyExclusive` can be a drop-in replacement for `PSOperations.MutuallyExclusive`.

#### Additional Advantages:

- Mutual Exclusivity is now evaluated post-dependencies and condition evaluation (i.e. immediately before execute).
    - This resolves **several deadlock and unexpected dependency scenarios**, while still ensuring that only one `Procedure` with each mutual exclusivity category is running simultaneously.
    - It also **improves performance** by only acquiring locks in a single request, and only when the `Procedure` is otherwise ready to execute.

# Additional Features

**ProcedureKit** also provides a number of new features, when migrating from `PSOperations`:

- Dependency Injection
- RepeatProcedure
- RetryProcedure

## · [[Dependency Injection]]

Often, `Procedures` will need dependencies in order to execute. As is typical with asynchronous / event-based applications, these dependencies might not be known at creation time. Instead they must be injected after the `Procedure` is initialised, but before it is executed.

**ProcedureKit** supports this via a set of [[protocols and types which work together|Dependency-Injection]]. We think this pattern is great, as it encourages the composition of small single purpose procedures. These can be easier to test and potentially enable greater re-use. You will find dependency injection used and encouraged throughout this framework.

# Additional Built-in Procedures

- CloudKitProcedure
- AlertProcedure `(iOS)`
- UIProcedure `(iOS)`
- ProcessProcedure `(macOS)`
- Location Procedures