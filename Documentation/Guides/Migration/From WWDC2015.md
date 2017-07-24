# Migrating from _Advanced Operations_, WWDC 2015

![ProcedureKit 4.0+](https://img.shields.io/badge/ProcedureKit-4.0⁺-blue.svg)

Concepts from the WWDC 2015 "Advanced NSOperations" sample framework map closely to (differently-named) _ProcedureKit_ classes. This guide will walk you through the differences, and reasons to make the move. Trust us.

## Why switch to _ProcedureKit_

Migrating to _ProcedureKit_ will provide immediate improvements over the "Advanced NSOperations" code, including:

- Fixes for various thread-safety issues and race conditions in the "Advanced NSOperations" code.
- Fixes for [operations occasionally get stuck ready, but never execute or properly finish](https://github.com/ProcedureKit/ProcedureKit/issues/175#issuecomment-208004960) (most commonly seen when using Conditions with the "Advanced NSOperations" code).
- Swift 3+ compatibility.
- Asserts to catch programmer errors.
- Logging to help debug `Procedure` execution.
- Support for more platforms: macOS, iOS, tvOS, watchOS.

In addition, _ProcedureKit_ is aggressively unit-tested, integration tested and actively developed and improved.

## Comparisons

A cheat-sheet for the `ProcedureKit` replacements for "Advanced NSOperations" classes:

| Advanced NSOperations   | ProcedureKit   |             |
|----------------|----------------|:--------------------------:|
| Operation      | Procedure      | [Compare](#-advanced-nsoperationsoperation--procedure)  |
| OperationQueue | ProcedureQueue | [Compare](#-advanced-nsoperationsoperationqueue--procedurequeue) |
| BlockOperation | BlockProcedure | [Compare](#-advanced-nsoperationsblockoperation--blockprocedure) |
| GroupOperation | GroupProcedure | [Compare](#-advanced-nsoperationsgroupoperation--groupprocedure) |
| DelayOperation | DelayProcedure | [Compare](#-advanced-nsoperationsdelayoperation--delayprocedure) |
| URLSessionTaskOperation | NetworkDataProcedure / NetworkDownloadProcedure / NetworkUploadProcedure | [Compare](#-advanced-nsoperationsurlsessiontaskoperation--networkprocedures) |
| MutuallyExclusive | MutuallyExclusive | [Compare](#-advanced-nsoperationsmutuallyexclusive--mutuallyexclusive-condition) |


### "Advanced NSOperations".Operation → [Procedure](Classes/Procedure.html)

#### Usage Differences:
- A `Procedure` must be added to a `ProcedureQueue`.
- A `Procedure` cannot override `cancel()` or several other `Foundation.Operation` methods - safer alternatives (like Observers) are provided.
- `Procedure.cancel()` will (by default) automatically `finish()` a Procedure (bypassing `execute()`) if it is called before the `Procedure` is started. See our guide on [how to handle cancellation in your Procedure subclasses](Handling-Cancellation.html).

#### Advantages:
- `Procedure` provides enhanced thread-safety and fixes for race conditions.
- `Procedure` fixes a bug where [Operations occasionally get stuck ready, but never execute or properly finish](https://github.com/ProcedureKit/ProcedureKit/issues/175#issuecomment-208004960) (due to overriding `isReady`).
- `Procedure` executes user code and events on a serial [EventQueue](Classes/EventQueue.html), helping avoid common classes of concurrency issues with subclass overrides, Observers, and more.
- `Procedure`'s internals (and methods) are asynchronous, preventing several classes of deadlock issues.
- `Procedure` Observers support many more events.
- `Procedure` is aggressively unit-tested with [an extensive unit test suite](https://github.com/ProcedureKit/ProcedureKit/tree/development/Tests) across all supported platforms.
- `Procedure` is aggressively stress-tested with [an extensive stress test suite](https://github.com/ProcedureKit/ProcedureKit/tree/development/Tests/ProcedureKitStressTests).
- `Procedure` incorporates numerous performance-improvements, such as short-circuit evaluation of Conditions and minimizing lock contention and use.
- `Procedure` provides numerous helpers for adopting proper asynchronous patterns and scheduling blocks / Observers on specific queues, or before / after certain `Procedure` lifecycle events.
- `Procedure` internal checks and asserts help you catch logical mistakes in your code.
- `Procedure` provides verbose, [customizable](Custom-Logging.html) logging that makes it easier to debug complex graphs of `Procedure`.

### "Advanced NSOperations".OperationQueue → [ProcedureQueue](Classes/ProcedureQueue.html)

A `ProcedureQueue` can be a nearly drop-in replacement for Advanced NSOperations' `OperationQueue`, and supports the same API and functionality as `OperationQueue`.

#### Key Exception:
- `ProcedureQueue` supports `ProcedureQueueDelegate` which has naming changes and additional functionality over `OperationQueueDelegate`.

## "Advanced NSOperations".BlockOperation → [BlockProcedure](Classes/BlockProcedure.html)

In essentially all cases, `BlockProcedure` can be a drop-in replacement for Advanced NSOperations' `BlockOperation`, but provides all the additional functionality and advantages of a `Procedure` ([see above](#-advanced-nsoperationsoperation--procedure)).

#### Key Difference:
- `BlockProcedure` does not provide the `convenience init(mainQueueBlock: dispatch_block_t)`.

### "Advanced NSOperations".GroupOperation → [GroupProcedure](Classes/GroupProcedure.html)

In essentially all cases, `GroupProcedure` can be a drop-in replacement for Advanced NSOperations' `GroupOperation`, but provides all the additional functionality and advantages of a `Procedure` ([see above](#-advanced-nsoperationsoperation--procedure)).

#### Additional Advantages:

- `GroupProcedure` provides enhanced thread-safety and fixes for race conditions / concurrency issues, including:
    - `GroupOperation` has race conditions and other issues impacting cancellation, which can result in a cancelled `GroupOperation` finishing without the cancelled flag ever being set.
    - `GroupOperation` has race conditions impacting error aggregation from children, which can result in crashes or other unexpected behavior.
- `GroupProcedure` supports customization of the `underlyingQueue` used for its children, the `qualityOfService`, etc.
- `GroupProcedure` supports suspend / resume.
- `GroupProcedure` provides overrides to support customizing error handling behavior and customizing added `Operations`.
- `GroupProcedure` provides numerous helpers for adopting proper asynchronous patterns and scheduling blocks / Observers on specific queues, or before / after certain `Procedure` lifecycle events.
- `GroupProcedure` internal checks and asserts help you catch logical mistakes in your code.

### "Advanced NSOperations".DelayOperation → [DelayProcedure](Classes/DelayProcedure.html)

In essentially all cases, `DelayProcedure` can be a drop-in replacement for Advanced NSOperations' `DelayOperation`, but provides all the additional functionality and advantages of a `Procedure` ([see above](#-advanced-nsoperationsoperation--procedure)).

### "Advanced NSOperations".URLSessionTaskOperation → Network*Procedures

_ProcedureKitNetwork_ provides three classes that split up the duties of Advanced NSOperations' `URLSessionTaskOperation`:

1. `NetworkDataProcedure` is a simple procedure which will perform a data task using URLSession based APIs.
2. `NetworkDownloadProcedure` is a simple procedure which will perform a download task using URLSession based APIs.
3. `NetworkUploadProcedure` is a simple procedure which will perform an upload task using URLSession based APIs.

#### Core Differences:

- 3 classes versus 1
- `Network*Procedure` only supports the completion block style URLSession API, therefore do not use these procedures if you wish to use delegate based APIs on URLSession.

#### Advantages:

- `Network*Procedures` can utilize dependency injection to have their "input" (the request, etc) provided post-initialization.
- `Network*Procedures` do not utilize KVO on `URLSessionTask`, which [can cause crashes](https://github.com/ProcedureKit/ProcedureKit/issues/320).

### "Advanced NSOperations".MutuallyExclusive → [MutuallyExclusive (Condition)](Classes/MutualExclusive.html)

In essentially all cases, `MutuallyExclusive` can be a drop-in replacement for Advanced NSOperations' `MutuallyExclusive`.

#### Additional Advantages:

- Mutual Exclusivity is now evaluated post-dependencies and condition evaluation (i.e. immediately before execute).
    - This resolves **several deadlock and unexpected dependency scenarios**, while still ensuring that only one `Procedure` with each mutual exclusivity category is running simultaneously.
    - It also **improves performance** by only acquiring locks in a single request, and only when the `Procedure` is otherwise ready to execute.

# Additional Features

_ProcedureKit_ also provides a number of new features, when migrating from "Advanced NSOperations":

- Dependency Injection

### [Dependency Injection](dependency-injection.html)

Often, `Procedures` will need dependencies in order to execute. As is typical with asynchronous / event-based applications, these dependencies might not be known at creation time. Instead they must be injected after the `Procedure` is initialised, but before it is executed.

_ProcedureKit_ supports this via a set of [protocols and types which work together](dependency-injection.html). We think this pattern is great, as it encourages the composition of small single purpose procedures. These can be easier to test and potentially enable greater re-use. You will find dependency injection used and encouraged throughout this framework.

# Additional Built-in Procedures

- CloudKitProcedure
- AlertProcedure `(iOS)`
- UIProcedure `(iOS)`
- ProcessProcedure `(macOS)`
- Location Procedures




