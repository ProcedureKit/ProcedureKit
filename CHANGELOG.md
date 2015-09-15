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

