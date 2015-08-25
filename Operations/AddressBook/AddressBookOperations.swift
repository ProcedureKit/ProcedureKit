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

    public enum Source {
        case DefaultSource
        case WithRecordID(ABRecordID)
    }

    public enum Get {
        case RecordID(ABRecordID)
        case Name(String)

        var name: String? {
            switch self {
            case .Name(let result): return result
            default: return .None
            }
        }

        var id: ABRecordID? {
            switch self {
            case .RecordID(let id): return id
            default: return .None
            }
        }
    }

    var inSource: Source? = .DefaultSource

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
}

// MARK: - Group

public class AddressBookGetGroups: AddressBookGetResource {

    var groups = Array<AddressBookGroup>()

    override func executeAddressBookTask() -> ErrorType? {
        if let source = source() {
            groups = addressBook.groupsInSource(source)
        }
        else {
            groups = addressBook.groups()
        }
        return .None
    }
}

public class AddressBookGetGroup: AddressBookGetGroups {

    let get: Get

    public var group: AddressBookGroup?

    public init(registrar: AddressBookPermissionRegistrar? = .None, get: Get) {
        self.get = get
        super.init(registrar: registrar)
    }

    override func executeAddressBookTask() -> ErrorType? {
        switch get {
        case .RecordID(let id):
            group = addressBook.groupWithID(id)
        case .Name(let groupName):
            if let error = super.executeAddressBookTask() {
                return error
            }

            group = groups.filter {
                if let name = $0.value(forProperty: AddressBookGroup.Property.name) {
                    return groupName == name
                }
                return false
            }.first
        }
        return .None
    }
}

public class AddressBookCreateGroup: AddressBookGetGroup {

    public init(registrar: AddressBookPermissionRegistrar? = .None, name: String) {
        super.init(registrar: registrar, get: .Name(name))
    }

    func createGroup() -> ErrorType? {
        if group == nil, let groupName = get.name {

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

    override func executeAddressBookTask() -> ErrorType? {
        if let error = super.executeAddressBookTask() {
            return error
        }
        return createGroup()
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

// MARK: - Person





