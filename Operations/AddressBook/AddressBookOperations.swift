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
    func executeAddressBookTask() -> ErrorType? {
        return .None
    }

    public override func execute() {
        requestAccess()
    }
}

public class AddressBookGetResource: AddressBookOperation {

    public enum Error: ErrorType {
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

    var inSource: Source? = .DefaultSource

    var groupQuery: Query? = .None
    var personQuery: Query? = .None

    public var group: AddressBookGroup? = .None
    public var person: AddressBookPerson? = .None

    func source() -> AddressBookSource? {
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

    func groups() -> [AddressBookGroup] {
        if let source = source() {
            return addressBook.groupsInSource(source)
        }
        else {
            return addressBook.groups()
        }
    }

    func people() -> [AddressBookPerson] {
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

    override func executeAddressBookTask() -> ErrorType? {
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

    override func executeAddressBookTask() -> ErrorType? {
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

    override func executeAddressBookTask() -> ErrorType? {
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

    override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return addPersonToGroup()
    }

    func addPersonToGroup() -> ErrorType? {
        if group == nil {
            return Error.FailedToGetGroup(groupQuery)
        }

        if person == nil {
            return Error.FailedToGetPerson(personQuery)
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

    override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return removePersonFromGroup()
    }

    func removePersonFromGroup() -> ErrorType? {
        if group == nil {
            return Error.FailedToGetGroup(groupQuery)
        }

        if person == nil {
            return Error.FailedToGetPerson(personQuery)
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

    public init(registrar: AddressBookPermissionRegistrar?, inGroupNamed groupName: String? = .None, transform: (AddressBookPerson) -> T?) {
        self.transform = transform
        super.init(registrar: registrar)
        if let groupName = groupName {
            groupQuery = .Name(groupName)
            addCondition(AddressBookGroupExistsCondition(registrar: registrar, name: groupName))
        }
    }

    override func executeAddressBookTask() -> ErrorType? {
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











