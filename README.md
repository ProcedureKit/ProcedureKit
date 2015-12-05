![](https://raw.githubusercontent.com/danthorpe/Operations/development/header.png)

[![Build status](https://badge.buildkite.com/4bc80b0824c6357ae071342271cb503b8994cf0cfa58645849.svg?branch=master)](https://buildkite.com/blindingskies/operations)
[![codecov.io](http://codecov.io/github/danthorpe/Operations/coverage.svg?branch=development)](http://codecov.io/github/danthorpe/Operations?branch=development)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/Operations.svg)](https://img.shields.io/cocoapods/v/Operations.svg)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/Operations.svg?style=flat)](http://cocoadocs.org/docsets/Operations)

# Operations

A Swift framework inspired by WWDC 2015 Advanced NSOperations session. See the session video here: https://developer.apple.com/videos/wwdc/2015/?id=226

## Status - 5th Dec, 2015

As of version 2.3, Operations is a multi-platform framework, with CocoaPods support in addition to framework targets for iOS Extensions, iOS Apps, OS X, watchOS and tvOS.

Current development focus is on improving test coverage (broke 60% for v2.3), and improving documentation coverage. Documentation is hosted here: [docs.danthorpe.me/operations](http://docs.danthorpe.me/operations/2.4.1/index.html).

As part of the bug fixing for 2.4.1, it was discovered that it is not currently possible to install the API Extension compatible framework via Carthage. This boiled down to having two schemes for the same platform, and Carthage doesn’t provide a way to pick. Now, there are two separate projects, one for API extension compatible frameworks only, which doesn’t actually solve the problem. But, there is a [pull request](https://github.com/Carthage/Carthage/pull/892) which should allow all projects to be build. For now, the only semi-automatic way to integrate these flavors is to use Cocoapods: `pod 'Operations/Extension'`. 

## Usage

`NSOperation` is a class which enables composition of discrete tasks or work for asynchronous execution on an operation queue. It is therefore an abstract class, and `Operation` is a similar abstract class. Therefore, typical usage in your own codebase would be to subclass `Operation` and override `execute`.

For example, an operation to save a `Contact` value in `YapDatabase` might be:

```swift
class SaveContactOperation: Operation {
    typealias CompletionBlockType = Contact -> Void

    let connection: YapDatabaseConnection
    let contact: Contact
    let completion: CompletionBlockType?

    init(connection: YapDatabaseConnection, contact: Contact, completion: CompletionBlockType? = .None) {
        self.connection = connection
        self.contact = contact
        self.completion = completion
        super.init()
        name = “Save Contact: \(contact.displayName)”
    }

    override func execute() {
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
        message: NSLocalizedString("The contact will be removed from all your devices.", comment: "The contact will be removed from all your devices."),
        action: NSLocalizedString("Delete", comment: "Delete"),
        isDestructive: true,
        cancelAction: NSLocalizedString("Cancel", comment: "Cancel"),
        presentingController: self)
    delete.addCondition(confirmation)
    queue.addOperation(delete)
}
```

When this delete operation is added to the queue, the user will be presented with a standard system `UIAlertController` asking if they're sure. Additionally, other `AlertOperation` instances will be prevented from running.

The above “save contact” operation looks quite verbose for though for a such a simple task. Luckily in reality we can do this:

```swift
let save = ComposedOperation(connection.writeOperation(contact))
save.addObserver(BlockObserver { (_, errors) in
    print(“Did save contact”)
})
queue.addOperation(save)
```

Because sometimes creating an `Operation` subclass is a little heavy handed. Above we composed an existing `NSOperation` but we can utilize a `BlockOperation`. For example, let say we want to warn the user before they cancel a "Add New Contact" controller without saving the Contact. 

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

## Device & OS Permissions

Requesting permissions from the user can often be a relatively complex task, which almost all apps have to perform at some point. Often developers put requests for these permissions in their AppDelegate, meaning that new users are bombarded with alerts. This isn't a great experience, and Apple expressly suggest only requesting permissions when you need them. However, this is easier said than done. The Operations framework can help however. Lets say we want to get the user's current location.

```swift
func getCurrentLocation(completion: CLLocation -> Void) {
    queue.addOperation(UserLocationOperation(handler: completion))
}
```

This operation will automatically request the user's permission if the application doesn't already have the required authorization, the default is "when in use".

Perhaps also you want to just test to see if authorization has already been granted, but not ask for it if it hasn't. In Apple’s original sample code from WWDC 2015, there are a number of `OperationCondition`s which express the authorization status for device or OS permissions. Things like, `LocationCondition`, and `HealthCondition`. However, in version 2.2 of Operations I moved away from this model to unify this functionality into the `CapabilityType` protocol. Where previously there were bespoke conditions (and errors) to test the status, there is now a single condition, which is initialized with a `CapabilityType`. 

For example, where previously you would have written this:

```swift
operation.addCondition(LocationCondition(usage: .WhenInUse))
```

now you write this:

```swift
operation.addCondition(AuthorizedFor(Capability.Location(.WhenInUse)))
```

As of 2.2 the following capabilities are expressed:

- [x] `Capability.Calendar` - includes support for `EKEntityType` requirements, defaults to `.Event`.
- [x] `Capability.Cloud` - includes support for default `CKContainer` or with specific identifier, and `.UserDiscoverable` cloud container permissions.
- [x] `Capability.Health` - improved support for exactly which `HKObjectType`s have read permissions. Please get in touch if you want to use HealthKit with Operations, as I currently don't, and would like some feedback or input on further improvements that can be made for HealthKit.
- [x] `Capability.Location` - includes support for required usage, either `.WhenInUse` (the default) or `.Always`.
- [x] `Capability.Passbook` - note here that there is void "status" type, just an availability boolean.
- [x] `Capability.Photos` 

In addition to a generic operation condition, which can be used as before with `SilentCondition` and `NegatedCondition`. There are also two capability generic operations. `GetAuthorizationStatus` will retrieve the current status of the capability. `Authorize` will explicity request the required permissions for the capability. Both of these operations accept the capability as their first initializer argument without a label, and have a completion block with the same type. Therefore, it is trivial to write a function which can update your controller or UI and use it for both operations.

For example here we can check the status of location services for the app:

```swift
func locationServicesEnabled(enabled: Bool, withAuthorization status: CLAuthorizationStatus) {
    switch (enabled, status) {
        case (false, _):
           // Location services are not enabled
        case (true, .NotDetermined):
           // Location services are enabled, but not currently determined for the app.
    }
}

func determineAuthorizationStatus() {
    queue.addOperation(GetAuthorizationStatus(Capability.Location(), completion: locationServicesEnabled))
}

func requestPermission() {
    queue.addOperation(Authorize(Capability.Location(), completion: locationServicesEnabled))
}
```

See the Permissions example project, where the above code is taken from.


## Installation

Operations is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Operations'
```

## Features

This is a brief summary of the current and planned functionality.

### Foundation

- [x] `Operation` and `OperationQueue` class definitions.
- [x] `OperationCondition` and evaluator functionality.
- [x] `OperationObserver` definition and integration.

### Building Blocks

- [x] `MutuallyExclusive` condition e.g. can only one `AlertPresentation` at once.
- [x] `NegatedCondition` evaluates the reverse of the composed condition.
- [x] `SilentCondition` suppress any dependencies of the composed condition.
- [x] ~~`NoCancelledDependencies`~~ `NoFailedDependenciesCondition` requires that all dependencies succeeded.
- [x] `BlockObserver` run blocks when the attached operation starts, produces another operation or finishes.
- [x] `BackgroundObserver` automatically start and stop background tasks if the application enters the background while the attached operation is running.
- [x] `NetworkObserver` automatically manage the device’s network indicator while the operation is running.
- [x] `TimeoutObserver` automatically cancel the attached operation if the timeout interval is reached.
- [x] `LoggingObserver` enable simple logging of the lifecycle of the operation and any of it’s produced operations.
- [x] `GroupOperation` encapsulate multiple operations into their own discrete unit, running on their own queue. Supports internally adding new operations, so can be used for batch processing or greedy operation tasks.
- [x] `DelayOperation` inserts a delay into the operation queue.
- [x] `BlockOperation` run a block inside an `Operation`. Supports unsuccessful finishing.
- [x] `GatedOperation` only run the composed operation if the provided block evaluates true.
- [x] `ComposedOperation` run a composed `NSOperation`. This is great for adding conditions or observers to bog-standard `NSOperation`s without having to subclass them. 

### Features

- [x] `GetAuthorizationStatus` get the current authorization status for the given `CapabilityType`. Supports EventKit, CloudKit, HealthKit, CoreLocation, PassKit, Photos.
- [x] `Authorize` request the required permissions to access the required `CapabilityType`. Supports EventKit, CloudKit, HealthKit, CoreLocation, PassKit, Photos.
- [x] `AuthorizedFor` express the required permissions to access the required `CapabilityType` as an `OperationCondition`. Meaning that if the status has not been determined yet, it will trigger authorization. Supports EventKit, CloudKit, HealthKit, CoreLocation, PassKit, Photos.
- [x] `ReachabilityCondition` requires that the supplied URL is reachable.
- [x] `ReachableOperation` compose an operation which must complete and requires network reachability. This uses an included system  Reachability object and does not require any extra dependencies. However currently in Swift 1.2, as function pointers are not supported, this uses a polling mechanism with `dispatch_source_timer`. I will probably replace this with more efficient Objective-C soon.
- [x] `CloudKitOperation` compose a `CKDatabaseOperation` inside an `Operation` with the appropriate `CKDatabase`.
- [x] `UserLocationOperation` access the user’s current location with desired accuracy. 
- [x] `ReverseGeocodeOperation` perform a reverse geocode lookup of the supplied `CLLocation`.
- [x] `ReverseGeocodeUserLocationOperation` perform a reverse geocode lookup of user’s current location.  
- [x] `UserNotificationCondition` require that the user has granted permission to present notifications.
- [x] `RemoteNotificationCondition` require that the user has granted permissions to receive remote notifications.
- [x] `UserConfirmationCondition` requires that the user confirms an action presented to them using a `UIAlertController`. The condition is configurable for title, message and button texts. 
- [x] `WebpageOperation` given a URL, will present a `SFSafariViewController`.

### +AddressBook

Available as a subspec (if using CocoaPods) is `ABAddressBook.framework` related operations.

- [x] `AddressBookCondition` require authorized access to ABAddressBook. Will automatically request access if status is not already determined.
- [x] `AddressBookOperation` is a base operation which creates the address book and requests access.
- [x] `AddressBookGetResource` is a subclass of `AddressBookOperation` and exposes methods to access resources from the address book. These can include person records and groups. All resources are wrapped inside Swift facades to the underlying opaque AddressBook types.
- [x] `AddressBookGetGroup` will get the group for a given name.
- [x] `AddressBookCreateGroup` will create the group for a given name, if it doesn’t already exist.
- [x] `AddressBookRemoveGroup` will remove the group for a given name.
- [x] `AddressBookAddPersonToGroup` will add the person with record id to the group with the provided name.
- [x] `AddressBookRemovePersonFromGroup` will remove the person with record id from the group with the provided name.
- [x] `AddressBookMapPeople<T>` takes an optional group name, and a mapping transform. It will map all the people in the address book (or in the group) via the transform. This is great if you have your own representation of a Person, and which to import the AddressBook. In such a case, create the following:

```swift
extension MyPerson {
    init?(addressBookPerson: AddressBookPerson) {
        // Create a person, return nil if not possible.
    }
}
```

Then, import people

```swift
let getPeople = AddressBookMapPeople { MyPerson($0) }
queue.addOperation(getPeople)
```

Use an observer or `GroupOperation` to access the results via the map operation’s `results` property.

- [x] `AddressBookDisplayPersonViewController` is an operation which will display a person (provided their record id), from a controller in your app. This operation will perform the necessary address book tasks. It can present the controller using 3 different styles, either `.Present` (i.e. modal), `.Show` (i.e. old style push) or `.ShowDetail`. Here’s an example:

```swift
    func displayPersonWithAddressBookRecordID(recordID: ABRecordID) {
        let controller = ABPersonViewController()
        controller.allowsActions = true
        controller.allowsEditing = true
        controller.shouldShowLinkedPeople = true
        let show = AddressBookDisplayPersonViewController(
						personViewController: controller, 
						personWithID: recordID, 
						displayControllerFrom: .ShowDetail(self), 
						delegate: self
				)
        queue.addOperation(show)
    }
```
- [x] `AddressBookDisplayNewPersonViewController` same as the above, but for showing the standard create new person controller. For example:

```swift
    @IBAction func didTapAddNewPerson(sender: UIBarButtonItem) {
        let show = AddressBookDisplayNewPersonViewController(
					displayControllerFrom: .Present(self), 
					delegate: self, 
					addToGroupWithName: “Special People”
				)
        queue.addOperation(show)
    }
```


## Motivation

I want to stress that this code is heavily influenced by Apple. In no way am I attempting to assume any sort of credit for this architecture - that goes to [Dave DeLong](https://twitter.com/davedelong) and his team. My motivations are that I want to adopt this code in my own projects, and so require a solid well tested framework which I can integrate with.

