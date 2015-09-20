//
//  AddressBookOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 25/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

#if os(iOS)

import Foundation
import AddressBook
import AddressBookUI

// MARK: - Address Book Operation

public class AddressBookOperation: Operation {

    internal var registrar: AddressBookPermissionRegistrar
    public var addressBook: AddressBook!

    public override init() {
        registrar = SystemAddressBookRegistrar()
        addressBook = AddressBook(registrar: registrar)
    }

    init(registrar r: AddressBookPermissionRegistrar) {
        registrar = r
        addressBook = AddressBook(registrar: registrar)
    }

    final func requestAccess() {
        if let addressBook = addressBook {
            addressBook.requestAccess(accessRequestDidComplete)
        }
        else {
            finish(AddressBookPermissionRegistrarError.AddressBookAccessDenied)
        }
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
            return all.filter { !members.contains($0) }
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

    public init(name: String) {
        super.init()
        groupQuery = .Name(name)
    }

    init(registrar: AddressBookPermissionRegistrar, name: String) {
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

    public init(group: String, personID: ABRecordID) {
        super.init()
        groupQuery = .Name(group)
        personQuery = .ID(personID)
    }

    init(registrar: AddressBookPermissionRegistrar, group: String, personID: ABRecordID) {
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

    public init(group: String, personID: ABRecordID) {
        super.init()
        groupQuery = .Name(group)
        personQuery = .ID(personID)
    }

    init(registrar: AddressBookPermissionRegistrar, group: String, personID: ABRecordID) {
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

    public init(inGroupNamed groupName: String? = .None, transform: (AddressBookPerson) -> T?) {
        self.transform = transform
        super.init()
        if let groupName = groupName {
            groupQuery = .Name(groupName)
        }
    }

    init(registrar: AddressBookPermissionRegistrar, inGroupNamed groupName: String? = .None, transform: (AddressBookPerson) -> T?) {
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
        results = addressBookPeople().flatMap { self.transform($0) }
        return .None
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
public class AddressBookDisplayPersonViewController<F: PresentingViewController>: GroupOperation {

    let delegate: ABPersonViewControllerDelegate
    let ui: UIOperation<ABPersonViewController, F>
    let get: AddressBookGetResource

    public convenience init(personViewController: ABPersonViewController? = .None, personWithID id: ABRecordID, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: ABPersonViewControllerDelegate, sender: AnyObject? = .None) {
        self.init(registrar: SystemAddressBookRegistrar(), personViewController: personViewController, personWithID: id, displayControllerFrom: from, delegate: delegate, sender: sender)
    }

    init(registrar: AddressBookPermissionRegistrar, personViewController: ABPersonViewController? = .None, personWithID id: ABRecordID, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: ABPersonViewControllerDelegate, sender: AnyObject? = .None) {

        self.ui = UIOperation(controller: personViewController ?? ABPersonViewController(), displayControllerFrom: from, sender: sender)
        self.delegate = delegate
        self.get = AddressBookGetResource(registrar: registrar)
        self.get.personQuery = .ID(id)
        super.init(operations: [ get ])
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get == operation, let person = get.addressBookPerson {
            ui.controller.personViewDelegate = delegate
            ui.controller.displayedPerson = person.storage
            ui.controller.addressBook = get.addressBook.addressBook
            addOperation(ui)
        }
    }
}

public class AddressBookDisplayNewPersonViewController<F: PresentingViewController>: GroupOperation {

    let delegate: ABNewPersonViewControllerDelegate
    let ui: UIOperation<ABNewPersonViewController, F>
    let get: AddressBookGetResource

    public convenience init(displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: ABNewPersonViewControllerDelegate, sender: AnyObject? = .None, addToGroupWithName groupName: String? = .None) {
        self.init(registrar: SystemAddressBookRegistrar(), displayControllerFrom: from, delegate: delegate, sender: sender, addToGroupWithName: groupName)
    }

    init(registrar: AddressBookPermissionRegistrar, displayControllerFrom from: ViewControllerDisplayStyle<F>, delegate: ABNewPersonViewControllerDelegate, sender: AnyObject? = .None, addToGroupWithName groupName: String? = .None) {

        self.ui = UIOperation(controller: ABNewPersonViewController(), displayControllerFrom: from, sender: sender)
        self.delegate = delegate
        self.get = AddressBookGetResource(registrar: registrar)
        if let groupName = groupName {
            get.groupQuery = .Name(groupName)
        }
        super.init(operations: [ get ])
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get == operation {

            ui.controller.newPersonViewDelegate = delegate
            ui.controller.addressBook = get.addressBook.addressBook

            if let group = get.addressBookGroup {
                ui.controller.parentGroup = group.storage
            }

            addOperation(ui)
        }
    }
}



// MARK: - External Change Callbacks

public struct AddressBookObserverQueue {

    private static let queue = OperationQueue()
    private static var shared = AddressBookObserverQueue()

    public static func start(didChangeBlock: AddressBookObserverGroup.DidChangeBlock) -> AddressBookObserverQueue {
        shared.start(didChangeBlock)
        return shared
    }

    public static func stop() {
        shared.stop()
    }

    var addressBookObserverGroup: AddressBookObserverGroup? = .None

    private init() { }

    private mutating func start(didChangeBlock: AddressBookObserverGroup.DidChangeBlock) {
        addressBookObserverGroup = AddressBookObserverGroup(block: didChangeBlock)
        addressBookObserverGroup?.addObserver(self)
        AddressBookObserverQueue.queue.addOperation(addressBookObserverGroup!)
    }

    private mutating func stop() {
        addressBookObserverGroup?.cancel()
    }
}

extension AddressBookObserverQueue: OperationObserver {
    public func operationDidStart(operation: Operation) {
        print("Started listening for AddressBook changes.")
    }

    public func operation(operation: Operation, didProduceOperation newOperation: NSOperation) {
        print("AddressBookObserver produced new Observer?")
    }

    public func operationDidFinish(operation: Operation, errors: [ErrorType]) {
        print("Stopped listening for AddressBook changes.")
    }
}

public class AddressBookObserverGroup: GroupOperation {

    public typealias DidChangeBlock = (info: [NSObject: AnyObject]?) -> Void

    class Observer: Operation {
        typealias AddressBookDidChange = [NSObject: AnyObject]? -> Void

        let addressBook: AddressBook
        let addressBookDidChange: AddressBookDidChange
        var observer: AddressBookExternalChangeObserver?

        init(addressBook: AddressBook, block: AddressBookDidChange) {
            self.addressBook = addressBook
            self.addressBookDidChange = block
            super.init()
            addObserver(BackgroundObserver())
        }

        override func execute() {
            observer = addressBook.observeExternalChanges { info in
                self.addressBookDidChange(info)
                self.finish(nil)
            }
        }
    }

    let didChangeBlock: DidChangeBlock
    let accessAddressBook: AddressBookOperation

    var addressBook: AddressBook? = .None
    var observer: Observer? = .None

    init(block: DidChangeBlock) {
        didChangeBlock = block
        accessAddressBook = AddressBookOperation()
        super.init(operations: [ accessAddressBook ])
        addCondition(MutuallyExclusive<AddressBookObserverGroup>())
        addCondition(SilentCondition(AddressBookCondition()))
    }

    func addExternalChangeObserver() {
        if !cancelled, let addressBook = addressBook {
            let observer = Observer(addressBook: addressBook, block: didChangeBlock)
            addOperation(observer)
            self.observer = observer
        }
    }

    public override func cancel() {
        observer?.cancel()
        super.cancel()
    }

    func addressBookDidChange(info: [NSObject: AnyObject]?) {
        didChangeBlock(info: info)
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty {
            if accessAddressBook == operation {
                addressBook = accessAddressBook.addressBook
                addExternalChangeObserver()
            }
            else if let _ = operation as? Observer {
                addExternalChangeObserver()
            }
        }
    }
}

#endif
