# Migrating from _Foundation.Operation_

![ProcedureKit 4.0+](https://img.shields.io/badge/ProcedureKit-4.0⁺-blue.svg)

_ProcedureKit_ makes it simple to use `Procedure`s alongside existing `Foundation.Operation` (`NSOperation`) subclasses.

Concepts from `Foundation.Operation` map closely to (differently-named) _ProcedureKit_ classes.

# Comparisons

A cheat-sheet for the _ProcedureKit_ replacements for _Foundation.Operation_ concepts:

| Foundation     | ProcedureKit   |             |
|----------------|----------------|:--------------------------:|
| Operation      | Procedure      | [Compare](#operation--procedure)  |
| OperationQueue | ProcedureQueue | [Compare](#operationqueue--procedurequeue) |
| BlockOperation | BlockProcedure | [Compare](#blockoperation--blockprocedure) |

### Operation → [Procedure](Classes/Procedure.html)

#### Core Differences:
- A `Procedure` **must** be added to a `ProcedureQueue`. It cannot be started manually.
- A `Procedure`'s code goes in its `execute()` override. (Instead of `start()` or `main()`.)
- A `Procedure` cannot override `cancel()` or several other `Operation` methods - safer alternatives (like Observers) are provided.

#### Core Additional Functionality:
- A `Procedure` supports [Observers](Classes/Observers.html) for executing code in response to `Procedure` events, which have numerous advantages over KVO on `Operation`.
- A `Procedure` supports [Conditions](Classes/Conditions.html). Before a `Procedure` is ready to execute it will asynchronously evaluate all of its conditions. If any condition fails, it finishes with an error instead of executing.
- `Procedure` has its own internal logging functionality that can be easily customized to [[support third-party logging frameworks or custom logging|Custom-Logging]] for easy debugging.
- `Procedures` can support the property of [Mutual Exclusion](Classes/MutualExclusion.html).

### OperationQueue → [ProcedureQueue](Classes/ProcedureQueue.html)

A `ProcedureQueue` can be a drop-in replacement for an `OperationQueue`, and supports the same API and functionality as `OperationQueue`.

#### Core Additional Functionality:
- Full `Procedure` support.
- Supports a `ProcedureQueueDelegate` to receive asynchronous callbacks when events (like adding a new `Operation` / `Procedure`) occur.

### BlockOperation → [BlockProcedure](Classes/BlockProcedure.html)

In essentially all cases, `BlockProcedure` can be a drop-in replacement for `BlockOperation`, but provides all the additional functionality of a `Procedure` ([see above](#operation--procedure)).

# Core Additional Features

- Dependency Injection
- GroupProcedure

## [Dependency Injection](dependency-injection.html)

Often, `Procedure`s will need dependencies in order to execute. As is typical with asynchronous / event-based applications, these dependencies might not be known at creation time. Instead they must be injected after the `Procedure` is initialised, but before it is executed.

_ProcedureKit_ supports this via a set of [protocols and types which work together](Dependency-Injection.html). We think this pattern is great, as it encourages the composition of small single purpose procedures. These are easier to test and potentially enable greater re-use. You will find dependency injection used and encouraged throughout this framework.

## [GroupProcedure](Classes/GroupProcedure.html)

A `GroupProcedure` can be used to create a logical grouping of "child" `Operations` / `Procedures` that run on its own (private) queue.

This is a very powerful class, and underpins a lot of other built-in `Procedure`s provided by the framework. It is probably the second most commonly used after `BlockProcedure`.

Instead of a maze of dependencies, allow `GroupProcedure` to help you break up `Operations` / `Procedures` into many reusable chunks that join into larger logical building blocks.
