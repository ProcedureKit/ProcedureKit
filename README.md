![](https://raw.githubusercontent.com/ProcedureKit/ProcedureKit/development/header.png)

[![Build status](https://badge.buildkite.com/4bc80b0824c6357ae071342271cb503b8994cf0cfa58645849.svg?branch=master)](https://buildkite.com/blindingskies/operations)
[![Coverage Status](https://coveralls.io/repos/github/ProcedureKit/ProcedureKit/badge.svg?branch=swift%2F2.2)](https://coveralls.io/github/ProcedureKit/ProcedureKit?branch=swift%2F2.2)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Operations.svg?style=flat)](https://cocoapods.org/pods/Operations)
[![CocoaPods Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/Operations.svg?style=flat)](https://cocoapods.org/pods/Operations)
[![Platform](https://img.shields.io/cocoapods/p/Operations.svg?style=flat)](http://cocoadocs.org/docsets/Operations)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)


# ProcedureKit

A Swift framework inspired by WWDC 2015 Advanced NSOperations session. Previously known as _Operations_, developed by [@danthorpe](https://github.com/danthorpe).

Resource | Where to find it
---------|-----------------
Session video | [developer.apple.com](https://developer.apple.com/videos/wwdc/2015/?id=226)
Reference documentation | [docs.danthorpe.me/operations](http://docs.danthorpe.me/operations/2.9.0/index.html)
Programming guide | [operations.readme.io](https://operations.readme.io)
Example projects | [danthorpe/Examples](https://github.com/danthorpe/Examples)

## Transition to ProcedureKit
_Operations_ has hit a turning point as part of its transition to Swift 3.0, due to the name change of `NSOperation` to `Operation`, which now conflicts with its base abstract class. I am taking this opportunity to rename the entire project and move it to an organization repository.

During this transition period, code, documentation and examples will still refer to `Operation` and `NSOperation` until the grand renaming occurs.

See #398 for the high level v4.0 roadmap which lists these forthcoming changes.

## Usage

The [programming guide](https://operations.readme.io/docs) goes into a lot more detail about using this framework. But here are some of the key details.

`Operation` is an `NSOperation` subclass. It is an abstract class which should be subclassed.

```swift
import Operations

class MyFirstOperation: Operation {
    override func execute() {
        guard !cancelled else { return }
        print("Hello World")
        finish()
    }
}

let queue = OperationQueue()
let myOperation = MyFirstOperation()
queue.addOperation(myOperation)
```

the key points here are:

1. Subclass `Operation`
2. Override `execute` but do not call `super.execute()`
3. Check the `cancelled` property before starting any *work*.
4. If not cancelled, always call `finish()` after the *work* is done. This could be done asynchronously.
5. Add operations to instances of `OperationQueue`.

## Observers

Observers are attached to an `Operation`. They receive callbacks when operation events occur. In a change from Apple's sample code, Operations defines four observer protocols for the four events: *did start*, *did cancel*, *did produce operation* and *did finish*. There are block based types which implement these protocols. For example, to observe when an operation starts:

```swift
operation.addObserver(StartedObserver { op in 
    print("Lets go!")
})
```

The framework also provides `BackgroundObserver`, `TimeoutObserver` and `NetworkObserver`.

See the programming guide on [Observers](https://operations.readme.io/docs/observers) for more information.

## Conditions

Conditions are attached to an `Operation`. Before an operation is ready to execute it will asynchronously *evaluate* all of its conditions. If any condition fails, the operation finishes with an error instead of executing. For example:

```swift
operation.addCondition(BlockCondition { 
    // operation will finish with an error if this is false
    return trueOrFalse
}
``` 

Conditions can be mutually exclusive. This is akin to a lock being held preventing other operations with the same exclusion being executed.

The framework provides the following conditions: `AuthorizedFor`, `BlockCondition`, `MutuallyExclusive`, `NegatedCondition`, `NoFailedDependenciesCondition`, `SilentCondition`, `ReachabilityCondition`, `RemoteNotificationCondition`, `UserConfirmationCondition` and `UserNotificationCondition`.

See the programming guide on [Conditions](https://operations.readme.io/docs/conditions) for more information.

## Capabilities

`CapabilityType` is a protocol which represents the application’s authorization to access device or user account abilities. For example, location services, cloud kit containers, calendars etc. The protocol provides a unified model to:
 
1. Check the current authorization status, using `GetAuthorizationStatus`, 
2. Explicitly request access, using `Authorize`
3. Both of the above as a condition called `AuthorizedFor`. 

For example:

```swift
class ReminderOperation: Operation {
    override init() {
        super.init()
        name = "Reminder Operation"
        addCondition(AuthorizedFor(Capability.Calendar(.Reminder)))
    }
   
    override func execute() {
        // do something with EventKit here
        finish()
    }
}
```
The framework provides the following capabilities: `Capability.Calendar`, `Capability.CloudKit`, `Capability.Health`, `Capability.Location`, `Capability.Passbook` and `Capability.Photos`.

See the programming guide on [Capabilities](https://operations.readme.io/docs/capabilities) for more information.

## Logging

`Operation` has its own internal logging functionality exposed via a `log` property:

```swift
class LogExample: Operation {
   
    override func execute() {
        log.info("Hello World!")
        finish()
    }
}
```

See the programming guide for more information on [logging](https://operations.readme.io/docs/logging) and [supporting 3rd party log frameworks](https://operations.readme.io/docs/custom-logging).

## Injecting Results

State (or data if you prefer) can be seamlessly transitioned between operations automatically. An operation which produces a *result* can conform to `ResultOperationType` and expose state via its `result` property. An operation which consumes state, can conform to `AutomaticInjectionOperationType` and set its *requirement* via its `requirement` property. Given conformance to these protocols, operations can be chained together:

```swift
let getLocation = UserLocationOperation()
let processLocation = ProcessUserLocation()
processLocation.injectResultFromDependency(getLocation)
queue.addOperations(getLocation, processLocation)
```

See the programming guide on [Injecting Results](https://operations.readme.io/docs/injecting-results) for more information.

## Installation

See the programming guide for detailed [installation instructions](https://operations.readme.io/docs/installing).

### CocoaPods

Operations is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Operations'
```

### Carthage

Add the following line to your Cartfile:

```ruby
github 'danthorpe/Operations'
```

It was recently discovered that it is not currently possible to install the API extension compatible framework via Carthage. This boiled down to having two schemes for the same platform, and Carthage doesn’t provide a way to pick. As of now, there are two separate projects. One for standard application version, and one for API extension compatible frameworks only. This doesn’t actually solve the problem, but there is a [pull request](https://github.com/Carthage/Carthage/pull/892) which should allow all projects in a repo to be built. For now, the only semi-automatic way to integrate these flavors is to use Cocoapods: `pod 'Operations/Extension'`. 


### Other *Advanced NSOperations*
Other developers have created projects based off Apple’a WWDC sample code. Check them out too.

1. [PSOperations](https://github.com/pluralsight/PSOperations)

