# 2.5.0

This is a relatively large number of changes with some breaking changes from 2.4.*.

### Breaking changes

1. [[OPR-140](https://github.com/danthorpe/Operations/pull/140)]: `OperationObserver` has been refactored to refine four different protocols each with a single function, instead of defining four functions itself. 

    The four protocols are for observing the following events: *did start*, *did cancel*, *did produce operation* and *did finish*. There are now specialized block observers, one for each event.

    This change is to reflect that observers are generally focused on a single event, which is more in keeping with a single responsibility principle. I feel this is better than a single type which typically has either three no-op functions or consists entirely of optional closures.

    To observe multiple events using blocks: add multiple observers. Alternatively, create a bespoke type to observe multiple events with the same type.

    `BlockObserver` itself still exists, however its usage is discouraged and it will be removed at a later time. It may also be necessary to make syntactic changes to existing code, in which case, I recommend replacing its usage entirely with one or more of `StartedObserver`, `CancelledObserver`, `ProducedOperationObserver` or `FinishedObserver`, all of which accept a non-optional block.

2. [[OPR-139](https://github.com/danthorpe/Operations/pull/139)]: Removed `Capabiltiy.Health`. Because this capability imports HealthKit, it is flagged by the app review team, and an application may be rejecting for not providing guidance on its usage of HealthKit. Therefore, as the majority of apps probably do not use this capability, I have removed it from the standard application framework. It is available as a subspec through Cocoapods:

    ```ruby
    pod 'Operations/+Health'
    ```

### Improvements

1. [[OPR-121](https://github.com/danthorpe/Operations/issues/121),[OPR-122](https://github.com/danthorpe/Operations/pull/122), [OPR-126](https://github.com/danthorpe/Operations/pull/126), [OPR-138](https://github.com/danthorpe/Operations/pull/138)]: Improves the built in logger. So that now:

    1. the message is enclosed in an  `@autoclosure`. 
    2. there is a default/global severity threshold
    3. there is a global enabled setting.

    Thanks to Jon ([@jshier](https://github.com/jshier)) for raising the initial issue on this one.

2. [[OPR-128](https://github.com/danthorpe/Operations/pull/128)]: Improves how code coverage is generated.

    Thanks to Steve ([@stevepeak](https://github.com/stevepeak)) from [Codecov.io](https://codecov.io) for helping with this.

3. [[OPR-133](https://github.com/danthorpe/Operations/issues/133), [OPR-134](https://github.com/danthorpe/Operations/pull/134)]: `DelayOperation` and `BlockOperation` have improved response to being cancelled.

    Thanks to Jon ([@jshier](https://github.com/jshier)) for raising the initial issue on this one.

4. [[OPR-132](https://github.com/danthorpe/Operations/pull/132)]: `BlockObserver` now supports a cancellation handler. However see the notes regarding changes to `OperationObserver` and `BlockObserver` above under breaking changes.

5. [[OPR-135](https://github.com/danthorpe/Operations/issues/135),[OPR-137](https://github.com/danthorpe/Operations/pull/137)]: Result Injection.

    It is now possible to inject the results from one operation into another operation as its requirements before it executes. This can be performed with a provided block, or automatically in the one-to-one, result-to-requirement case. See the [programming guide](https://operations.readme.io/docs/injecting-results) for more information.

    Thanks very much to Frank ([@difujia](https://github.com/difujia)) for the inspiration on this, and Jon ([@jshier](https://github.com/jshier)) for contributing to the discussion.

6. [[OPR-141](https://github.com/danthorpe/Operations/pull/141)]: `Operation` now uses `precondition` to check the expectations of public APIs. These are called out in the function’s documentation. Thanks to the Swift evolution mailing list & Chris Lattner on this one.

7. [[OPR-144](https://github.com/danthorpe/Operations/issues/144), [OPR-145](https://github.com/danthorpe/Operations/pull/145)]: Supports adapting the internal logger to use 3rd party logging frameworks. The example project uses [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver) as a logger. 

    Thanks to Steven ([@shsteven](https://github.com/shsteven)) for raising the issue on this one!

8. [[OPR-148](https://github.com/danthorpe/Operations/pull/148)]: Location operations now conform to `ResultOperationType` which means their result (`CLLocation`, `CLPlacemark`) can be injected automatically into appropriate consuming operations.

### Bug Fixes

1. [[OPR-124](https://github.com/danthorpe/Operations/pull/124)]: Fixes a bug where notification names conflicted. 

    Thanks to Frank ([@difujia](https://github.com/difujia)) for this one.

2. [[OPR-123](https://github.com/danthorpe/Operations/issues/123),[OPR-125](https://github.com/danthorpe/Operations/pull/125), [OPR-130](https://github.com/danthorpe/Operations/pull/130)]: Fixes a bug where a completion block would be executed twice. 

    Thanks again to Frank ([@difujia](https://github.com/difujia)) for raising the issue.

3. [[OPR-127](https://github.com/danthorpe/Operations/issues/127), [OPR-131](https://github.com/danthorpe/Operations/pull/131)]: Fixes a bug where an operation could fail to start due to a race condition. Now, if an operation has no conditions, rather than entering a `.EvaluatingConditions` state, it will immediately (i.e. synchronously) become `.Ready`. 

    Thanks to Kevin ([@kevinbrewster](https://github.com/kevinbrewster)) for raising this issue.

4. [[OPR-142](https://github.com/danthorpe/Operations/pull/142)]: `Operation` now checks the current state in comparison to `.Ready` before adding conditions or operations. This is unlikely to be a breaking change, as it is not a significant difference.

    Thanks to Frank ([@difujia](https://github.com/difujia)) for this one.

5. [[OPR-146](https://github.com/danthorpe/Operations/pull/146)]: Fixes a subtle issue where assessing the readiness could trigger state changes.


# 2.4.1
1. [[OPR-113](https://github.com/danthorpe/Operations/pull/113)]: Fixes an issue where building against iOS 9 using Carthage would unleash a tidal wave of warnings related to ABAddressBook. Thanks to [@JaimeWhite](https://github.com/JamieWhite) for bringing this to my attention!
2. [[OPR-114](https://github.com/danthorpe/Operations/pull/114)]: Reorganized the repository into two project files. One create standard frameworks for applications, for iOS, watchOS, tvOS, and OS X. The other creates Extension API compatible frameworks for iOS, tvOS and OS X. At the moment, if you wish to use an API extension compatible framework with Carthage - this is a problem, as Carthage only builds one project, however the is a Pull Request which will fix this. The issue previously was that the `Operations.framework` products would overwrite each other. I’ve tried everything I can think of to make Xcode produce a product which has a different name to its module - but it won’t let me. So.. the best thing to do in this case is use CocoaPods and the Extension subspec.
3. [[OPR-115](https://github.com/danthorpe/Operations/pull/115)]: Fixes an issue with code coverage after project reorganization.
4. [[OPR-116](https://github.com/danthorpe/Operations/pull/116)]: Fixes a mistake where `aggregateErrors` was not publicly accessible in `GroupOperation`. Thanks to [@JaimeWhite](https://github.com/JamieWhite) for this.

Thanks a lot to [@JaimeWhite](https://github.com/JamieWhite) for helping me find and squash some bugs with this release. Greatly appreciated!  

# 2.4.0
1. [[OPR-108](https://github.com/danthorpe/Operations/pull/108)]: Adds an internal logging mechanism to `Operation`. Output log information using the `log` property  of the operation. This property exposes simple log functions. E.g.

   ```swift
   let operation = MyOperation() // etc
   operation.log.info(“This is a info message.”)
   ```
To use a custom logger, create a type conforming to `LoggerType` and add an instance property to your `Operation` subclass. Then override `getLogger()` and `setLogger(: LoggerType)` to get/set your custom property.

The global severity is set to `.Warning`, however individual operation loggers can override to set it lower, e.g. 

    ```swift
    operation.log.verbose(“This verbose message will not be logged, as the severity threshold is .Warning”)
    operation.log.severity = .Verbose
    operation.log.verbose(“Now it will be logged.”)
    ```
2. [[OPR-109](https://github.com/danthorpe/Operations/pull/109)]: Added documentation to all of the Capability (device permissions etc) functionality. Also now uses Jazzy categories configuration to make the generated documentation more easily navigable. Documentation is hosted on here: [docs.danthorpe.me/operations](http://docs.danthorpe.me/operations/2.4.0/index.html).


# 2.3.0
1. [[OPR-89](https://github.com/danthorpe/Operations/pull/89)]: Adds support (via subspecs) for watchOS 2 and tvOS apps.
2. [[OPR-101](https://github.com/danthorpe/Operations/pull/101)]: Fixes a bug where `ReachableOperation` may fail to start in some scenarios.
3. [[OPR-102](https://github.com/danthorpe/Operations/pull/102)]: Adds more documentation to the finish method of Operation. If it’s possible for an Operation to be cancelled before it’s started, then do not call finish. This is mostly likely a possibility when writing network operations and cancelling groups.
4. [[OPR-103](https://github.com/danthorpe/Operations/pull/103)]: Adds % of code covered by tests to the README. Service performed by CodeCov.
5. [[OPR-104](https://github.com/danthorpe/Operations/pull/104)]: Maintenance work on the CI scripts, which have now moved to using a build pipeline which is uploaded to BuildKite and executed all on the same physical box. See [post on danthorpe.me](http://danthorpe.me/posts/uploading-build-pipelines.html).
6. [[OPR-105](https://github.com/danthorpe/Operations/pull/105)]: Improves the testability and test coverage of the Reachability object.
7. [[OPR-106](https://github.com/danthorpe/Operations/pull/106)]: Adds more tests to the AddressBook swift wrapper, increases coverage of `Operation`, `NegatedCondition` & `UIOperation`.

# 2.2.1
1. [[OPR-100](https://github.com/danthorpe/Operations/pull/100)]: Adds documentation to all “Core” elements of the framework. Increases documentation coverage from 8% to 22%. Still pretty bad, but will get there eventually.

# 2.2.0
1. [[OPR-91](https://github.com/danthorpe/Operations/pull/91), [OPR-92](https://github.com/danthorpe/Operations/pull/92)]: Fixes a bug in AddressBook when building against iOS 9, where `Unmanaged<T>` could be unwrapped incorrectly.
2. [[OPR-93](https://github.com/danthorpe/Operations/pull/93), [OPR-95](https://github.com/danthorpe/Operations/pull/95)]: Adds support for Contacts.framework including `ContactsCondition` plus operations for `GetContacts`, `GetContactsGroup`, `RemoveContactsGroup`, `AddContactsToGroup` and `RemoveContactsFromGroup` in addition to a base contacts operation class. Also included are UI operations `DisplayContactViewController` and `DisplayCreateContactViewController`.
3. [[OPR-97](https://github.com/danthorpe/Operations/pull/97), [OPR-98](https://github.com/danthorpe/Operations/pull/98)]: Refactors how device authorization permissions are checked and requested. Introduces the concept of a `CapabilityType` to govern authorization status and requests. This works in tandem with new operations `GetAuthorizationStatus<Capability>` and `Authorize<Capability>` with an operation condition `AuthorizedFor<Capability>`. The following conditions are now deprecated: `CalendarCondition`, `CloudContainerCondition`, `HealthCondition`, `LocationCondition`, `PassbookCondition`, `PhotosCondition` in favor of `Capability.Calendar`, `Capability.Cloud`, `Capability.Heath`, `Capability.Location`, `Capability.Passbook`, `Capability.Photos` respectively. Replace your condition code like this example:

```swift
operation.addCondition(AuthorizedFor(Capability.Location(.WhenInUse)))
```

# 2.1.0
1. [[OPR-90](https://github.com/danthorpe/Operations/pull/90)]: Multi-platform support. Adds new framework targets to the project for iOS Extension only API framework. This doesn’t have support for BackgroundObserver, or NetworkObserver for example. Use `pod ‘Operations/Extension’` to use it in a Podfile for your iOS Extension target. Also, we have Mac OS X support (no special pod required). And watchOS support - use `pod ‘Operations/watchOS’`.

# 2.0.2
1. [[OPR-87](https://github.com/danthorpe/Operations/pull/87)]: Improves the reliability of the reverse geocoder unit tests.

# 2.0.1
1. [[OPR-62, OPR-86](https://github.com/danthorpe/Operations/pull/86)]: Fixes a bug in Swift 2.0 where two identical conditions would cause a deadlock. Thanks to @mblsha.
2. [[OPR-85](https://github.com/danthorpe/Operations/pull/85)]: Fixes up the Permissions example project for Swift 2.0. Note that YapDatabase currently has a problem because it has some weak links, which doesn’t work with Bitcode enabled, which is default in Xcode 7. This PR just turned off Bitcode, but if you re-run the Pods, then that change will be over-ridden. What you can do instead, if YapDatabase is still not fixed is to use my fork which has a fix on the `YAP-180` branch.

# 2.0.0
This is the Swift 2.0 compatible version.

# 1.0.0
1. [[OPR-79](https://github.com/danthorpe/Operations/pull/79)]: Adds more documentation to the types.
2. [[OPR-83](https://github.com/danthorpe/Operations/pull/83)]: Adds some convenience functions to `NSOperation` and `GroupOperation` for adding multiple dependencies at once, and multiple operations to a group before it is added to a queue.

This is a release for Swift 1.2 compatible codebases.

# 0.12.1
1. [[OPR-74](https://github.com/danthorpe/Operations/pull/74)]: Work in progress on AddressBook external change request. *Warning* so not use this, as I cannot actually get this working yet.
2. [[OPR-75](https://github.com/danthorpe/Operations/pull/75)]: Fixes a serious bug where attempting to create an ABAddressBook after previously denying access executed a fatalError.

# 0.12.0
1. [[OPR-63](https://github.com/danthorpe/Operations/pull/63)]: Speeds up the test suite by 40 seconds.
2. [[OPR-65](https://github.com/danthorpe/Operations/pull/65)]: Adds a generic `UIOperation` class. Can be used to show view controllers, either present modally, show or show detail presentations. It is used as the basis for `AlertOperation`, and the `AddressBookDisplayPersonController`, `AddressBookDisplayNewPersonController` operations.
3. [[OPR-67](https://github.com/danthorpe/Operations/pull/67)]: Adds reverse geocode operations. Supply a `CLLocation` to `ReverseGeocodeOperation` directly. Or use `ReverseGeocodeUserLocationOperation` to reverse geocode the user’s current location. Additionally, `LocationOperation` has been renamed to `UserLocationOperation`.
4. [[OPR-68](https://github.com/danthorpe/Operations/pull/68)]: General improvements to the `AddressBook` APIs including a `createPerson` function, plus addition of missing person properties & labels. Additionally, fixes a bug in setting multi-value string properties.
5. [[OPR-71](https://github.com/danthorpe/Operations/pull/71)]: Updates the unit test scripts to use Fastlane, same as Swift 2.0 branch.

# 0.11.0
1. [[OPR-45](https://github.com/danthorpe/Operations/pull/45), [OPR-46](https://github.com/danthorpe/Operations/pull/46), [OPR-47](https://github.com/danthorpe/Operations/pull/47), [OPR-48](https://github.com/danthorpe/Operations/pull/48), [OPR-49](https://github.com/danthorpe/Operations/pull/49), [OPR-54](https://github.com/danthorpe/Operations/pull/54)]:

Refactor of AddressBook.framework related functionality. The `AddressBookOperation` is no longer block based, but instead keeps a reference to the address book as a property. This allows for superior composition. Additionally there is now an `AddressBookGetResource` operation, which will access the address book, and then exposes methods to read people, and if set, an individual person record and group record.

Additionally, there is now operations for adding/removing a person to a group. Add/Remove groups. And map all the people records into your own type.

Internally, these operations are supported by a Swift wrapper of the AddressBook types, e.g. `AddressBookPerson` etc. This wrapper is heavily inspired by the Gulliver. If you want more powerful AddressBook features, I suggest you checkout that project, and then either subclass the operations to expose Gulliver types, or write a simple protocol extension to get Gulliver types from `AddressBookPersonType` etc etc.

2. [[OPR-57](https://github.com/danthorpe/Operations/pull/57)]: The CloudKitOperation is no longer a GroupOperation, just a standard Operation, which enqueues the `CKDatabaseOperation` onto the database’s queue directly.
3. [[OPR-58](https://github.com/danthorpe/Operations/pull/58)]: Added `ComposedOperation` which is a specialized `GatedOperation` which always succeeds. This is handy if you want to add conditions or observers to an `NSOperation`.
4. [[OPR-60](https://github.com/danthorpe/Operations/pull/60)]: Renamed `NoCancellationsCondition` to `NoFailedDependenciesCondition` which encompasses the same logic, but will also fail if any of the operation’s dependencies are `Operation` subclasses which have failed. In addition, `Operation` now exposes all it’s errors via the `errors` public property.

# 0.10.0
1. [[OPR-14](https://github.com/danthorpe/Operations/pull/14)]: Supports Photos library permission condition.
2. [[OPR-16](https://github.com/danthorpe/Operations/pull/16)]: Supports Health Kit permission condition.

# 0.9.0
1. [[OPR-11](https://github.com/danthorpe/Operations/pull/11)]: Supports Passbook condition.
2. [[OPR-13](https://github.com/danthorpe/Operations/pull/13)]: Supports a EventKit permission condition.
3. [[OPR-17](https://github.com/danthorpe/Operations/pull/17)]: Supports remote notification permission condition.
4. [[OPR-18](https://github.com/danthorpe/Operations/pull/18)]: Supports user notification settings condition.
5. [[OPR-38](https://github.com/danthorpe/Operations/pull/38)]: Adds a `LocationOperation` demo to Permissions.app
6. [[OPR-39](https://github.com/danthorpe/Operations/pull/39)]: Adds a user confirmation alert condition.


# 0.8.0
1. [[OPR-37](https://github.com/danthorpe/Operations/pull/37)]: Creates an example app called Permissions. This is a simple catalogue style application which will be used to demonstrate functionality of the Operations framework.

At the moment, it only shows Address Book related functionality. Including using combinations of `SilentCondition`, `NegatedCondition` and `AddressBookCondition` to determine if the app has already got authorization, requesting authorization and performing a simple ABAddressBook related operation.

Additionally, after discussions with Dave DeLong, I’ve introduced changes to the underlying Operation’s state machine.

Lastly, the structure of `BlockOperation` has been modified slightly to allow the task execution block to pass an error (`ErrorType`) into the continuation block. Because closures cannot have default arguments, this currently means that it is required, e.g. `continueWithError(error: nil)` upon success. 
 

# 0.7.0
1. [[OPR-7](https://github.com/danthorpe/Operations/pull/7)]: Supports a condition which requires all of an operation’s dependencies to succeed.
2. [[OPR-12](https://github.com/danthorpe/Operations/pull/12)]: Adds `LocationOperation` and `LocationCondition`. This allows for accessing the user’s location, requesting “WhenInUse” authorization.
3. [[OPR-36](https://github.com/danthorpe/Operations/pull/36)]: Adds `AddressBookOperation` which allows for access to the user’s address book inside of a handler block (similar to a `BlockOperation`). As part of this, `AddressBookCondition` is also available, which allows us to condition other operation types.


# 0.6.0
1. [[OPR-5](https://github.com/danthorpe/Operations/pull/5)]: Supports silent conditions. This means that if a condition would normally produce an operation (say, to request access to a resource) as a dependency, composing it inside a `SilentCondition` will suppress that dependent operation.
2. [[OPR-6](https://github.com/danthorpe/Operations/pull/r)]: Supports negating condition.
3. [[OPR-30](https://github.com/danthorpe/Operations/pull/30)]: Adds a `LoggingObserver` to log operation lifecycle events.
4. [[OPR-33](https://github.com/danthorpe/Operations/pull/33)]: Adds `GatedOperation` which will only execute the composed operation if the supplied block evaluates true - i.e. opens the gate.
5. [[OPR-34](https://github.com/danthorpe/Operations/pull/34)] & [[OPR-35](https://github.com/danthorpe/Operations/pull/35)]: Adds a `ReachableOperation`. Composing an operation inside a `ReachableOperation` will ensure that it runs after the device regains network reachability. If the network is reachable, the operation will execute immediately, if not, it will register a Reachability observer to execute the operation when the network is available. Unlike the `ReachabilityCondition` which will fail if a host is not available, use `ReachableOperation` to perform network related tasks which must be executed regardless.


# 0.5.0
1. [[OPR-22](https://github.com/danthorpe/Operations/pull/22)]: Supports displaying a `UIAlertController` as a `AlertOperation`.
2. [[OPR-26](https://github.com/danthorpe/Operations/pull/26)]: Adds a Block Condition. This allows an operation to only execute if a block evaluates true.
3. [[OPR-27](https://github.com/danthorpe/Operations/pull/27)]: Fixes a bug where the `produceOperation` function was not publicly accessible. Thanks - @MattKiazyk
4. [[OPR-28](https://github.com/danthorpe/Operations/pull/28)]: Supports a generic `Operation` subclass which wraps a `CKDatabaseOperation` setting the provided `CKDatabase`.
5. [[OPR-29](https://github.com/danthorpe/Operations/pull/29)]: Improves the `CloudCondition.Error` to include `.NotAuthenticated` for when the user is not signed into iCloud.


# 0.4.2 - Initial Release of Operations.
Base `Operation` and `OperationQueue` classes, with the following features.

The project has been developed using Xcode 7 and Swift 2.0, with  unit testing (~ 75% test coverage). It has now been back-ported to Swift 1.2 for version 1.0 of the framework. Version 2.0 will support Swift 2.0 features, including iOS 9 technologies such as Contacts framework etc.

1. Operation types:
1.1. `BlockOperation`: run a block inside an operation, taking advantage of Operation features.
1.2. `GroupOperation`: compose one more operations into a group.
1.3. `DelayOperation`: delay execution of operations on the queue.

2. Conditions
Conditions can be attached to `Operation`s, and optionally introduce new `NSOperation` instances to overcome the condition requirements. E.g. presenting a permission dialog. The following conditions are currently supported:
2.1. `MutuallyExclusive`: for exclusivity of a given kind, e.g. to prevent system alerts presenting at the same time.
2.2. `ReachabilityCondition`: only execute tasks when the device is online.
2.3. `CloudCondition`: authorised access to a CloudKit container. 

3. Observers
Observers can be attached to `Operation`s, and respond to events such as the operation starting, finishing etc. Currently observer types are:
3.1. `BackgroundObserver`: when the app enters the background, a background task will automatically be started, and ended when the operation ends.
3.2. `BlockObserver`: run arbitrary blocks when events occur on the observed operation.
3.3. `NetworkObserver`: updates the status of the network indicator.
3.4. `TimeoutObserver`: trigger functionality if the operation does not complete within a given time interval.

