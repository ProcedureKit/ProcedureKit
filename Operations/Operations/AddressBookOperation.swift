//
//  AddressBookOperation.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/07/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation
import AddressBook

public protocol AddressBookAuthenticationManager {
    var status: ABAuthorizationStatus { get }
    func createAddressBook() -> (ABAddressBookRef!, CFErrorRef!)
    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: ABAddressBookRequestAccessCompletionHandler)
}

struct SystemAddressBookAuthenticationManager: AddressBookAuthenticationManager {

    var status: ABAuthorizationStatus {
        return ABAddressBookGetAuthorizationStatus()
    }

    func createAddressBook() -> (ABAddressBookRef!, CFErrorRef!) {
        var addressBookError: Unmanaged<CFErrorRef>? = .None
        var addressBook: ABAddressBookRef? = .None
        if let ref = ABAddressBookCreateWithOptions(nil, &addressBookError) {
            addressBook = ref.takeUnretainedValue()
            return (addressBook, nil)
        }
        else if let addressBookError = addressBookError {
            return (nil, addressBookError.takeUnretainedValue())
        }
        return (nil, nil)
    }

    func requestAccessToAddressBook(addressBook: ABAddressBookRef, completion: ABAddressBookRequestAccessCompletionHandler) {
        ABAddressBookRequestAccessWithCompletion(addressBook, completion)
    }
}

public class AddressBookOperation: AccessAddressBook {

    public init(suppressPermissionRequest silent: Bool = false, handler: AddressBookHandler) {
        super.init(manager: SystemAddressBookAuthenticationManager(), handler: handler)
        let condition = AddressBookCondition(manager: manager)
        addCondition(silent ? SilentCondition(condition) : condition)
    }

    public init(manager: AddressBookAuthenticationManager, silent: Bool = false, handler: AddressBookHandler) {
        super.init(manager: manager, handler: handler)
        let condition = AddressBookCondition(manager: manager)
        addCondition(silent ? SilentCondition(condition) : condition)
    }
}

public class AddressBookMapAllRecords<T>: AddressBookOperation {

    public init(suppressPermissionRequest silent: Bool = false, inGroupWithName groupName: String? = .None, transform: (ABRecordRef) -> T?, completion: (results: [T], continueWithError: BlockOperation.ContinuationBlockType) -> Void) {

        let getAllRecords: ABAddressBookRef -> [ABRecordRef] = { addressBook in
            let records: [ABRecordRef]
            if let groupName = groupName, group: ABRecordRef = readGroupRecordWithName(groupName, fromAddressBook: addressBook) {
                records = ABGroupCopyArrayOfAllMembers(group).takeRetainedValue() as [ABRecordRef]
            }
            else {
                records = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue() as [ABRecordRef]
            }
            return records
        }

        super.init(suppressPermissionRequest: silent, handler: { (addressBook, continueWithError) in
            // Get all the records, map them with the transform, use flatMap to trim an .None elements.
            let records: [ABRecordRef] = getAllRecords(addressBook)
            let results: [T] = records.flatMap { flatMap(transform($0), { [$0] }) ?? [] }
            completion(results: results, continueWithError: continueWithError)
        })

        if let groupName = groupName {
            addCondition(AddressBookGroupExistsCondition(name: groupName, manager: manager))
        }
    }
}

public class AddressBookGroupExistsCondition: OperationCondition {

    enum Error: ErrorType {
        case GroupDoesNotExist
    }

    public let name = "Address Book Group Exists"
    public let isMutuallyExclusive = false

    public let groupName: String
    private var manager: AddressBookAuthenticationManager
    private var createAddressBookGroup: AddressBookCreateGroup?
    private var createAddressBookGroupResult: AddressBookCreateGroupResult? = .None

    public init(name: String, manager: AddressBookAuthenticationManager? = .None) {
        self.groupName = name
        self.manager = manager ?? SystemAddressBookAuthenticationManager()
    }

    public func dependencyForOperation(operation: Operation) -> NSOperation? {
        createAddressBookGroup = AddressBookCreateGroup(manager: manager, groupName: groupName) { result in
            self.createAddressBookGroupResult = result
        }
        return createAddressBookGroup
    }

    public func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        if let result = createAddressBookGroupResult, group: ABRecordRef = result.group {
            completion(.Satisfied)
        }
        else {
            completion(.Failed(Error.GroupDoesNotExist))
        }
    }
}

internal class AddressBookCreateGroup: AddressBookOperation {

    internal init(manager: AddressBookAuthenticationManager, suppressPermissionRequest silent: Bool = false, groupName: String, completion: AddressBookCreateGroupResult -> Void) {
        super.init(manager: manager, silent: silent, handler: { (addressBook, continueWithError) in
            if let group: ABRecordRef = readGroupRecordWithName(groupName, fromAddressBook: addressBook) {
                println("Address Book group already exists.")
                completion((group, .None))
            }
            else {
                println("Will create Address Book group.")
                completion(createGroupRecordWithName(groupName, inAddressBook: addressBook))
            }
            continueWithError(error: nil)
        })
        name = "Address Book Create Group: \(groupName)"
    }
}

// MARK: - Helpers

private func readGroupRecordWithName(searchTerm: String, fromAddressBook addressBook: ABAddressBookRef) -> ABRecordRef? {
    let groups = ABAddressBookCopyArrayOfAllGroups(addressBook)?.takeRetainedValue() as! [ABRecordRef]
    let groupNames = groups.map { ABRecordCopyValue($0, kABGroupNameProperty)?.takeRetainedValue() as! String }
    let filtered = groups.filter { record in
        let name = ABRecordCopyValue(record, kABGroupNameProperty).takeRetainedValue() as! String
        return name == searchTerm
    }
    return filtered.first
}

internal enum AddressBookCreateGroupError: ErrorType {
    case FailedToSetGroupNameProperty(CFError?)
    case FailedToAddGroupRecord(CFError?)
    case FailedToSaveAddressBook(CFError?)
}

internal typealias AddressBookCreateGroupResult = (group: ABRecordRef?, error: AddressBookCreateGroupError?)

private func createGroupRecordWithName(groupName: String, inAddressBook addressBook: ABAddressBookRef) -> AddressBookCreateGroupResult {

    let group: ABRecordRef = ABGroupCreate().takeRetainedValue()
    let error: AddressBookCreateGroupError? = {
        var error: Unmanaged<CFError>?
        if !ABRecordSetValue(group, kABGroupNameProperty, groupName, &error) {
            println("Failed to set group name value: \(error?.takeRetainedValue())")
            return .FailedToSetGroupNameProperty(error?.takeRetainedValue())
        }
        else if !ABAddressBookAddRecord(addressBook, group, &error) {
            println("Failed to add record: \(error?.takeRetainedValue())")
            return .FailedToAddGroupRecord(error?.takeRetainedValue())
        }
        else if !ABAddressBookSave(addressBook, &error) {
            println("Failed to save address book: \(error?.takeRetainedValue())")
            return .FailedToSaveAddressBook(error?.takeRetainedValue())
        }
        return .None
    }()

    return (group, error)
}


