//
//  AddressBookOperations.swift
//  Operations
//
//  Created by Daniel Thorpe on 25/08/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

// MARK: - Address Book Operation

@available(iOS, deprecated=9.0)
public class AddressBookOperation: Operation {

    internal var registrar: AddressBookPermissionRegistrar
    public var addressBook: AddressBook!

    public override init() {
        registrar = SystemAddressBookRegistrar()
        addressBook = AddressBook(registrar: registrar)
        super.init()
    }

    init(registrar: AddressBookPermissionRegistrar) {
        self.addressBook = AddressBook(registrar: registrar)
        self.registrar = registrar
        super.init()
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

@available(iOS, deprecated=9.0)
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

        case ID(Int32)
        case Name(String)

        var name: String? {
            switch self {
            case .Name(let result): return result
            default: return .None
            }
        }

        // swiftlint:disable variable_name_min_length
        var id: ABRecordID? {
            switch self {
            case .ID(let id): return id
            default: return .None
            }
        }
        // swiftlint:enable variable_name_min_length
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

@available(iOS, deprecated=9.0)
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

@available(iOS, deprecated=9.0)
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

@available(iOS, deprecated=9.0)
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

@available(iOS, deprecated=9.0)
public class AddressBookAddPersonToGroup: AddressBookGetResource {

    @available(iOS, deprecated=9.0)
    public init(group: String, personID: Int32) {
        super.init()
        groupQuery = .Name(group)
        personQuery = .ID(personID)
    }

    init(registrar: AddressBookPermissionRegistrar, group: String, personID: Int32) {
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

@available(iOS, deprecated=9.0)
public class AddressBookRemovePersonFromGroup: AddressBookGetResource {

    public init(group: String, personID: Int32) {
        super.init()
        groupQuery = .Name(group)
        personQuery = .ID(personID)
    }

    init(registrar: AddressBookPermissionRegistrar, group: String, personID: Int32) {
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

@available(iOS, deprecated=9.0)
public class AddressBookMapPeople<T>: AddressBookGetResource {

    let transform: (AddressBookPerson) -> T?
    public private(set) var results = Array<T>()

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
