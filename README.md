# Operations

[![Build status](https://badge.buildkite.com/4bc80b0824c6357ae071342271cb503b8994cf0cfa58645849.svg)](https://buildkite.com/blindingskies/operations)

A Swift framework inspired by WWDC 2015 Advanced NSOperations session. See the session video here: https://developer.apple.com/videos/wwdc/2015/?id=226

## Motivation

I want to stress that this code is heavily influenced by Apple. In no way am I attempting to assume any sort of credit for this architecture - that goes to [Dave DeLong](https://twitter.com/davedelong) and his team. My motivations are that I want to adopt this code in my own projects, and so require a solid well tested framework which I can integrate with.

Rather than just copy Apple’s sample code, I have been re-writing it from scratch, but heavily guided. The main changes I have made, other than some minor bug fixes, have been architectural to enhance the testability of the code. Unfortunately, this makes the public API a little messy for Swift 1.2, but thanks to `@testable` will not be visible in Swift 2.

## Usage

`NSOperation` is a class which enables composition of discrete tasks or work for asynchronous execution on an operation queue. It is therefore an abstract class, and `Operation` is a similar abstract class. Therefore, typical usage in your own codebase would be to subclass `Operation` and override `execute`.

For example, an operation to save a `Contact` value in `YapDatabase` might be:

```swift
public class SaveContactOperation: Operation {
    public typealias CompletionBlockType = Contact -> Void

    let connection: YapDatabaseConnection
    let contact: Contact
    let completion: CompletionBlockType?

    public init(connection: YapDatabaseConnection, contact: Contact, completion: CompletionBlockType? = .None) {
        self.connection = connection
        self.contact = contact
        self.completion = completion
        super.init()
        name = “Save Contact: \(contact.displayName)”
    }

    public override func execute() {
        connection.asyncWrite(contact) { (returned: Contact) in
            self.completion?(returned)
            self.finish()
        }
    }
}
```

The power of the `Operations` framework however, comes with attaching conditions and observer to operations. For example, perhaps before the user is allowed to delete a `Contact`, we want them to confirm their intention. We can achieve this using the supplied `UserConfirmationCondition`.

```swift
func deleteContact(contact: Contact) {
    let delete = DeleteContactOperation(connection: readWriteConnection, contact: contact)
    let confirmation = UserConfirmationCondition(
        title: NSLocalizedString("Are you sure?", comment: "Are you sure?"),
        message: NSLocalizedString("The contact will be removed from all your devices.", comment: "The contact will be removed fromon all your devices."),
        action: NSLocalizedString("Delete", comment: "Delete"),
        isDestructive: true,
        cancelAction: NSLocalizedString("Cancel", comment: "Cancel"),
        presentingController: self)
    delete.addCondition(confirmation)
    queue.addOperation(delete)
}
```

When this delete operation is added to the queue, the user will be presented with a standard system `UIAlertController` asking if they're sure. Additionally, other `AlertOperation` instances will be prevented from running.

Sometimes, creating an `Operation` subclass is a little heavy handed, and in these situations, we can utilize a `BlockOperation`. For example, let say we want to warn the user before they cancel a "Add New Contact" controller without saving the Contact. 

```swift
@IBAction didTapCancelButton(button: UIButton) {
    dismiss()
}

func dismiss() {
    // Define a dispatch block for unwinding.
    let dismiss = {
        self.performSegueWithIdentifier(SegueIdentifier.UnwindToContacts.rawValue, sender: nil)
    }

    // Wrap this in a block operation
    let operation = BlockOperation(mainQueueBlock: dismiss)

    // Attach a condition to check if there are unsaved changes
    // this is an imaginary conditon - doesn't exist in Operation framework
    let condition = UnsavedChangesCondition(
        connection: connection,
        value: contact,
        save: save(dismiss),
        discard: BlockOperation(mainQueueBlock: dismiss),
        presenter: self
    )
    operation.addCondition(condition)

    // Attach an observer to see if the operation failed because
    // there were no edits from a default Contact - in which case
    // continue with dismissing the controller.
    operation.addObserver(BlockObserver { [unowned queue] (_, errors) in
        if let error = errors.first as? UnsavedChangesConditionError {
            switch error {
            case .NoChangesFromDefault:
                queue.addOperation(BlockOperation(mainQueueBlock: dismiss))

            case .HasUnsavedChanges:
                break
            }
        }
    })

    queue.addOperation(operation)
}

```

In the above example, we're able to compose reusable (and testable!) units of work in order to express relatively complex control logic. Another way to achieve this kind of behaviour might be through FRP techniques, however those are unlikely to yield re-usable types like `UnsavedChangesCondition`, or even `DismissController` if the above was composed inside a custom `GroupOperation`.

Requesting permissions from the user can often be a relatively complex task, which almost all apps have to perform at some point. Often developers put requests for these permissions in their AppDelegate, meaning that new users are bombarded with alerts. This isn't a great experience, and Apple expressly suggest only requesting permissions when you need them. However, this is easier said than done. The Operations framework can help however. Lets say we want to get the user's current location.

```swift
func getCurrentLocation(completion: CLLocation -> Void) {
    let location = LocationOperation(handler: completion)
    location.addCondition(LocationCondition())
    queue.addOperation(location)
}
```

This operation will automatically request the user's permission if the application doesn't already have the required authorization, the default is "when in use".

Perhaps also you want to just test to see if authorization has already been granted, but not ask for it if it hasn't. This can be done using a `BlockOperation` and `SilentCondition`.

```swift
func determineAuthorizationStatus() {
    let authorized = BlockOperation { (continueWithError: BlockOperation.ContinuationBlockType) in
        self.state = .Authorized
        continueWithError(error: nil)
    }
    authorized.addCondition(SilentCondition(LocationCondition()))
    authorized.addObserver(BlockObserver { (_, errors) in
        if let error = errors.first as? LocationCondition.Error {
            switch error {
            case let .AuthenticationStatusNotSufficient(CLAuthorizationStatus.NotDetermined, _):
                self.state = .Unknown

            case let .AuthenticationStatusNotSufficient(CLAuthorizationStatus.Denied, _):
                self.state = .Denied

            default:
                self.state = .Unknown
            }
        }
    })
    queue.addOperation(authorized)
}
```

There is an example app, Permissions.app in `example/Permissions` which contains more examples of this sort of usage. 

## Installation

Operations is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod ‘Operations’
```

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
- [x] HealthKit
- [x] Photos
- [x] Events & Reminders
- [x] Passbook
- [ ] Contacts - some initial work is done on the `swift_2.0` branch. However, currently this branch is behind `development` by quite a margin.
- [ ] Webpage - some initial work is done on a feature branch, again, Swift 2.0 only.
- [x] User Confirmation Alert - condition an operation with a user confirmation, so that the operation will only be executed if the user confirms it. Great for “delete” operation for example.


The framework is well tested, with approximately 70% coverage. This is known as I wrote it much of the foundation bits using Xcode 7 but have back ported it to Swift 1.2.

Development of a usable Swift 1.2 version is the priority. However, development of the Swift 2.0 version will shortly begin in parallel, and increase in priority. Therefore the versioning of this project will follow this pattern: Swift 1.2: `0.4 -> 1.x` and Swift 2.0: `2.0 -> 2.x`. 
