![](https://raw.githubusercontent.com/ProcedureKit/ProcedureKit/development/header.png)

[![Build status](https://badge.buildkite.com/4bc80b0824c6357ae071342271cb503b8994cf0cfa58645849.svg)](https://buildkite.com/procedurekit/procedurekit)
[![Coverage Status](https://coveralls.io/repos/github/ProcedureKit/ProcedureKit/badge.svg?branch=swift%2F2.2)](https://coveralls.io/github/ProcedureKit/ProcedureKit?branch=swift%2F2.2)
[![Documentation](http://procedure.kit.run/development/badge.svg)](http://procedure.kit.run/development)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ProcedureKit.svg?style=flat)](https://cocoapods.org/pods/ProcedureKit)
[![Platform](https://img.shields.io/cocoapods/p/ProcedureKit.svg?style=flat)](http://cocoadocs.org/docsets/ProcedureKit)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# ProcedureKit

A Swift framework inspired by WWDC 2015 Advanced NSOperations session. Previously known as _Operations_, developed by [@danthorpe](https://github.com/danthorpe) with a lot of help from our fantastic community.

Resource | Where to find it
---------|-----------------
Session video | [developer.apple.com](https://developer.apple.com/videos/wwdc/2015/?id=226)
Old but more complete reference documentation | [docs.danthorpe.me/operations](http://docs.danthorpe.me/operations/2.9.0/index.html)
Updated but not yet complete reference docs | [procedure.kit.run/development](http://procedure.kit.run/development/index.html)
Programming guide | [operations.readme.io](https://operations.readme.io)

## Compatibility

ProcedureKit supports all current Apple platforms. The minimum requirements are:

- iOS 9.0+
- macOS 10.11+
- watchOS 3.0+
- tvOS 9.2+

The current released version of ProcedureKit (5.1.0) supports Swift 4.2+ and Xcode 10.1. The `development` branch is Swift 5 and Xcode 10.2 compatible.

## Framework structure

_ProcedureKit_ is a "multi-module" framework (don't bother Googling that, I just made it up). What I mean, is that the Xcode project has multiple targets/products each of which produces a Swift module. Some of these modules are cross-platform, others are dedicated, e.g. `ProcedureKitNetwork` vs `ProcedureKitMobile`.

## Installing ProcedureKit

See the [Installing ProcedureKit](http://procedure.kit.run/development/installing-procedurekit.html) guide. 

## Usage

`Procedure` is a `Foundation.Operation` subclass. It is an abstract class which _must_ be subclassed.

```swift
import ProcedureKit

class MyFirstProcedure: Procedure {
    override func execute() {
        print("Hello World")
        finish()
    }
}

let queue = ProcedureQueue()
let myProcedure = MyFirstProcedure()
queue.add(procedure: myProcedure)
```

the key points here are:

1. Subclass `Procedure`
2. Override `execute` but do not call `super.execute()`
4. Always call `finish()` after the *work* is done, or if the procedure is cancelled. This could be done asynchronously.
5. Add procedures to instances of `ProcedureQueue`.

## Observers

Observers are attached to a `Procedure` subclass. They receive callbacks when lifecycle events occur. The lifecycle events are: *did attach*, *will execute*, *did execute*, *did cancel*, *will add new operation*, *did add new operation*, *will finish* and *did finish*.

These methods are defined by a protocol, so custom classes can be written to conform to multiple events. However, block based methods exist to add observers more naturally. For example, to observe when a procedure finishes:

```swift
myProcedure.addDidFinishBlockObserver { procedure, errors in 
    procedure.log.info(message: "Yay! Finished!")
}
```

The framework also provides `BackgroundObserver`, `TimeoutObserver` and `NetworkObserver`.

See the wiki on [[Observers|Observers]] for more information.

## Conditions

Conditions are attached to a `Procedure` subclass. Before a procedure is ready to execute it will asynchronously *evaluate* all of its conditions. If any condition fails, it finishes with an error instead of executing. For example:

```swift
myProcedure.add(condition: BlockCondition { 
    // procedure will execute if true
    // procedure will be ignored if false
    // procedure will fail if error is thrown
    return trueOrFalse // or throw AnError()
}
``` 

Conditions can be mutually exclusive. This is akin to a lock being held preventing other operations with the same exclusion being executed.

The framework provides the following conditions: `AuthorizedFor`, `BlockCondition`, `MutuallyExclusive`, `NegatedCondition`, `NoFailedDependenciesCondition`, `SilentCondition` and `UserConfirmationCondition` (in _ProcedureKitMobile_).

See the wiki on [[Conditions|Conditions]], or the old programming guide on [Conditions|](https://operations.readme.io/docs/conditions) for more information.

## Capabilities

A _capability_ represents the application’s ability to access device or user account abilities, or potentially any kind of gated resource. For example, location services, cloud kit containers, calendars etc or a webservice. The `CapabiltiyProtocol` provides a unified model to:
 
1. Check the current authorization status, using `GetAuthorizationStatusProcedure`, 
2. Explicitly request access, using `AuthorizeCapabilityProcedure`
3. Both of the above as a condition called `AuthorizedFor`. 

For example:

```swift
import ProcedureKit
import ProcedureKitLocation

class DoSomethingWithLocation: Procedure {
    override init() {
        super.init()
        name = "Location Operation"
        add(condition: AuthorizedFor(Capability.Location(.whenInUse)))
    }
   
    override func execute() {
        // do something with Location Services here
        
        
        finish()
    }
}
```

_ProcedureKit_ provides the following capabilities: `Capability.CloudKit` and `Capability.Location`.

In _Operations_, (a previous version of this framework), more functionality existed (calendar, health, photos, address book, etc), and we are still considering how to offer these in _ProcedureKit_. 

See the wiki on [[Capabilities|Capabilities]], or the old programming guide on [Capabilities](https://operations.readme.io/docs/capabilities) for more information.

## Logging

`Procedure` has its own internal logging functionality exposed via a `log` property:

```swift
class LogExample: Procedure {
   
    override func execute() {
        log.info("Hello World!")
        finish()
    }
}
```

See the programming guide for more information on [logging](https://operations.readme.io/docs/logging) and [supporting 3rd party log frameworks](https://operations.readme.io/docs/custom-logging).

## Dependency Injection

Often, procedures will need dependencies in order to execute. As is typical with asynchronous/event based applications, these dependencies might not be known at creation time. Instead they must be injected after the procedure is initialised, but before it is executed. _ProcedureKit_ supports this via a set of protocols and types which work together. We think this pattern is great, as it encourages the composition of small single purpose procedures. These can be easier to test and potentially enable greater re-use. You will find dependency injection used and encouraged throughout this framework. 

Anyway, firstly, a value may be ready or pending. For example, when a procedure is initialised, it might not have all its dependencies, so they are in a pending state. Hopefully they become ready by the time it executes.

Secondly, if a procedure is acquiring the dependency required by another procedure, it may succeed, or it may fail with an error. Therefore there is a simple _Result_ type which supports this.

Thirdly, there are protocols to define the `input` and `output` properties. 

`InputProcedure` associates an `Input` type. A `Procedure` subclass can conform to this to allow dependency injection. Note, that only one `input` property is supported, therefore, create intermediate struct types to contain multiple dependencies. Of course, the `input` property is a pending value type.

`OutputProcedure` exposes the `Output` associated type via its `output` property, which is a pending result type.

Bringing it all together is a set of APIs on `InputProcedure` which allows chaining dependencies together. Like this:

```swift
import ProcedureKitLocation

// This class is part of the framework, it 
// conforms to OutputProcedure
let getLocation = UserLocationProcedure()

// Lets assume we've written this, it
// conforms to InputProcedure
let processLocation = ProcessUserLocation()

// This line sets up dependency & injection
// it automatically handles errors and cancellation
processLocation.injectResult(from: getLocation)

// Still need to add both procedures to the queue
queue.add(procedures: getLocation, processLocation)
```

In the above, it is assumed that the `Input` type matched the `Output` type, in this case, `CLLocation`. However, it is also possible to use a closure to massage the output type to the required input type, for example:

```swift
import ProcedureKitLocation

// This class is part of the framework, it 
// conforms to OutputProcedure
let getLocation = UserLocationProcedure()

// Lets assume we've written this, it
// conforms to InputProcedure, and 
// requires a CLLocationSpeed value
let processSpeed = ProcessUserSpeed()

// This line sets up dependency & injection
// it automatically handles errors and cancellation
// and the closure extracts the speed value
processLocation.injectResult(from: getLocation) { $0.speed }

// Still need to add both procedures to the queue
queue.add(procedures: getLocation, processLocation)
```

Okay, so what just happened? Well, the `injectResult` API has a variant which accepts a trailing closure. The closure receives the output value, and must return the input value (or throw an error). So, `{ $0.speed }` will return the speed property from the user's `CLLocation` instance.

Key thing to note here is that this closure runs synchronously. So, it's best to not put anything onerous onto it. If you need to do more complex data mappings, check out [`TransformProcedure`](https://github.com/ProcedureKit/ProcedureKit/blob/development/Sources/ProcedureKit/Transform.swift#L7) and [`AsyncTransformProcedure`](https://github.com/ProcedureKit/ProcedureKit/blob/development/Sources/ProcedureKit/Transform.swift#L31). 

See the programming guide on [Injecting Results](https://operations.readme.io/docs/injecting-results) for more information.
