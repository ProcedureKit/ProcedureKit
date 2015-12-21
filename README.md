![](https://raw.githubusercontent.com/danthorpe/Operations/development/header.png)

[![Build status](https://badge.buildkite.com/4bc80b0824c6357ae071342271cb503b8994cf0cfa58645849.svg?branch=master)](https://buildkite.com/blindingskies/operations)
[![codecov.io](http://codecov.io/github/danthorpe/Operations/coverage.svg?branch=development)](http://codecov.io/github/danthorpe/Operations?branch=development)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/Operations.svg)](https://img.shields.io/cocoapods/v/Operations.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/Operations.svg?style=flat)](http://cocoadocs.org/docsets/Operations)

# Operations

A Swift framework inspired by WWDC 2015 Advanced NSOperations session. See the session video [here](https://developer.apple.com/videos/wwdc/2015/?id=226). There is a programming guide available here: [operations.readme.io](https://operations.readme.io). Reference documentation is available here: [docs.danthorpe.me/operations](http://docs.danthorpe.me/operations/2.4.1/index.html).

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
```

the key point here are:

1. Subclass `Operation`
2. Override `execute` but do not call `super.execute()`
3. Check the `cancelled` property before starting any *work*.
4. If not cancelled, always call `finish()` after the *work* is done. This could be done asynchronously.

## Observers
Observers are attached to an `Operation`. They receive callbacks when operation events occur. Unlike the Apple sample code, Operations defines four observer protocols for the four events, *did start*, *did cancel*, *did produce operation* and *did finish*. There are block based types which implement these protocols. For example, to observe when an operation starts:

```swift
operation.addObserver(StartedObserver { op in 
    print("Lets go!")
})
```

The framework provides `BackgroundObserver`, `TimeoutObserver` and `NetworkObserver`.

See the programming guide on [Observers](https://operations.readme.io/docs/observers) for more information.

## Conditions
Conditions are attached to an `Operation`. Before an operation is ready to execute it will asynchronously *evaluate* all of its conditions. If a conditions fails, the operation finishes with an error instead of executing. For example:

```swift
operation.addCondition(BlockCondition { 
    // operation will only be executed if this is true
    return trueOrFalse
}
``` 

Conditions can be mutually exclusive which is akin to a lock being held preventing other operations with the same exclusion being executed.

The framework provides `AuthorizedFor`, `BlockCondition`, `MutuallyExclusive`, `NegatedCondition`, `NoFailedDependenciesCondition`, `SilentCondition`, `ReachilityCondition`, `RemoteNotificationCondition`, `UserConfirmationCondition` and `UserNotificationCondition`.

See the programming guide on [Conditions](https://operations.readme.io/docs/conditions) for more information.

## Capabilities
`CapabilityType` is a protocol which represents the applications authorization to access device or user account abilities. For example, location services, cloud kit contains, calendars etc. The protocol provides a unified model for checking the current authorization status, using `GetAuthorizationStatus`, explicitly requesting access, using `Authorize`, and as a condition with `AuthorizedFor`. For example:

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
The framework provides capabilities: `Capability.Calendar`, `Capability.CloudKit`, `Capability.Health`, `Capability.Location`, `Capability.Passbook` and `Capability.Photos`.

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

See the programming guide for more information: [logging](https://operations.readme.io/docs/logging) and [supporting 3rd party log frameworks](https://operations.readme.io/docs/custom-logging).

## Injecting Results
State can be seamlessly transitioned between operations automatically. An operation which produces a *result* must conform to `ResultOperationType` and expose state via its `result` property. An operation which consumes state, has a *requirement* which must be set via its `requirement` property. Given conformance to these protocols, operations can be chained together:

```swift
let retrieval = DataRetrieval()
let processing = DataProcessing()
processing.injectResultFromDependency(retrieval)
queue.addOperations(retrieval, processing)
```

See the programming guide on [Injecting Results](https://operations.readme.io/docs/injecting-results) for more information.


## Status - 21st Dec, 2015

As of version 2.3, Operations is a multi-platform framework, with CocoaPods support in addition to framework targets for iOS Extensions, iOS Apps, OS X, watchOS and tvOS.

## Installation

See the programming guide for detailed [installation instructions](https://operations.readme.io/docs/installing).

### CocoaPods

Operations is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Operations'
```

### Carthage

Recently it was discovered that it is not currently possible to install the API Extension compatible framework via Carthage. This boiled down to having two schemes for the same platform, and Carthage doesn’t provide a way to pick. Now, there are two separate projects, one for API extension compatible frameworks only, which doesn’t actually solve the problem. But, there is a [pull request](https://github.com/Carthage/Carthage/pull/892) which should allow all projects to be build. For now, the only semi-automatic way to integrate these flavors is to use Cocoapods: `pod 'Operations/Extension'`. 


## Motivation

I want to stress that this code is heavily influenced by Apple. In no way am I attempting to assume any sort of credit for this architecture - that goes to [Dave DeLong](https://twitter.com/davedelong) and his team. My motivations are that I want to adopt this code in my own projects, and so require a solid well tested framework which I can integrate with.

