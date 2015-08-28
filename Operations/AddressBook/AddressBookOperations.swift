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

    internal var registrar: AddressBookPermissionRegistrar
    public var addressBook: AddressBook

    public init(registrar r: AddressBookPermissionRegistrar? = .None) {
        registrar = r ?? SystemAddressBookRegistrar()
        addressBook = AddressBook(registrar: registrar)
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

    public var addressBookGroup: AddressBookGroup? = .None
    public var addressBookPerson: AddressBookPerson? = .None

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

    public func allAddressBookPeople() -> [AddressBookPerson] {
        return addressBook.people()
    }

    public func addressBookPeopleInGroup() -> [AddressBookPerson]? {
        return addressBookGroup.map { $0.members() }
    }

    public func addressBookPeopleNotInGroup() -> [AddressBookPerson] {
        let all = allAddressBookPeople()
        return addressBookGroup.map {
            let members: [AddressBookPerson] = $0.members()
            return all.filter { !contains(members, $0) }
        } ?? all
    }

    public func addressBookPeople() -> [AddressBookPerson] {
        if let group = addressBookGroup {
            return group.members()
        }
        else if let source = source() {
            return addressBook.peopleInSource(source)
        }
        else {
            return addressBook.people()
        }
    }

    // Queries

    public func executeAddressBookGroupQuery(query: Query) -> AddressBookGroup? {
        switch query {

        case .ID(let id):
            return addressBook.groupWithID(id)

        case .Name(let groupName):
            return groups().filter {
                if let name = $0.value(forProperty: AddressBookGroup.Property.name) {
                    return groupName == name
                }
                return false
            }.first
        }
    }

    public func executeAddressBookPersonQuery(query: Query) -> AddressBookPerson? {
        switch query {
        case .ID(let id):
            return addressBook.personWithID(id)

        case .Name(let name):
            return addressBook.peopleWithName(name).first
        }
    }

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }

        addressBookGroup = groupQuery.map { self.executeAddressBookGroupQuery($0) } ?? .None
        addressBookPerson = personQuery.map { self.executeAddressBookPersonQuery($0) } ?? .None

        return .None
    }

    // Actions

    public func addPeople(people: [AddressBookPerson], toGroup group: AddressBookGroup) -> ErrorType? {

        for person in people {
            if let error = group.add(person) {
                return error
            }
        }

        if let error = addressBook.save() {
            return error
        }

        return .None
    }
}

// MARK: - Group Actions

public class AddressBookGetGroup: AddressBookGetResource {

    public init(registrar r: AddressBookPermissionRegistrar? = .None, name: String) {
        super.init(registrar: r)
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
        if addressBookGroup == nil, let groupName = groupQuery?.name {

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

            self.addressBookGroup = group
        }
        return .None
    }
}

public class AddressBookRemoveGroup: AddressBookGetGroup {

    func removeGroup() -> ErrorType? {
        if let group = addressBookGroup {
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
    }

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return addPersonToGroup()
    }

    func addPersonToGroup() -> ErrorType? {

        if let group = addressBookGroup {
            if let person = addressBookPerson {
                return addPeople([person], toGroup: group)
            }
            else {
                return AddressBookError.FailedToGetPerson(personQuery)
            }
        }
        else {
            return AddressBookError.FailedToGetGroup(groupQuery)
        }
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
        if addressBookGroup == nil {
            return AddressBookError.FailedToGetGroup(groupQuery)
        }

        if addressBookPerson == nil {
            return AddressBookError.FailedToGetPerson(personQuery)
        }

        if let group = addressBookGroup, person = addressBookPerson, error = group.remove(person) {
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
        }
    }

    public override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return mapPeople()
    }

    func mapPeople() -> ErrorType? {
        results = addressBookPeople().flatMap { flatMap(self.transform($0), { [$0] }) ?? [] }
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
        if errors.isEmpty && get == operation, let person = get.addressBookPerson {
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
            let op = DisplayNewPersonController(displayStyle: displayStyle, delegate: delegate, sender: sender, addressBook: get.addressBook, group: get.addressBookGroup)
            addOperation(op)
        }
    }
}



// MARK: - External Change Callbacks

public struct AddressBookObserverQueue {

    private static let queue = OperationQueue()
    private static var shared = AddressBookObserverQueue()

    public static func start() -> AddressBookObserverQueue {
        shared.start()
        return shared
    }

    public static func stop() {
        shared.stop()
    }

    var observer: AddressBookObserver? = .None

    private init() { }

    private mutating func start() {
        observer = AddressBookObserver()
        observer?.addObserver(self)
        AddressBookObserverQueue.queue.addOperation(observer!)
    }

    private mutating func stop() {
        observer?.cancel()
    }
}

extension AddressBookObserverQueue: OperationObserver {
    public func operationDidStart(operation: Operation) {
        println("Started listening for AddressBook changes.")
    }

    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        println("AddressBookObserver produced new Observer?")
    }

    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        println("Stopped listening for AddressBook changes.")
    }
}

public class AddressBookObserver: GroupOperation {

    class Observer: AddressBookOperation {
        typealias AddressBookDidChange = [NSObject: AnyObject]? -> Void

        let addressBookDidChange: AddressBookDidChange
        var observer: AddressBookExternalChangeObserver?

        init(_ block: AddressBookDidChange) {
            addressBookDidChange = block
        }

        deinit {
            observer?.endObservingExternalChangesToAddressBook()
        }

        override func executeAddressBookTask() -> ErrorType? {
            if let error = super.executeAddressBookTask() {
                return error
            }
            observer = addressBook.observeExternalChanges { info in
                self.addressBookDidChange(info)
                self.finish(nil)
            }
            return .None
        }

        override func cancel() {
            observer?.endObservingExternalChangesToAddressBook()
        }
    }

    var observer: Observer? = .None

    public init() {
        super.init(operations: [])
        addCondition(MutuallyExclusive<AddressBookObserver>())
        addCondition(SilentCondition(AddressBookCondition()))
    }

    public override func execute() {
        observer = Observer(addressBookDidChange)
        addOperation(observer!)
    }

    public override func cancel() {
        observer?.cancel()
    }

    func addressBookDidChange(info: [NSObject: AnyObject]?) {
        println("Address book did change: \(info)")
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty, let current = operation as? Observer {
            println("Observer did finish")
            if !cancelled {
                observer = Observer(addressBookDidChange)
                addOperation(observer!)
            }
        }
    }
}







