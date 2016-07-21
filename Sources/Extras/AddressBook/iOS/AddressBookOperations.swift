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

@available(iOS, deprecated: 9.0)
public class AddressBookOperation: Procedure {

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
            finish(AddressBookPermissionRegistrarError.addressBookAccessDenied)
        }
    }

    final func accessRequestDidComplete(_ error: AddressBookPermissionRegistrarError?) {
        if let error = error {
            self.finish(error)
        }
        else {
            self.finish(executeAddressBookTask())
        }
    }

    /*  Sub-classes may over-ride this method to perform AddressBook related
        functions before the operation finishes. */
    public func executeAddressBookTask() -> ErrorProtocol? {
        return .none
    }

    public override func execute() {
        requestAccess()
    }
}

@available(iOS, deprecated: 9.0)
public class AddressBookGetResource: AddressBookOperation {

    public enum AddressBookError: ErrorProtocol {
        case failedToGetGroup(Query?)
        case failedToGetPerson(Query?)
    }

    public enum Source {
        case defaultSource
        case withRecordID(ABRecordID)
    }

    public enum Query {

        case ID(Int32)
        case Name(String)

        var name: String? {
            switch self {
            case .Name(let result): return result
            default: return .none
            }
        }

        // swiftlint:disable variable_name_min_length
        var id: ABRecordID? {
            switch self {
            case .ID(let id): return id
            default: return .none
            }
        }
        // swiftlint:enable variable_name_min_length
    }

    public var inSource: Source? = .defaultSource

    public var groupQuery: Query? = .none
    public var personQuery: Query? = .none

    public var addressBookGroup: AddressBookGroup? = .none
    public var addressBookPerson: AddressBookPerson? = .none

    public func source() -> AddressBookSource? {
        if let inSource = inSource {
            switch inSource {
            case .defaultSource:
                let source: AddressBookSource = addressBook.defaultSource()
                return source
            case .withRecordID(let id):
                return addressBook.sourceWithID(id)
            }
        }
        return .none
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

    public func executeAddressBookGroupQuery(_ query: Query) -> AddressBookGroup? {
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

    public func executeAddressBookPersonQuery(_ query: Query) -> AddressBookPerson? {
        switch query {
        case .ID(let id):
            return addressBook.personWithID(id)

        case .Name(let name):
            return addressBook.peopleWithName(name).first
        }
    }

    public override func executeAddressBookTask() -> ErrorProtocol? {
        if let error = super.executeAddressBookTask() {
            return error
        }

        addressBookGroup = groupQuery.map { self.executeAddressBookGroupQuery($0) } ?? .none
        addressBookPerson = personQuery.map { self.executeAddressBookPersonQuery($0) } ?? .none

        return .none
    }

    // Actions

    public func addPeople(_ people: [AddressBookPerson], toGroup group: AddressBookGroup) -> ErrorProtocol? {

        for person in people {
            if let error = group.add(person) {
                return error
            }
        }

        if let error = addressBook.save() {
            return error
        }

        return .none
    }
}

// MARK: - Group Actions

@available(iOS, deprecated: 9.0)
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

@available(iOS, deprecated: 9.0)
public class AddressBookCreateGroup: AddressBookGetGroup {

    public override func executeAddressBookTask() -> ErrorProtocol? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return createGroup()
    }

    func createGroup() -> ErrorProtocol? {
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
        return .none
    }
}

@available(iOS, deprecated: 9.0)
public class AddressBookRemoveGroup: AddressBookGetGroup {

    func removeGroup() -> ErrorProtocol? {
        if let group = addressBookGroup {
            if let error = addressBook.removeRecord(group) {
                return error
            }
            if let error = addressBook.save() {
                return error
            }
        }
        return .none
    }

    public override func executeAddressBookTask() -> ErrorProtocol? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return removeGroup()
    }
}

@available(iOS, deprecated: 9.0)
public class AddressBookAddPersonToGroup: AddressBookGetResource {

    @available(iOS, deprecated: 9.0)
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

    public override func executeAddressBookTask() -> ErrorProtocol? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return addPersonToGroup()
    }

    func addPersonToGroup() -> ErrorProtocol? {

        if let group = addressBookGroup {
            if let person = addressBookPerson {
                return addPeople([person], toGroup: group)
            }
            else {
                return AddressBookError.failedToGetPerson(personQuery)
            }
        }
        else {
            return AddressBookError.failedToGetGroup(groupQuery)
        }
    }
}

@available(iOS, deprecated: 9.0)
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

    public override func executeAddressBookTask() -> ErrorProtocol? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return removePersonFromGroup()
    }

    func removePersonFromGroup() -> ErrorProtocol? {
        if addressBookGroup == nil {
            return AddressBookError.failedToGetGroup(groupQuery)
        }

        if addressBookPerson == nil {
            return AddressBookError.failedToGetPerson(personQuery)
        }

        if let group = addressBookGroup, let person = addressBookPerson, let error = group.remove(person) {
            return error
        }

        if let error = addressBook.save() {
            return error
        }

        return .none
    }
}

// MARK: - Person Actions

@available(iOS, deprecated: 9.0)
public class AddressBookMapPeople<T>: AddressBookGetResource {

    let transform: (AddressBookPerson) -> T?
    public private(set) var results = Array<T>()

    public init(inGroupNamed groupName: String? = .none, transform: (AddressBookPerson) -> T?) {
        self.transform = transform
        super.init()
        if let groupName = groupName {
            groupQuery = .Name(groupName)
        }
    }

    init(registrar: AddressBookPermissionRegistrar, inGroupNamed groupName: String? = .none, transform: (AddressBookPerson) -> T?) {
        self.transform = transform
        super.init(registrar: registrar)
        if let groupName = groupName {
            groupQuery = .Name(groupName)
        }
    }

    public override func executeAddressBookTask() -> ErrorProtocol? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return mapPeople()
    }

    func mapPeople() -> ErrorProtocol? {
        results = addressBookPeople().flatMap { self.transform($0) }
        return .none
    }
}
