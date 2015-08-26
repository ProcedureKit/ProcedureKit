//
//  AddressBookOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 25/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI

// MARK: - Address Book Operation

public class AddressBookOperation: Operation {

    public var addressBook: AddressBook

    public init(registrar: AddressBookPermissionRegistrar? = .None) {
        addressBook = AddressBook(registrar: registrar ?? SystemAddressBookRegistrar())
    }

    final func requestAccess() {
        addressBook.requestAccess(accessRequestDidComplete)
    }

    final func accessRequestDidComplete(error: AddressBookPermissionRegistrarError?) {
        if let error = error {
            self.finish(error)
        }
        else {
            self.finish(executeAddressBookTask())
        }
    }

    /*  Sub-classes may over-ride this method to perform AddressBook related
        functions before the operation finishes. */
    public func executeAddressBookTask() -> ErrorType? {
        return .None
    }

    public override func execute() {
        requestAccess()
    }
}

public class AddressBookGetResource: AddressBookOperation {

    public enum AddressBookError: ErrorType {
        case FailedToGetGroup(Query?)
        case FailedToGetPerson(Query?)
    }

    public enum Source {
        case DefaultSource
        case WithRecordID(ABRecordID)
    }

    public enum Query {

        case ID(ABRecordID)
        case Name(String)

        var name: String? {
            switch self {
            case .Name(let result): return result
            default: return .None
            }
        }

        var id: ABRecordID? {
            switch self {
            case .ID(let id): return id
            default: return .None
            }
        }
    }

    public var inSource: Source? = .DefaultSource

    public var groupQuery: Query? = .None
    public var personQuery: Query? = .None

    public var group: AddressBookGroup? = .None
    public var person: AddressBookPerson? = .None

    public func source() -> AddressBookSource? {
        if let inSource = inSource {
            switch inSource {
            case .DefaultSource:
                let source: AddressBookSource = addressBook.defaultSource()
                return source
            case .WithRecordID(let id):
                return addressBook.sourceWithID(id)
            }
        }
        return .None
    }

    public func groups() -> [AddressBookGroup] {
        if let source = source() {
            return addressBook.groupsInSource(source)
        }
        else {
            return addressBook.groups()
        }
    }

    public func people() -> [AddressBookPerson] {
        if let group = group {
            return group.members()
        }
        else if let source = source() {
            return addressBook.peopleInSource(source)
        }
        else {
            return addressBook.people()
        }
    }

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }

        if let query = groupQuery {
            switch query {

            case .ID(let id):
                group = addressBook.groupWithID(id)

            case .Name(let groupName):
                group = groups().filter {
                    if let name = $0.value(forProperty: AddressBookGroup.Property.name) {
                        return groupName == name
                    }
                    return false
                }.first
            }
        }

        if let query = personQuery {
            switch query {
            case .ID(let id):
                person = addressBook.personWithID(id)

            case .Name(let name):
                person = addressBook.peopleWithName(name).first
            }
        }

        return .None
    }
}

// MARK: - Group Actions

public class AddressBookGetGroup: AddressBookGetResource {

    public init(registrar: AddressBookPermissionRegistrar? = .None, name: String) {
        super.init(registrar: registrar)
        groupQuery = .Name(name)
    }
}

public class AddressBookCreateGroup: AddressBookGetGroup {

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return createGroup()
    }

    func createGroup() -> ErrorType? {
        if group == nil, let groupName = groupQuery?.name {

            let group = AddressBookGroup()
            if let error = group.setValue(groupName, forProperty: AddressBookGroup.Property.name) {
                return error
            }

            if let error = addressBook.addRecord(group) {
                return error
            }

            if let error = addressBook.save() {
                return error
            }

            self.group = group
        }
        return .None
    }
}

public class AddressBookRemoveGroup: AddressBookGetGroup {

    func removeGroup() -> ErrorType? {
        if let group = group {
            if let error = addressBook.removeRecord(group) {
                return error
            }
            if let error = addressBook.save() {
                return error
            }
        }
        return .None
    }

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return removeGroup()
    }
}

public class AddressBookAddPersonToGroup: AddressBookGetResource {

    public init(registrar: AddressBookPermissionRegistrar? = .None, group: String, personID: ABRecordID) {
        super.init(registrar: registrar)
        groupQuery = .Name(group)
        personQuery = .ID(personID)
        addCondition(AddressBookGroupExistsCondition(registrar: registrar, name: group))
    }

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return addPersonToGroup()
    }

    func addPersonToGroup() -> ErrorType? {
        if group == nil {
            return AddressBookError.FailedToGetGroup(groupQuery)
        }

        if person == nil {
            return AddressBookError.FailedToGetPerson(personQuery)
        }

        if let group = group, person = person, error = group.add(person) {
            return error
        }

        if let error = addressBook.save() {
            return error
        }

        return .None
    }
}

public class AddressBookRemovePersonFromGroup: AddressBookGetResource {

    public init(registrar: AddressBookPermissionRegistrar? = .None, group: String, personID: ABRecordID) {
        super.init(registrar: registrar)
        groupQuery = .Name(group)
        personQuery = .ID(personID)
    }

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return removePersonFromGroup()
    }

    func removePersonFromGroup() -> ErrorType? {
        if group == nil {
            return AddressBookError.FailedToGetGroup(groupQuery)
        }

        if person == nil {
            return AddressBookError.FailedToGetPerson(personQuery)
        }

        if let group = group, person = person, error = group.remove(person) {
            return error
        }

        if let error = addressBook.save() {
            return error
        }
        
        return .None
    }
}

// MARK: - Person Actions

public class AddressBookMapPeople<T>: AddressBookGetResource {

    let transform: (AddressBookPerson) -> T?
    var results = Array<T>()

    public init(registrar: AddressBookPermissionRegistrar? = .None, inGroupNamed groupName: String? = .None, transform: (AddressBookPerson) -> T?) {
        self.transform = transform
        super.init(registrar: registrar)
        if let groupName = groupName {
            groupQuery = .Name(groupName)
            addCondition(AddressBookGroupExistsCondition(registrar: registrar, name: groupName))
        }
    }

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return mapPeople()
    }

    func mapPeople() -> ErrorType? {
        results = people().flatMap { flatMap(self.transform($0), { [$0] }) ?? [] }
        return .None
    }
}

// MARK: - UI

public enum ViewControllerDisplayStyle {
    case Show(UIViewController)
    case ShowDetail(UIViewController)
    case Present(UIViewController)

    func displayController(controller: UIViewController, sender: AnyObject?, completion: (() -> Void)?) {
        switch self {

        case .Present(let from):
            let nav = UINavigationController(rootViewController: controller)
            from.presentViewController(nav, animated: true, completion: completion)

        case .Show(let from):
            from.showViewController(controller, sender: sender)

        case .ShowDetail(let from):
            from.showDetailViewController(controller, sender: sender)

        default: break
        }
    }
}

/**
Displays an `ABPersonViewController`. To enable actions or editing, create
an `ABPersonViewController` instance and configure these settings. Pass it
to this operation as the first argument.

The operation will locate the `ABRecordRef` for the person and set this
on the controller in addition to the `ABAddressBookRef`.

Select and appropriate `DisplayStyle` to configure how the controller should
be displayed, either presented, show, show detail. For each style, associate
the sending view controller. Therefore, to push a person controller:

    let show = AddressBookDisplayPersonViewController(
        personWithId: addressBookID,
        displayFromControllerWithStyle: .Show(self),
        delegate: self,
        sender: self)
    queue.addOperation(show)

To configure the controller, you can do this:

    let controller = ABPersonViewController()
    controller.allowEditing = true
    let show = AddressBookDisplayPersonViewController(
        personViewController: controller,
        personWithId: addressBookID,
        displayFromControllerWithStyle: .Show(self),
        delegate: self,
        sender: self)
    queue.addOperation(show)
*/
public class AddressBookDisplayPersonViewController: GroupOperation {

    class DisplayPersonViewController: Operation {

        let controller: ABPersonViewController
        let displayStyle: ViewControllerDisplayStyle
        let sender: AnyObject?


        init(personViewController: ABPersonViewController? = .None, delegate: ABPersonViewControllerDelegate, displayStyle: ViewControllerDisplayStyle, sender: AnyObject?, addressBook: AddressBook, person: AddressBookPerson) {
            self.displayStyle = displayStyle
            self.sender = sender
            controller = {
                let controller = personViewController ?? ABPersonViewController()
                controller.displayedPerson = person.storage
                controller.addressBook = addressBook.addressBook
                return controller
            }()
        }

        override func execute() {
            dispatch_async(Queue.Main.queue) {
                self.displayStyle.displayController(self.controller, sender: self.sender) {
                    self.finish()
                }
            }
        }
    }

    let personViewController: ABPersonViewController?
    let displayStyle: ViewControllerDisplayStyle
    let delegate: ABPersonViewControllerDelegate
    let sender: AnyObject?

    let get: AddressBookGetResource

    public init(registrar: AddressBookPermissionRegistrar? = .None, personViewController: ABPersonViewController? = .None, personWithID id: ABRecordID, displayFromControllerWithStyle displayStyle: ViewControllerDisplayStyle, delegate: ABPersonViewControllerDelegate, sender: AnyObject? = .None) {

        self.personViewController = personViewController
        self.displayStyle = displayStyle
        self.delegate = delegate
        self.sender = sender
        self.get = AddressBookGetResource(registrar: registrar)
        self.get.personQuery = .ID(id)
        super.init(operations: [ get ])
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get == operation, let person = get.person {
            let op = DisplayPersonViewController(personViewController: personViewController, delegate: delegate, displayStyle: displayStyle, sender: sender, addressBook: get.addressBook, person: person)
            addOperation(op)
        }
    }
}


public class AddressBookDisplayNewPersonViewController: GroupOperation {

    class DisplayNewPersonController: Operation {

        let controller: ABNewPersonViewController
        let displayStyle: ViewControllerDisplayStyle
        let sender: AnyObject?

        init(displayStyle: ViewControllerDisplayStyle, delegate: ABNewPersonViewControllerDelegate, sender: AnyObject? = .None, addressBook: AddressBook, group: AddressBookGroup? = .None) {
            self.displayStyle = displayStyle
            self.sender = sender
            controller = {
                let newPersonViewController = ABNewPersonViewController()
                newPersonViewController.newPersonViewDelegate = delegate
                newPersonViewController.addressBook = addressBook.addressBook
                if let group = group {
                    newPersonViewController.parentGroup = group.storage
                }
                return newPersonViewController
            }()
        }

        override func execute() {
            dispatch_async(Queue.Main.queue) {
                self.displayStyle.displayController(self.controller, sender: self.sender) {
                    self.finish()
                }
            }
        }
    }

    let displayStyle: ViewControllerDisplayStyle
    let delegate: ABNewPersonViewControllerDelegate
    let sender: AnyObject?

    let get: AddressBookGetResource

    public init(registrar: AddressBookPermissionRegistrar? = .None, displayFromControllerWithStyle displayStyle: ViewControllerDisplayStyle, delegate: ABNewPersonViewControllerDelegate, sender: AnyObject? = .None, addToGroupWithName groupName: String? = .None) {
        self.displayStyle = displayStyle
        self.delegate = delegate
        self.sender = sender
        self.get = AddressBookGetResource(registrar: registrar)
        if let groupName = groupName {
            get.groupQuery = .Name(groupName)
        }
        super.init(operations: [ get ])
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get == operation {
            let op = DisplayNewPersonController(displayStyle: displayStyle, delegate: delegate, sender: sender, addressBook: get.addressBook, group: get.group)
            addOperation(op)
        }
    }
}










