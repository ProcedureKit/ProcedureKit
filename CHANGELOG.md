# 0.7.0
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

