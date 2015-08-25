//
//  AddressBookExtras.swift
//  Operations
//
//  Created by Daniel Thorpe on 14/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook
import AddressBookUI


/*
// MARK: - UI

public enum DisplayStyle {
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

public class AddressBookDisplayNewPersonController: GroupOperation {

    class DisplayNewPersonController: Operation {

        let controller: ABNewPersonViewController
        let style: DisplayStyle
        let sender: AnyObject?

        init(delegate: ABNewPersonViewControllerDelegate, style: DisplayStyle, sender: AnyObject?, addressBook: ABAddressBookRef, group: ABRecordRef? = .None) {
            self.style = style
            self.sender = sender
            controller = {
                let newPersonViewController = ABNewPersonViewController()
                newPersonViewController.newPersonViewDelegate = delegate
                newPersonViewController.addressBook = addressBook
                if let group: ABRecordRef = group {
                    newPersonViewController.parentGroup = group
                }
                return newPersonViewController
            }()
        }

        override func execute() {
            dispatch_async(Queue.Main.queue) {
                self.style.displayController(self.controller, sender: self.sender) {
                    self.finish(nil)
                }
            }
        }
    }

    let delegate: ABNewPersonViewControllerDelegate
    let style: DisplayStyle
    let sender: AnyObject?

    let get: AddressBookGet

    public init(delegate: ABNewPersonViewControllerDelegate, style: DisplayStyle, sender: AnyObject? = .None, addToGroupWithName groupName: String? = .None) {
        self.delegate = delegate
        self.style = style
        self.sender = sender

        if let groupName = groupName {
            get = AddressBookGet(groupName: groupName)
        }
        else {
            get = AddressBookGet()
        }
        super.init(operations: [get.operation])
        addCondition(MutuallyExclusive<AddressBookDisplayNewPersonController>())
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get.operation == operation, let addressBook: ABAddressBookRef = get.addressBook {
            addOperation(DisplayNewPersonController(delegate: delegate, style: style, sender: sender, addressBook: addressBook, group: get.group))
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
        let style: DisplayStyle
        let sender: AnyObject?


        init(personViewController: ABPersonViewController? = .None, person: ABRecordRef, delegate: ABPersonViewControllerDelegate, style: DisplayStyle, sender: AnyObject?, addressBook: ABAddressBookRef) {
            self.style = style
            self.sender = sender
            controller = {
                let controller = personViewController ?? ABPersonViewController()
                controller.displayedPerson = person
                controller.addressBook = addressBook
                return controller
            }()
        }

        override func execute() {
            dispatch_async(Queue.Main.queue) {
                self.style.displayController(self.controller, sender: self.sender) {
                    self.finish(nil)
                }
            }
        }
    }

    let personViewController: ABPersonViewController?
    let delegate: ABPersonViewControllerDelegate
    let style: DisplayStyle
    let sender: AnyObject?
    
    let get: AddressBookGet

    public init(personViewController: ABPersonViewController? = .None, personWithID recordID: ABRecordID, displayFromControllerWithStyle style: DisplayStyle, delegate: ABPersonViewControllerDelegate, sender: AnyObject? = .None) {
        self.personViewController = personViewController
        self.style = style        
        self.delegate = delegate
        self.sender = sender
        self.get = AddressBookGet(personRecordID: recordID)
        super.init(operations: [ get.operation ])
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get.operation == operation, let addressBook: ABAddressBookRef = get.addressBook, person: ABRecordRef = get.person {
            addOperation(DisplayPersonViewController(personViewController: personViewController, person: person, delegate: delegate, style: style, sender: sender, addressBook: addressBook))
        }
    }
}


// MARK: - Processing

public class AddressBookMapRecords<T>: GroupOperation {
    let transform: (ABRecordRef) -> T?
    let get: AddressBookGet

    public var results = Array<T>()

    public init(suppressPermissionRequest silent: Bool = false, inGroup groupName: String? = .None, transform: (ABRecordRef) -> T?) {
        self.transform = transform
        self.get = AddressBookGet(suppressPermissionRequest: silent, recordsInGroup: groupName)
        super.init(operations: [ get.operation ])
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && operation == get.operation {
            results = get.records.flatMap { flatMap(transform($0), { [$0] }) ?? [] }
        }
    }
}

// MARK: - Actions

public class AddressBookRemovePersonFromGroup: GroupOperation {

    let get: AddressBookGetPersonAndGroup

    public init(suppressPermissionRequest silent: Bool = false, personRecordID: ABRecordID, groupName: String) {
        get = AddressBookGetPersonAndGroup(suppressPermissionRequest: silent, personRecordID: personRecordID, groupName: groupName)
        super.init(operations: [get])
        name = "AddressBook: Remove Person \(personRecordID) from Group: \(groupName)"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && operation == get, let addressBook: ABAddressBookRef = get.addressBook, group: ABRecordRef = get.group, member: ABRecordRef = get.person {
            addOperation(AddressBookRemoveGroupMember(addressBook: addressBook, group: group, member: member))
        }
    }
}

public class AddressBookAddPersonToGroup: GroupOperation {

    let get: AddressBookGetPersonAndGroup

    public init(suppressPermissionRequest silent: Bool = false, personRecordID: ABRecordID, groupName: String) {
        get = AddressBookGetPersonAndGroup(suppressPermissionRequest: silent, personRecordID: personRecordID, groupName: groupName)
        super.init(operations: [get])
        name = "AddressBook: Add Person \(personRecordID) to Group: \(groupName)"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && operation == get, let addressBook: ABAddressBookRef = get.addressBook, group: ABRecordRef = get.group, member: ABRecordRef = get.person {
            addOperation(AddressBookAddGroupMember(addressBook: addressBook, group: group, member: member))
        }
    }
}

public class AddressBookRemoveGroup: GroupOperation {

    let get: AddressBookGet

    public init(suppressPermissionRequest silent: Bool = false, groupName: String) {
        get = AddressBookGet(suppressPermissionRequest: silent, groupName: groupName)
        super.init(operations: [ get.operation ])
        name = "AddressBook: Remove Group: \(groupName)"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && operation == get.operation, let addressBook: ABAddressBookRef = get.addressBook, group: ABRecordRef = get.group {
            addOperation(AddressBookRemoveRecords(addressBook: addressBook, records: [group]))
        }
    }
}

public class AddressBookCreateGroup: GroupOperation {

    let get: AddressBookGetGroup
    var set: AddressBookSetProperty!
    var group: ABRecordRef?

    public init(suppressPermissionRequest silent: Bool = false, groupName: String) {
        get = AddressBookGetGroup(suppressPermissionRequest: silent, groupName: groupName)
        super.init(operations: [ get ])
        name = "AddressBook: Create Group: \(groupName)"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if operation == get, let addressBook: ABAddressBookRef = get.addressBook {
            if let group: ABRecordRef = get.group {
                // no-op group already existed
                self.group = group
            }
            else {
                group = ABGroupCreate().takeRetainedValue()
                set = AddressBookSetProperty(record: group!, property: kABGroupNameProperty, value: get.groupName)
                addOperation(set)
            }
        }
        else if operation == set, let addressBook: ABAddressBookRef = get.addressBook {
            addOperation(AddressBookAddRecords(addressBook: addressBook, records: [group!]))
        }
    }
}

// MARK: - Get

public protocol GetAddressBookType {
    var addressBook: AddressBook? { get }
}

public protocol GetAddressBookGroupType: GetAddressBookType {
    var group: AddressBookRecord? { get }
}

public protocol GetAddressBookPersonType: GetAddressBookType {
    var person: AddressBookRecord? { get }
}

public protocol GetAddressBookRecords {
    var records: [AddressBookRecord] { get }
}

enum AddressBookGet: GetAddressBookGroupType, GetAddressBookPersonType, GetAddressBookRecords {
    case AddressBook(AddressBookGetAddressBook)
    case Group(AddressBookGetGroup)
    case Person(AddressBookGetPerson)
    case GroupAndPerson(AddressBookGetPersonAndGroup)
    case GroupMembers(AddressBookGetAllGroupMembers)
    case AllPeople(AddressBookGetAllPeople)

    var operation: Operation {
        switch self {
        case .AddressBook(let op): return op
        case .Group(let op): return op
        case .Person(let op): return op
        case .GroupAndPerson(let op): return op
        case .GroupMembers(let op): return op
        case .AllPeople(let op): return op
        }
    }

    var addressBook: ABAddressBookRef? {
        switch self {
        case .AddressBook(let get): return get.addressBook
        case .Group(let get): return get.addressBook
        case .Person(let get): return get.addressBook
        case .GroupAndPerson(let get): return get.addressBook
        case .GroupMembers(let get): return get.addressBook
        case .AllPeople(let get): return get.addressBook
        }
    }

    var group: ABRecordRef? {
        switch self {
        case .Group(let get): return get.group
        case .GroupAndPerson(let get): return get.group
        case .GroupMembers(let get): return get.group
        default: return .None
        }
    }

    var person: ABRecordRef? {
        switch self {
        case .Person(let get): return get.person
        case .GroupAndPerson(let get): return get.person
        default: return .None
        }
    }

    var records: [ABRecordRef] {
        switch self {
        case .GroupMembers(let get): return get.records
        case .AllPeople(let get): return get.records
        default: return []
        }
    }

    init(suppressPermissionRequest silent: Bool = false) {
        self = .AddressBook(AddressBookGetAddressBook(suppressPermissionRequest: silent))
    }

    init(suppressPermissionRequest silent: Bool = false, groupName: String) {
        self = .Group(AddressBookGetGroup(suppressPermissionRequest: silent, groupName: groupName))
    }

    init(suppressPermissionRequest silent: Bool = false, personRecordID: ABRecordID) {
        self = .Person(AddressBookGetPerson(suppressPermissionRequest: silent, personRecordID: personRecordID))
    }

    init(suppressPermissionRequest silent: Bool = false, personRecordID: ABRecordID, groupName: String) {
        self = .GroupAndPerson(AddressBookGetPersonAndGroup(suppressPermissionRequest: silent, personRecordID: personRecordID, groupName: groupName))
    }

    init(suppressPermissionRequest silent: Bool = false, recordsInGroup groupName: String?) {
        if let groupName = groupName {
            self = .GroupMembers(AddressBookGetAllGroupMembers(suppressPermissionRequest: silent, groupName: groupName))
        }
        else {
            self = .AllPeople(AddressBookGetAllPeople(suppressPermissionRequest: silent))
        }
    }
}


public class AddressBookGetAllGroupMembers: AddressBookGetGroup, GetAddressBookRecords {

    public var records = Array<ABRecordRef>()

    public override init(suppressPermissionRequest silent: Bool = false, groupName: String) {
        super.init(suppressPermissionRequest: silent, groupName: groupName)
        name = "AddressBook: Read All Group Members"
    }

    func copyGroupMembers() {
        if let group: ABRecordRef = group {
            records = ABGroupCopyArrayOfAllMembers(group).takeRetainedValue() as [ABRecordRef]
        }
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty, let readGroup = readGroup {
            if operation == readGroup {
                copyGroupMembers()
            }
        }
    }
}

public class AddressBookGetAllPeople: GroupOperation, GetAddressBookRecords {

    let get: AddressBookGetAddressBook

    public var records = Array<AddressBookRecord>()

    public var addressBook: AddressBook? {
        return get.addressBook
    }

    public init(suppressPermissionRequest silent: Bool = false) {
        self.get = AddressBookGetAddressBook(suppressPermissionRequest: silent)
        super.init(operations: [ get ])
        name = "AddressBook: Read All People"
    }

    func copyAllPeople() {
        records = addressBook?.allPeople ?? []
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && operation == get {
            copyAllPeople()
        }
    }
}

public class AddressBookGetPersonAndGroup: GroupOperation, GetAddressBookPersonType, GetAddressBookGroupType {

    let personRecordID: ABRecordID
    let groupName: String

    let get: AddressBookGetAddressBook
    var readPerson: AddressBookReadPerson? = .None
    var readGroup: AddressBookReadGroup? = .None

    public var addressBook: AddressBook? {
        return get.addressBook
    }

    public var person: AddressBookRecord? {
        return readPerson?.person
    }

    public var group: AddressBookRecord? {
        return readGroup?.group
    }

    public init(suppressPermissionRequest silent: Bool = false, personRecordID: ABRecordID, groupName: String) {
        self.personRecordID = personRecordID
        self.groupName = groupName
        self.get = AddressBookGetAddressBook(suppressPermissionRequest: silent)
        super.init(operations: [ get ])
        name = "AddressBook: Get Person: \(personRecordID) & Group: \(groupName)"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get == operation, let addressBook = addressBook {
            readPerson = AddressBookReadPerson(addressBook: addressBook, personRecordID: personRecordID)
            readGroup = AddressBookReadGroup(addressBook: addressBook, groupName: groupName)
            addOperation(readPerson!)
            addOperation(readGroup!)
        }
    }
}

public class AddressBookGetPerson: GroupOperation, GetAddressBookPersonType {

    let personRecordID: ABRecordID
    let get: AddressBookGetAddressBook
    var read: AddressBookReadPerson? = .None

    public var addressBook: AddressBook? {
        return get.addressBook
    }

    public var person: AddressBookRecord? {
        return read?.person
    }

    public init(suppressPermissionRequest silent: Bool = false, personRecordID: ABRecordID) {
        self.personRecordID = personRecordID
        self.get = AddressBookGetAddressBook(suppressPermissionRequest: silent)
        super.init(operations: [ get ])
        name = "AddressBook: Get Person: \(personRecordID)"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get == operation, let addressBook = addressBook {
            read = AddressBookReadPerson(addressBook: addressBook, personRecordID: personRecordID)
            addOperation(read!)
        }
    }
}

public class AddressBookGetGroup: GroupOperation, GetAddressBookGroupType {

    let groupName: String
    let get: AddressBookGetAddressBook
    var read: AddressBookReadGroup? = .None

    public var addressBook: AddressBook? {
        return get.addressBook
    }

    public var group: AddressBookRecord? {
        return read?.group
    }

    public init(suppressPermissionRequest silent: Bool = false, groupName: String) {
        self.groupName = groupName
        self.get = AddressBookGetAddressBook(suppressPermissionRequest: silent)
        super.init(operations: [ get ])
        name = "AddressBook: Get Group: \(groupName)"
    }

    public override func operationDidFinish(operation: NSOperation, withErrors errors: [ErrorType]) {
        if errors.isEmpty && get == operation, let addressBook: AddressBook = addressBook {
            read = AddressBookReadGroup(addressBook: addressBook, groupName: groupName)
            addOperation(read!)
        }
    }
}

public class AddressBookGetAddressBook: Operation, GetAddressBookType {
    let silent: Bool
    var getAddressBook: AddressBookOperation!
    public var addressBook: AddressBook?

    init(suppressPermissionRequest: Bool = false) {
        silent = suppressPermissionRequest
        super.init()
        name = "AddressBook: Get Address Book"
    }

    func addGetAddressBookOperation() {
        getAddressBook = AddressBookOperation(suppressPermissionRequest: silent) { [weak self] (addressBook, continueWithError) in
            continueWithError(error: nil)
            if let weakSelf = self {
                weakSelf.addressBook = AddressBook(addressBook: addressBook)
                weakSelf.finish(nil)
            }
        }
        produceOperation(getAddressBook)
    }

    public override func execute() {
        addGetAddressBookOperation()
    }
}

// MARK: - Group

public class AddressBookRemoveGroupMember: AddressBookSave {

    public enum RemoveGroupMemberError: ErrorType {
        case FailedToRemoveMember(CFError?)
    }

    let group: ABRecordRef
    let member: ABRecordRef

    init(addressBook: ABAddressBookRef, group: ABRecordRef, member: ABRecordRef) {
        self.group = group
        self.member = member
        super.init(addressBook: addressBook)
        name = "AddressBook: Remove Group Member"
    }

    func removeMember() -> RemoveGroupMemberError? {
        var error: Unmanaged<CFError>?
        if !ABGroupRemoveMember(group, member, &error) {
            return .FailedToRemoveMember(error?.takeRetainedValue())
        }
        return .None
    }

    public override func execute() {
        if let error = removeMember() {
            finish(error)
        }
        else {
            super.execute()
        }
    }
}

public class AddressBookAddGroupMember: AddressBookSave {

    public enum AddGroupMemberError: ErrorType {
        case FailedToAddMember(CFError?)
    }

    let group: ABRecordRef
    let member: ABRecordRef

    init(addressBook: ABAddressBookRef, group: ABRecordRef, member: ABRecordRef) {
        self.group = group
        self.member = member
        super.init(addressBook: addressBook)
        name = "AddressBook: Add Group Member"
    }

    func addMember() -> AddGroupMemberError? {
        var error: Unmanaged<CFError>?
        if !ABGroupAddMember(group, member, &error) {
            return .FailedToAddMember(error?.takeRetainedValue())
        }
        return .None
    }

    public override func execute() {
        if let error = addMember() {
            finish(error)
        }
        else {
            super.execute()
        }
    }
}

// MARK: - Set Property

public class AddressBookSetProperty: Operation {

    public enum SetPropertyError: ErrorType {
        case FailedToSetProperty(CFError?)
    }

    let record: ABRecordRef
    let property: ABPropertyID
    let value: AnyObject

    init(record: ABRecordRef, property: ABPropertyID, value: AnyObject) {
        self.record = record
        self.property = property
        self.value = value
    }

    func setProperty() -> SetPropertyError? {
        var error: Unmanaged<CFError>?
        if !ABRecordSetValue(record, property, value, &error) {
            return .FailedToSetProperty(error?.takeRetainedValue())
        }
        return .None
    }

    public override func execute() {
        finish(setProperty())
    }
}

// MARK: - Add, Remove & Save

public class AddressBookAddRecords: AddressBookSave {

    public enum AddRecordsError: ErrorType {
        case FailedToAddRecord(CFError?)
    }

    let records: [ABRecordRef]

    init(addressBook: ABAddressBookRef, records: [ABRecordRef]) {
        self.records = records
        super.init(addressBook: addressBook)
        name = "AddressBook: Add Records"
    }

    func addRecord(record: ABRecordRef) -> AddRecordsError? {
        var error: Unmanaged<CFError>?
        if !ABAddressBookAddRecord(addressBook, record, &error) {
            return .FailedToAddRecord(error?.takeRetainedValue())
        }
        return .None
    }

    public override func execute() {
        for record in records {
            if let error = addRecord(record) {
                finish(error)
                break
            }
            else if let error = save() {
                finish(error)
                break
            }
        }
        finish(nil)
    }
}

public class AddressBookRemoveRecords: AddressBookSave {

    public enum RemoveRecordError: ErrorType {
        case FailedToRemoveRecord(CFError?)
    }

    let records: [ABRecordRef]

    init(addressBook: ABAddressBookRef, records: [ABRecordRef]) {
        self.records = records
        super.init(addressBook: addressBook)
        name = "AddressBook: Remove Records"
    }

    func removeRecord(record: ABRecordRef) -> RemoveRecordError? {
        var error: Unmanaged<CFError>? = .None
        if !ABAddressBookRemoveRecord(addressBook, record, &error) {
            return .FailedToRemoveRecord(error?.takeRetainedValue())
        }
        return .None
    }

    public override func execute() {
        for record in records {
            if let error = removeRecord(record) {
                finish(error)
                break
            }
            else if let error = save() {
                finish(error)
                break
            }
        }
        finish(nil)
    }
}

public class AddressBookSave: Operation {

    public enum SaveError: ErrorType {
        case FailedToSaveAddressBook(CFError?)
    }

    let addressBook: ABAddressBookRef

    init(addressBook: ABAddressBookRef) {
        self.addressBook = addressBook
        super.init()
        name = "AddressBook: Save"
    }

    func save() -> SaveError? {
        var error: Unmanaged<CFError>? = .None
        if !ABAddressBookSave(addressBook, &error) {
            return .FailedToSaveAddressBook(error?.takeRetainedValue())
        }
        return .None
    }

    public override func execute() {
        finish(save())
    }
}

// MARK: - Read

class AddressBookReadPerson: Operation {

    enum ReadPersonError: ErrorType {
        case FailedToReadPersonRecord
    }

    let addressBook: AddressBook
    let personRecordID: ABRecordID
    var person: AddressBookRecord? = .None

    init(addressBook: AddressBook, personRecordID: ABRecordID) {
        self.addressBook = addressBook
        self.personRecordID = personRecordID
        super.init()
        name = "AddressBook: Read Person \(personRecordID)"
    }

    override func execute() {
        if let person = addressBook.personWithRecordID(personRecordID) {
            self.person = person
            finish(nil)
        }
        else {
            finish(ReadPersonError.FailedToReadPersonRecord)
        }
    }
}

class AddressBookReadGroup: AddressBookReadAllGroups {

    enum ReadGroupError: ErrorType {
        case FailedToReadGroupRecord
    }

    var group: AddressBookRecord? = .None

    init(addressBook: AddressBook, groupName: String) {
        super.init(addressBook: addressBook, searchTerm: groupName)
        name = "AddressBook: Read Group \(groupName)"
    }

    override func execute() {
        readGroups()
        if let group = groups.first {
            self.group = group
            finish(nil)
        }
        else {
            finish(ReadGroupError.FailedToReadGroupRecord)
        }
    }
}

class AddressBookReadAllGroups: Operation {

    let addressBook: AddressBook
    let searchTerm: String?
    var groups = Array<AddressBookRecord>()

    init(addressBook: AddressBook, searchTerm: String? = .None) {
        self.addressBook = addressBook
        self.searchTerm = searchTerm
        super.init()
        name = "AddressBook: Read All Groups"
    }

    func readGroups() {
        groups = addressBook.groupsWithName(searchTerm: searchTerm)
    }

    override func execute() {
        readGroups()
        finish(nil)
    }
}

// MARK: - Helpers

private func readGroupRecordWithName(searchTerm: String, fromAddressBook addressBook: ABAddressBookRef) -> ABRecordRef? {
    return readGroupRecordsWithName(searchTerm, fromAddressBook: addressBook).first
}

private func readGroupRecordsWithName(searchTerm: String, fromAddressBook addressBook: ABAddressBookRef) -> [ABRecordRef] {
    let groups = ABAddressBookCopyArrayOfAllGroups(addressBook)?.takeRetainedValue() as! [ABRecordRef]
    let filtered = groups.filter { record in
        let name = ABRecordCopyValue(record, kABGroupNameProperty).takeRetainedValue() as! String
        return name == searchTerm
    }
    return filtered
}


*/














