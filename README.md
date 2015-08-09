# Operations

A Swift framework inspired by WWDC 2015 Advanced NSOperations session. See the session video here: https://developer.apple.com/videos/wwdc/2015/?id=226

## Motivation

I want to stress that this code is heavily influenced by Apple. In no way am I attempting to assume any sort of credit for this architecture - that goes to [Dave DeLong](https://twitter.com/davedelong) and his team. My motivations are that I want to adopt this code in my own projects, and so require a solid well tested framework which I can integrate with.

Rather than just copy Apple’s sample code, I have been re-writing it from scratch, but heavily guided. The main changes I have made, other than some minor bug fixes, have been architectural to enhance the testability of the code. Unfortunately, this makes the public API a little messy for Swift 1.2, but thanks to `@testable` will not be visible in Swift 2.

## Current Status

This is a brief summary of the current and planned functionality.

### Foundation

- [x] `Operation` and `OperationQueue` class definitions.
- [x] `OperationCondition` and evaluator functionality.
- [x] `OperationObserver` definition and integration.

### Building Blocks

- [x] `MutuallyExclusive` condition e.g. can only one `AlertPresentation` at once.
- [x] `NegatedCondition` evaluates the reverse of the composed condition.
- [x] `SilentCondition` suppress any dependencies of the composed condition.
- [x] `NoCancelledDependencies` requires that all dependencies succeeded.
- [x] `BlockObserver` run blocks when the attached operation starts, produces another operation or finishes.
- [x] `BackgroundObserver` automatically start and stop background tasks if the application enters the background while the attached operation is running.
- [x] `NetworkObserver` automatically manage the device’s network indicator while the operation is running.
- [x] `TimeoutObserver` automatically cancel the attached operation if the timeout interval is reached.
- [x] `LoggingObserver` enable simple logging of the lifecycle of the operation and any of it’s produced operations.
- [x] `GroupOperation` encapsulate multiple operations into their own discrete unit, running on their own queue. Supports internally adding new operations, so can be used for batch processing or greedy operation tasks.
- [x] `DelayOperation` inserts a delay into the operation queue.
- [x] `BlockOperation` run a block inside an `Operation`. Supports unsuccessful finishing.
- [x] `GatedOperation` only run the composed operation if the provided block evaluates true.

### Features

- [x] `ReachabilityCondition` requires that the supplied URL is reachable.
- [x] `ReachableOperation` compose an operation which must complete and requires network reachability. This uses an included system  Reachability object and does not require any extra dependencies. However currently in Swift 1.2, as function pointers are not supported, this uses a polling mechanism with `dispatch_source_timer`. I will probably replace this with more efficient Objective-C soon.
- [x] `AddressBookCondition` require authorized access to ABAddressBook. Will automatically request access if status is not already determined.
- [x] `AddressBookOperation` perform task in closure which receives `ABAddressBookRef` instance. Will automatically add `AddressBookCondition`.
- [x] `CloudCondition` require varying levels of access to a `CKContainer`.
- [x] `CloudKitOperation` compose a `CKDatabaseOperation` inside an `Operation` with the appropriate `CKDatabase`.
- [x] `LocationCondition` requires permission to access the user’s location with support for specifying always or when in use permissions.
- [x] `LocationOperation` access the user’s current location with desired accuracy. 
- [x] User Notifications
- [x] Remote Notifications
- [ ] HealthKit
- [ ] Photos & Camera
- [x] Events & Reminders
- [x] Passbook
- [ ] Contacts - some initial work is done on the `swift_2.0` branch. However, currently this branch is behind `development` by quite a margin.
- [ ] Webpage - some initial work is done on a feature branch, again, Swift 2.0 only.
- [x] User Confirmation Alert - condition an operation with a user confirmation, so that the operation will only be executed if the user confirms it. Great for “delete” operation for example.


The framework is well tested, with approximately 70% coverage. This is known as I wrote it much of the foundation bits using Xcode 7 but have back ported it to Swift 1.2.

Development of a usable Swift 1.2 version is the priority. However, development of the Swift 2.0 version will shortly begin in parallel, and increase in priority. Therefore the versioning of this project will follow this pattern: Swift 1.2: `0.4 -> 1.x` and Swift 2.0: `2.0 -> 2.x`. 
